import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_monthly_operations_controller.freezed.dart';
part 'rd_monthly_operations_controller.g.dart';

enum RDViewMode { accounts, monthlyHub }

enum RDMonthlyFilter { all, toCollect, readyForPo, settled, overdue }

enum RDDueWindowFilter { all, firstHalf, secondHalf }

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
  DateTime build() => ref.watch(clockProvider)().toMonthStart();

  void setMonth(DateTime month) {
    state = month.toMonthStart();
    ref.read(rDHubSelectionProvider.notifier).clear();
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
    @Default(false) bool groupByCustomer,
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
  RDHubFiltersState build() => const RDHubFiltersState();

  void setStatus(RDMonthlyFilter filter) => state = state.copyWith(status: filter);

  /// Tapping the active window again clears it.
  void toggleDueWindow(RDDueWindowFilter filter) => state = state.copyWith(
        dueWindow: state.dueWindow == filter ? RDDueWindowFilter.all : filter,
      );

  void toggleGroupByCustomer([bool? value]) =>
      state = state.copyWith(groupByCustomer: value ?? !state.groupByCustomer);

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);

  void clear() => state = RDHubFiltersState(groupByCustomer: state.groupByCustomer);
}

@freezed
sealed class RDHubSelectionState with _$RDHubSelectionState {
  const factory RDHubSelectionState({
    @Default(<String>{}) Set<String> installmentIds,
    @Default(false) bool isSelectionMode,
  }) = _RDHubSelectionState;

  const RDHubSelectionState._();

  bool contains(String id) => installmentIds.contains(id);
  int get count => installmentIds.length;
}

/// Multi-select for batch PO actions.
/// * `selectAll`/`selectGroup` **union** into the current selection.
/// * Selection mode is left only via [exit]/[clear] — never by un-ticking the last row.
@Riverpod(keepAlive: true)
class RDHubSelection extends _$RDHubSelection {
  @override
  RDHubSelectionState build() => const RDHubSelectionState();

  void enter() => state = state.copyWith(isSelectionMode: true);

  void exit() => state = const RDHubSelectionState();

  void clear() => exit();

  void toggle(String installmentId) {
    final next = Set<String>.of(state.installmentIds);
    if (!next.remove(installmentId)) next.add(installmentId);
    state = state.copyWith(installmentIds: next, isSelectionMode: true);
  }

  void selectAll(Iterable<String> ids) => state = state.copyWith(
        installmentIds: {...state.installmentIds, ...ids},
        isSelectionMode: true,
      );

  void deselectAll(Iterable<String> ids) {
    final remove = ids.toSet();
    state = state.copyWith(
      installmentIds: state.installmentIds.where((id) => !remove.contains(id)).toSet(),
    );
  }
}

// =============================================================================================
// Derived data
// =============================================================================================

/// Operation rows for the selected month, built from per-RD summaries (one row per RD) —
/// no schedule hydration, no fact streams, no network.
@riverpod
Future<UnmodifiableListView<RDMonthlyOperationItem>> monthlyOperationItems(Ref ref) async {
  final month = ref.watch(rDHubMonthProvider);
  final now = ref.watch(clockProvider)().toDateOnly();
  final deposits = await ref.watch(recurringDepositsControllerProvider.future);
  final summaries = await ref.watch(rdLedgerSummariesProvider.future);

  final isFutureMonth = month.isAfter(now.toMonthStart());
  final items = <RDMonthlyOperationItem>[];

  for (final deposit in deposits) {
    if (deposit.status == DepositStatus.closed) continue;
    final no = RDScheduleFactory.installmentNoFor(deposit.startDate, month);
    if (no < 1 || no > deposit.totalMonths) continue;

    final summary = summaries[deposit.id] ?? RDLedgerSummary.pristine(deposit, now);
    final installment = summary.installmentFor(deposit, no, now);
    final priors = isFutureMonth
        ? const <RDInstallment>[]
        : summary.priorOpenInstallments(deposit, no, now);

    items.add(RDMonthlyOperationItem(
      deposit: deposit,
      installment: installment,
      summary: summary,
      priorOpen: priors,
      hasSummary: summaries.containsKey(deposit.id),
    ));
  }
  return UnmodifiableListView(items);
}

/// RDs visible in the hub that have no cached summary yet (first run after migration).
@riverpod
Future<List<String>> rdIdsMissingSummary(Ref ref) async {
  final items = await ref.watch(monthlyOperationItemsProvider.future);
  return [for (final i in items) if (!i.hasSummary) i.deposit.id];
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
  final items = ref.watch(monthlyOperationItemsProvider).value ?? const [];
  final now = ref.watch(clockProvider)().toDateOnly();
  final month = ref.watch(rDHubMonthProvider);
  final isFutureMonth = month.isAfter(now.toMonthStart());

  var s = const RDMonthlyKpiSummary();
  for (final item in items) {
    s = s.copyWith(
      firstHalfCount: s.firstHalfCount + (item.isFirstHalfDue ? 1 : 0),
      secondHalfCount: s.secondHalfCount + (item.isFirstHalfDue ? 0 : 1),
    );
    if (item.isSettled) {
      s = s.copyWith(
        settledAmount: s.settledAmount + item.installment.dueAmount,
        settledCount: s.settledCount + 1,
      );
    } else if (item.isReadyForPo) {
      s = s.copyWith(
        readyForPoAmount: s.readyForPoAmount + item.installment.dueAmount,
        readyForPoCount: s.readyForPoCount + 1,
      );
    } else if (item.isCustomerPending) {
      s = s.copyWith(
        toCollectAmount: s.toCollectAmount + item.totalOutstanding,
        toCollectCount: s.toCollectCount + 1,
      );
    }
    if (!isFutureMonth && item.hasOverdueDebt(now)) {
      s = s.copyWith(
        overdueAmount: s.overdueAmount + item.totalOutstanding,
        overdueCount: s.overdueCount + 1,
      );
    }
    if (!isFutureMonth && item.priorOverdueCount > 0) {
      s = s.copyWith(
        priorArrearsAccountsCount: s.priorArrearsAccountsCount + 1,
        priorArrearsAmount: s.priorArrearsAmount + item.priorOverdueAmount,
      );
    }
  }
  return s.copyWith(totalCount: items.length);
}

@freezed
sealed class RDAgentFloatSummary with _$RDAgentFloatSummary {
  const factory RDAgentFloatSummary({
    /// Collected but not yet deposited — physical cash (capped at ₹20k per PO lot).
    @Default(0.0) double cashInHandCash,
    /// Collected but not yet deposited — UPI / bank / cheque.
    @Default(0.0) double cashInHandDigital,
    @Default(0) int cashInHandAccounts,
    /// Fronted at the PO and not yet recovered from customers.
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
  final closed = {
    for (final d in deposits ?? const <RecurringDeposit>[])
      if (d.status == DepositStatus.closed) d.id,
  };

  var s = const RDAgentFloatSummary();
  for (final summary in summaries.values) {
    if (closed.contains(summary.rdId)) continue;
    if (summary.cashInHand > 0) {
      s = s.copyWith(
        cashInHandCash: s.cashInHandCash + summary.cashInHandCash,
        cashInHandDigital: s.cashInHandDigital + summary.cashInHandDigital,
        cashInHandAccounts: s.cashInHandAccounts + 1,
      );
    }
    if (summary.receivable > 0) {
      s = s.copyWith(
        receivableAmount: s.receivableAmount + summary.receivable,
        receivableAccounts: s.receivableAccounts + 1,
      );
    }
    s = s.copyWith(absorbedFeesTotal: s.absorbedFeesTotal + summary.absorbedTotal);
    if (summary.arrearsCount >= 2) {
      s = s.copyWith(arrearsAccounts: s.arrearsAccounts + 1);
    }
  }
  return s;
}

@riverpod
Future<UnmodifiableListView<RDMonthlyOperationItem>> filteredMonthlyOperations(Ref ref) async {
  final filters = ref.watch(rDHubFiltersProvider);
  final month = ref.watch(rDHubMonthProvider);
  final now = ref.watch(clockProvider)().toDateOnly();
  final items = await ref.watch(monthlyOperationItemsProvider.future);
  final isFutureMonth = month.isAfter(now.toMonthStart());

  Iterable<RDMonthlyOperationItem> filtered = items.where((item) {
    final matchesStatus = switch (filters.status) {
      RDMonthlyFilter.all => true,
      RDMonthlyFilter.toCollect => item.isCustomerPending,
      RDMonthlyFilter.readyForPo => item.isReadyForPo,
      RDMonthlyFilter.settled => item.isSettled,
      RDMonthlyFilter.overdue => !isFutureMonth && item.hasOverdueDebt(now),
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
    filtered = filtered.where((item) {
      final d = item.deposit;
      return (d.customerName?.toLowerCase().contains(q) ?? false) ||
          (d.accountNo?.toLowerCase().contains(q) ?? false) ||
          (d.serialNo?.toLowerCase().contains(q) ?? false);
    });
  }

  final list = filtered.toList()
    ..sort((a, b) {
      if (filters.groupByCustomer) {
        final byName = (a.deposit.customerName ?? a.deposit.customerId)
            .toLowerCase()
            .compareTo((b.deposit.customerName ?? b.deposit.customerId).toLowerCase());
        if (byName != 0) return byName;
        final byId = a.deposit.customerId.compareTo(b.deposit.customerId);
        if (byId != 0) return byId;
      }
      final aOverdue = a.isOverdue(now) && a.isCustomerPending;
      final bOverdue = b.isOverdue(now) && b.isCustomerPending;
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
      final aDebt = a.hasOverdueDebt(now);
      final bDebt = b.hasOverdueDebt(now);
      if (aDebt != bDebt) return aDebt ? -1 : 1;
      if (a.priorOverdueCount != b.priorOverdueCount) {
        return b.priorOverdueCount.compareTo(a.priorOverdueCount);
      }
      return RecurringDeposit.defaultCompare(a.deposit, b.deposit);
    });

  return UnmodifiableListView(list);
}

/// A household block when "group by customer" is on.
typedef RDCustomerGroup = ({
  String customerId,
  String customerName,
  List<RDMonthlyOperationItem> items,
  double monthlyTotal,
});

@riverpod
Future<List<RDCustomerGroup>> groupedMonthlyOperations(Ref ref) async {
  final items = await ref.watch(filteredMonthlyOperationsProvider.future);
  final groups = <String, List<RDMonthlyOperationItem>>{};
  for (final item in items) {
    groups.putIfAbsent(item.deposit.customerId, () => []).add(item);
  }
  return [
    for (final e in groups.entries)
      (
        customerId: e.key,
        customerName: e.value.first.deposit.customerName ?? e.key,
        items: e.value,
        monthlyTotal: e.value.fold(0.0, (s, i) => s + i.installment.installmentAmount),
      ),
  ];
}

/// Selected rows resolved against the current month's items.
///
/// A PO visit deposits the *next contiguous ready months* of each selected account; fronting
/// (depositing a month the customer has not paid) is a separate, explicit per-account action.
@freezed
sealed class RDBatchSelectionSummary with _$RDBatchSelectionSummary {
  const factory RDBatchSelectionSummary({
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> items,
    /// Accounts with at least one collected-but-undeposited month.
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> depositable,
    /// Accounts whose selected month is the latest deposited one (undo-able).
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> revertible,
  }) = _RDBatchSelectionSummary;

  const RDBatchSelectionSummary._();

  int get count => items.length;
  int get readyInstallments =>
      depositable.fold(0, (s, i) => s + i.readyForPoCount);
  double get totalAmount => items.fold(0.0, (s, i) => s + i.installment.dueAmount);
}

@riverpod
RDBatchSelectionSummary batchSelectionSummary(Ref ref) {
  final ids = ref.watch(rDHubSelectionProvider.select((s) => s.installmentIds));
  final items = ref.watch(monthlyOperationItemsProvider).value ?? const [];
  final selected = <RDMonthlyOperationItem>[
    for (final i in items)
      if (ids.contains(i.installment.id)) i,
  ];
  return RDBatchSelectionSummary(
    items: selected,
    depositable: [for (final i in selected) if (i.readyForPoCount > 0) i],
    revertible: [for (final i in selected) if (i.isLatestDeposited) i],
  );
}

// =============================================================================================
// Actions
// =============================================================================================

/// Hub-level orchestration over `RDLedgerController`.
@Riverpod(keepAlive: true)
class RDMonthlyOperationsActions extends _$RDMonthlyOperationsActions {
  @override
  void build() {}

  RDLedgerController get _ledger => ref.read(rDLedgerControllerProvider.notifier);

  /// Deposits every collected-but-undeposited month of each account (one PO event per account).
  Future<Result<void, String>> depositReady(
    Iterable<RDMonthlyOperationItem> items, {
    DateTime? depositedOn,
  }) async {
    for (final item in items) {
      final count = item.readyForPoCount;
      if (count == 0) continue;
      final r = await _ledger.depositNextToPo(
        rdId: item.deposit.id,
        count: count,
        depositedOn: depositedOn,
      );
      if (r case Failure()) return r;
    }
    return const Success(null);
  }

  /// Fronts the account from the agent's pocket: deposits every ready month **plus** the
  /// selected (unpaid or partial) month.
  Future<Result<void, String>> frontFromPocket(RDMonthlyOperationItem item, {DateTime? depositedOn}) {
    final through = item.summary.depositedThroughNo;
    final target = item.installment.installmentNo;
    if (target <= through) return Future.value(const Success(null));
    return _ledger.depositNextToPo(
      rdId: item.deposit.id,
      count: target - through,
      depositedOn: depositedOn,
    );
  }

  Future<Result<void, String>> undoLatestDeposit(RDMonthlyOperationItem item) =>
      _ledger.undoLatestPoDeposit(item.deposit.id);

  Future<Result<void, String>> depositSelectedReady({DateTime? depositedOn}) async {
    final result = await depositReady(
      ref.read(batchSelectionSummaryProvider).depositable,
      depositedOn: depositedOn,
    );
    if (result case Success()) ref.read(rDHubSelectionProvider.notifier).exit();
    return result;
  }

  /// Every account in the current month with ready months (the "Deposit all ready" strip).
  Future<Result<void, String>> depositAllReady({DateTime? depositedOn}) async {
    final items = ref.read(monthlyOperationItemsProvider).value ??
        UnmodifiableListView(const <RDMonthlyOperationItem>[]);
    return depositReady(items.where((i) => i.readyForPoCount > 0), depositedOn: depositedOn);
  }

  /// Agent pays the remaining fee of [item]'s month from pocket.
  Future<Result<void, String>> absorbRemainingFee(RDMonthlyOperationItem item) =>
      _ledger.absorbFee(
        rdId: item.deposit.id,
        installmentNo: item.installment.installmentNo,
        amount: item.installment.customerFeeDue,
      );

  /// Everything the payment sheet needs to open pre-filled for [item].
  Future<Result<({List<RDInstallment> schedule, double initialAmount}), String>>
      prepareLogPayment(RDMonthlyOperationItem item) async {
    final provider = rdLedgerProjectionProvider(item.deposit.id);
    final sub = ref.listen(provider, (_, _) {});
    try {
      final projection = await ref.read(provider.future);
      return Success((
        schedule: projection.installments,
        initialAmount: projection.summary.owedByCustomer > 0
            ? projection.summary.owedByCustomer
            : item.installment.outstandingAmount,
      ));
    } on RDLedgerException catch (e) {
      return Failure(e.message);
    } finally {
      sub.close();
    }
  }

  /// Builds summaries for RDs that have none yet (first run after migration), then
  /// optionally re-projects every visible RD (pull-to-refresh).
  Future<void> ensureSummaries({bool rebuildAll = false}) async {
    final ledger = ref.read(rDLedgerControllerProvider.notifier);
    final ids = rebuildAll
        ? (ref.read(monthlyOperationItemsProvider).value ?? const [])
            .map((i) => i.deposit.id)
            .toList()
        : await ref.read(rdIdsMissingSummaryProvider.future);
    for (final id in ids) {
      await ledger.rebuildSummary(id);
    }
  }
}
