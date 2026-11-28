import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_monthly_operations_controller.freezed.dart';
part 'rd_monthly_operations_controller.g.dart';

enum RDViewMode {
  accounts,
  monthlyHub;

  String get queryValue => switch (this) {
    RDViewMode.accounts => 'accounts',
    RDViewMode.monthlyHub => 'hub',
  };
}

enum RDMonthlyFilter { all, toCollect, readyForPo, settled, receivable }

enum RDDueWindowFilter { all, firstHalf, secondHalf }

enum RDHubSortField { serialNo, overdueFirst, customerName }

// =============================================================================================
// State — three small notifiers so a keystroke in search never rebuilds the month's rows.
// =============================================================================================

@riverpod
class RDViewModeController extends _$RDViewModeController {
  @override
  RDViewMode build() => RDViewMode.accounts;

  void setMode(RDViewMode mode) => state = mode;
}

/// Which calendar month the hub is looking at (always the 1st of the month).
@Riverpod(keepAlive: true)
class RDHubMonth extends _$RDHubMonth {
  @override
  DateTime build() {
    ref.watch(activeSessionKeyProvider);
    return ref.watch(clockProvider)().toMonthStart();
  }

  void setMonth(DateTime month) {
    state = month.toMonthStart();
  }

  void previousMonth() => setMonth(DateTime(state.year, state.month - 1));
  void nextMonth() => setMonth(DateTime(state.year, state.month + 1));
  void resetToCurrentMonth() => setMonth(ref.read(clockProvider)());
}

@freezed
sealed class RDHubFiltersState with _$RDHubFiltersState {
  const factory RDHubFiltersState({
    @Default(RDMonthlyFilter.all) RDMonthlyFilter status,
    @Default(RDDueWindowFilter.all) RDDueWindowFilter dueWindow,
    @Default(RDHubSortField.serialNo) RDHubSortField sortField,
    @Default(SortDirection.asc) SortDirection sortDirection,
    @Default('') String searchQuery,
  }) = _RDHubFiltersState;

  const RDHubFiltersState._();

  bool get hasActiveFilters =>
      status != RDMonthlyFilter.all ||
      dueWindow != RDDueWindowFilter.all ||
      searchQuery.isNotEmpty;
}

@Riverpod(keepAlive: true)
class RDHubFilters extends _$RDHubFilters {
  @override
  RDHubFiltersState build() {
    ref.watch(activeSessionKeyProvider);
    return const RDHubFiltersState();
  }

  void setStatus(RDMonthlyFilter filter) =>
      state = state.copyWith(status: filter);

  /// Tapping the active window again clears it.
  void toggleDueWindow(RDDueWindowFilter filter) => state = state.copyWith(
    dueWindow: state.dueWindow == filter ? RDDueWindowFilter.all : filter,
  );

  void setSort(RDHubSortField field, SortDirection direction) =>
      state = state.copyWith(sortField: field, sortDirection: direction);

  void resetSort() => state = state.copyWith(
    sortField: RDHubSortField.serialNo,
    sortDirection: SortDirection.asc,
  );

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void clear() => state = RDHubFiltersState(
    sortField: state.sortField,
    sortDirection: state.sortDirection,
  );
}

// =============================================================================================
// Derived data
// =============================================================================================

/// Operation rows for the selected month, built from per-RD summaries (one row per RD) —
/// no schedule hydration, no fact streams, no network.
@riverpod
Future<UnmodifiableListView<RDMonthlyOperationItem>> monthlyOperationItems(
  Ref ref,
) async {
  final month = ref.watch(rDHubMonthProvider);
  final now = ref.watch(currentDateProvider);
  final deposits = await ref.watch(recurringDepositsControllerProvider.future);
  final summaries = await ref.watch(rdLedgerSummariesProvider.future);

  // Overlay live customer names whenever CustomersController has loaded (so renaming a customer
  // propagates immediately), and only block-await CustomersController when a deposit lacks a name.
  final liveCustomers = ref.watch(customersControllerProvider).value;
  final Map<String, String> customerNames;
  if (liveCustomers != null) {
    customerNames = {for (final c in liveCustomers) c.id: c.name};
  } else if (deposits.any((d) => d.customerName == null)) {
    final customers = await ref.watch(customersControllerProvider.future);
    customerNames = {for (final c in customers) c.id: c.name};
  } else {
    customerNames = const {};
  }

  final isFutureMonth = month.isAfter(now.toMonthStart());
  final items = <RDMonthlyOperationItem>[];

  for (var deposit in deposits) {
    if (deposit.status == DepositStatus.closed) continue;
    final liveName = customerNames[deposit.customerId];
    if (liveName != null && liveName != deposit.customerName) {
      deposit = deposit.copyWith(customerName: liveName);
    }
    final no = RDScheduleFactory.installmentNoFor(deposit.startDate, month);
    if (no < 1 || no > deposit.totalMonths) continue;

    final summary =
        summaries[deposit.id] ?? RDLedgerSummary.pristine(deposit, now);
    final installment = summary.installmentFor(deposit, no, now);
    final allPriors = summary.priorOpenInstallments(deposit, no, now);
    // On future-month planning views, suppress un-matured current/upcoming months so healthy
    // accounts stay calm, while keeping genuinely past-due arrears (`dueDate < now`) visible.
    final priors = isFutureMonth
        ? [
            for (final p in allPriors)
              if (p.dueDate.isBefore(now)) p,
          ]
        : allPriors;

    items.add(
      RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
        summary: summary,
        priorOpen: priors,
        hasSummary: summaries.containsKey(deposit.id),
      ),
    );
  }
  return UnmodifiableListView(items);
}

/// RDs visible in the hub that have no cached summary yet (first run after migration).
@riverpod
Future<List<String>> rdIdsMissingSummary(Ref ref) async {
  final items = await ref.watch(monthlyOperationItemsProvider.future);
  return [
    for (final i in items)
      if (!i.hasSummary) i.deposit.id,
  ];
}

@freezed
sealed class RDMonthlyKpiSummary with _$RDMonthlyKpiSummary {
  const factory RDMonthlyKpiSummary({
    @Default(0.0) double toCollectAmount,
    @Default(0) int toCollectCount,
    @Default(0.0) double readyForPoAmount,
    @Default(0) int readyForPoCount,
    @Default(0.0) double settledAmount,
    @Default(0) int settledCount,
    @Default(0.0) double receivableAmount,
    @Default(0) int receivableCount,
    @Default(0.0) double overdueAmount,
    @Default(0) int overdueCount,
    @Default(0) int priorArrearsAccountsCount,
    @Default(0.0) double priorArrearsAmount,
    @Default(0) int firstHalfCount,
    @Default(0) int secondHalfCount,
    @Default(0) int totalCount,
  }) = _RDMonthlyKpiSummary;
}

@riverpod
RDMonthlyKpiSummary monthlyOperationsKpi(Ref ref) {
  final items =
      ref.watch(monthlyOperationItemsProvider).value ??
      const <RDMonthlyOperationItem>[];
  final now = ref.watch(currentDateProvider);
  final month = ref.watch(rDHubMonthProvider);
  final isFutureMonth = month.isAfter(now.toMonthStart());

  var toCollectAmount = 0.0;
  var toCollectCount = 0;
  var readyForPoAmount = 0.0;
  var readyForPoCount = 0;
  var settledAmount = 0.0;
  var settledCount = 0;
  var receivableAmount = 0.0;
  var receivableCount = 0;
  var overdueAmount = 0.0;
  var overdueCount = 0;
  var priorArrearsAccountsCount = 0;
  var priorArrearsAmount = 0.0;
  var firstHalfCount = 0;
  var secondHalfCount = 0;

  for (final item in items) {
    // Counts and totals mirror the 4 KPI filter predicates so tile counts match row counts.
    if (item.isCustomerPending) {
      if (item.isFirstHalfDue) {
        firstHalfCount++;
      } else {
        secondHalfCount++;
      }
      toCollectAmount += item.totalOutstanding;
      toCollectCount++;
    }
    if (item.hasReadyForPo) {
      readyForPoAmount += item.readyForPoAmount;
      readyForPoCount++;
    }
    if (item.isSettled) {
      settledAmount += item.installment.dueAmount;
      settledCount++;
    }
    if (item.hasReceivable) {
      receivableAmount += item.receivableAmount;
      receivableCount++;
    }
    if (item.hasOverdueDebt(now)) {
      overdueAmount += isFutureMonth
          ? item.priorOverdueAmount
          : item.totalOutstanding;
      overdueCount++;
    }
    if (item.priorOverdueCount > 0) {
      priorArrearsAccountsCount++;
      priorArrearsAmount += item.priorOverdueAmount;
    }
  }

  return RDMonthlyKpiSummary(
    toCollectAmount: toCollectAmount,
    toCollectCount: toCollectCount,
    readyForPoAmount: readyForPoAmount,
    readyForPoCount: readyForPoCount,
    settledAmount: settledAmount,
    settledCount: settledCount,
    receivableAmount: receivableAmount,
    receivableCount: receivableCount,
    overdueAmount: overdueAmount,
    overdueCount: overdueCount,
    priorArrearsAccountsCount: priorArrearsAccountsCount,
    priorArrearsAmount: priorArrearsAmount,
    firstHalfCount: firstHalfCount,
    secondHalfCount: secondHalfCount,
    totalCount: items.length,
  );
}

@freezed
sealed class RDAgentFloatSummary with _$RDAgentFloatSummary {
  const factory RDAgentFloatSummary({
    /// Collected but not yet deposited — physical cash (capped at ₹20k per PO lot).
    @Default(0.0) double cashInHandCash,

    /// Collected but not yet deposited — UPI / bank / cheque.
    @Default(0.0) double cashInHandDigital,
    @Default(0) int cashInHandAccounts,

    /// Paid from pocket at the PO and not yet recovered from customers.
    @Default(0.0) double receivableAmount,
    @Default(0) int receivableAccounts,
    @Default(0.0) double absorbedFeesTotal,

    /// Accounts with 2+ unsettled past-due months.
    @Default(0) int arrearsAccounts,
  }) = _RDAgentFloatSummary;

  const RDAgentFloatSummary._();

  double get cashInHandTotal => cashInHandCash + cashInHandDigital;
  bool get hasFloat => cashInHandAccounts > 0 || receivableAccounts > 0;
}

/// Cross-month agent float straight from the summary cache.
@riverpod
RDAgentFloatSummary globalAgentFloat(Ref ref) {
  final summaries = ref.watch(rdLedgerSummariesProvider).value ?? const {};
  final deposits = ref.watch(recurringDepositsControllerProvider).value;
  final now = ref.watch(currentDateProvider);
  final byId = {
    for (final d in deposits ?? const <RecurringDeposit>[]) d.id: d,
  };

  var cashInHandCash = 0.0;
  var cashInHandDigital = 0.0;
  var cashInHandAccounts = 0;
  var receivableAmount = 0.0;
  var receivableAccounts = 0;
  var absorbedFeesTotal = 0.0;
  var arrearsAccounts = 0;

  for (final summary in summaries.values) {
    final deposit = byId[summary.rdId];
    if (deposit == null || deposit.status == DepositStatus.closed) continue;
    if (summary.cashInHand > 0) {
      cashInHandCash += summary.cashInHandCash;
      cashInHandDigital += summary.cashInHandDigital;
      cashInHandAccounts++;
    }
    if (summary.receivable > 0) {
      receivableAmount += summary.receivable;
      receivableAccounts++;
    }
    absorbedFeesTotal += summary.absorbedTotal;
    // Evaluate arrears as of today: the cached count is only as fresh as the last write.
    if (summary.arrearsCountAsOf(deposit, now) >=
        RDLedgerRules.standard.arrearsAlertThresholdMonths) {
      arrearsAccounts++;
    }
  }
  return RDAgentFloatSummary(
    cashInHandCash: cashInHandCash,
    cashInHandDigital: cashInHandDigital,
    cashInHandAccounts: cashInHandAccounts,
    receivableAmount: receivableAmount,
    receivableAccounts: receivableAccounts,
    absorbedFeesTotal: absorbedFeesTotal,
    arrearsAccounts: arrearsAccounts,
  );
}

@riverpod
Future<UnmodifiableListView<RDMonthlyOperationItem>> filteredMonthlyOperations(
  Ref ref,
) async {
  final filters = ref.watch(rDHubFiltersProvider);
  final now = ref.watch(currentDateProvider);
  final items = await ref.watch(monthlyOperationItemsProvider.future);

  Iterable<RDMonthlyOperationItem> filtered = items.where((item) {
    final matchesStatus = switch (filters.status) {
      RDMonthlyFilter.all => true,
      RDMonthlyFilter.toCollect => item.isCustomerPending,
      RDMonthlyFilter.readyForPo => item.hasReadyForPo,
      RDMonthlyFilter.settled => item.isSettled,
      RDMonthlyFilter.receivable => item.hasReceivable,
    };
    if (!matchesStatus) return false;
    return switch (filters.dueWindow) {
      RDDueWindowFilter.all => true,
      RDDueWindowFilter.firstHalf => item.isFirstHalfDue,
      RDDueWindowFilter.secondHalf => !item.isFirstHalfDue,
    };
  });

  final q = filters.searchQuery.toLowerCase().trim();
  if (q.isNotEmpty) {
    // Serial first (cheapest, most common at the counter), then account digits, then name.
    filtered = filtered.where((item) {
      final d = item.deposit;
      return (d.serialNo?.toLowerCase().contains(q) ?? false) ||
          (d.accountNo?.toLowerCase().contains(q) ?? false) ||
          (d.customerName?.toLowerCase().contains(q) ?? false);
    });
  }

  final sign = filters.sortDirection == SortDirection.asc ? 1 : -1;
  final list = filtered.toList()
    ..sort((a, b) {
      int compareSerial() {
        final cmp = RecurringDeposit.defaultCompare(a.deposit, b.deposit);
        if (cmp != 0) return cmp * sign;
        return a.deposit.id.compareTo(b.deposit.id) * sign;
      }

      switch (filters.sortField) {
        case RDHubSortField.serialNo:
          return compareSerial();
        case RDHubSortField.overdueFirst:
          final aMonths = a.arrearsMonthsAt(now);
          final bMonths = b.arrearsMonthsAt(now);
          if (aMonths != bMonths) return bMonths.compareTo(aMonths) * sign;
          if (aMonths > 0) {
            final aOldest = a.oldestOverdueDueDateAt(now)!;
            final bOldest = b.oldestOverdueDueDateAt(now)!;
            final byDue = aOldest.compareTo(bOldest);
            if (byDue != 0) return byDue * sign;
          }
          return compareSerial();
        case RDHubSortField.customerName:
          final byName = (a.deposit.customerName ?? a.deposit.customerId)
              .toLowerCase()
              .compareTo(
                (b.deposit.customerName ?? b.deposit.customerId).toLowerCase(),
              );
          if (byName != 0) return byName * sign;
          return compareSerial();
      }
    });

  return UnmodifiableListView(list);
}

// =============================================================================================
// Actions
// =============================================================================================

/// Hub-level orchestration over `RDLedgerController`.
@Riverpod(keepAlive: true)
class RDMonthlyOperationsActions extends _$RDMonthlyOperationsActions {
  @override
  void build() {}

  RDLedgerController get _ledger =>
      ref.read(rDLedgerControllerProvider.notifier);

  Future<Result<void, String>> undoLatestDeposit(RDMonthlyOperationItem item) =>
      _ledger.undoLatestPoDeposit(item.deposit.id);

  /// Agent pays the remaining fee of [item]'s month from pocket (only when that closes the month).
  Future<Result<void, String>> absorbRemainingFee(RDMonthlyOperationItem item) {
    final amount = item.installment.absorbableFee;
    if (amount <= 0) {
      return Future.value(
        Failure(t.recurringDeposits.monthlyOperations.card.nothingToAbsorb),
      );
    }
    return _ledger.absorbFee(
      rdId: item.deposit.id,
      installmentNo: item.installment.installmentNo,
      amount: amount,
    );
  }

  /// Builds summaries for RDs that have none yet (first run after migration), or
  /// re-projects every visible RD in a single batch read + bulk upsert (pull-to-refresh).
  Future<Result<void, String>> ensureSummaries({
    bool rebuildAll = false,
  }) async {
    final items = await ref.read(monthlyOperationItemsProvider.future);
    final deposits = <RecurringDeposit>[
      for (final i in items)
        if (rebuildAll || !i.hasSummary) i.deposit,
    ];
    if (deposits.isEmpty) return const Success(null);
    return ref
        .read(rDLedgerControllerProvider.notifier)
        .rebuildSummaries(deposits);
  }
}
