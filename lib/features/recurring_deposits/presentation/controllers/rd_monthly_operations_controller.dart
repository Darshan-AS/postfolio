import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
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
    final installment = summary.installmentFor(deposit, no);

    final priors = isFutureMonth
        ? const <RDInstallment>[]
        : summary
            .priorOpenInstallments(deposit, no, now)
            .where((p) => p.isOverdueAt(now) || p.outstandingLateFeeAt(now) > 0)
            .toList(growable: false);

    items.add(RDMonthlyOperationItem(
      deposit: deposit,
      installment: installment,
      priorOverdueCount: priors.length,
      priorOverdueAmount: priors.fold(0.0, (s, p) => s + p.outstandingAmountAt(now)),
      priorOverdueFee: priors.fold(0.0, (s, p) => s + p.outstandingLateFeeAt(now)),
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
        settledAmount: s.settledAmount + item.installment.installmentAmount,
        settledCount: s.settledCount + 1,
      );
    } else if (item.isReadyForPo) {
      s = s.copyWith(
        readyForPoAmount: s.readyForPoAmount + item.installment.installmentAmount,
        readyForPoCount: s.readyForPoCount + 1,
      );
    } else if (item.isCustomerPending) {
      s = s.copyWith(
        toCollectAmount: s.toCollectAmount + item.totalPayable(now),
        toCollectCount: s.toCollectCount + 1,
      );
    }
    if (!isFutureMonth && item.hasOverdueDebt(now)) {
      s = s.copyWith(
        overdueAmount: s.overdueAmount + item.totalOutstandingPayable(now),
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
    @Default(0.0) double undepositedCashAmount,
    @Default(0) int undepositedCashCount,
    @Default(0.0) double pocketAdvancesAmount,
    @Default(0) int pocketAdvancesCount,
  }) = _RDAgentFloatSummary;

  const RDAgentFloatSummary._();

  bool get hasFloat => undepositedCashCount > 0 || pocketAdvancesCount > 0;
}

/// Cross-month agent float straight from the summary cache (cash in hand vs pocket advances).
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
        undepositedCashAmount: s.undepositedCashAmount + summary.cashInHand,
        undepositedCashCount: s.undepositedCashCount + 1,
      );
    }
    if (summary.pocketAdvance > 0) {
      s = s.copyWith(
        pocketAdvancesAmount: s.pocketAdvancesAmount + summary.pocketAdvance,
        pocketAdvancesCount: s.pocketAdvancesCount + 1,
      );
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
@freezed
sealed class RDBatchSelectionSummary with _$RDBatchSelectionSummary {
  const factory RDBatchSelectionSummary({
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> items,
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> depositable,
    @Default(<RDMonthlyOperationItem>[]) List<RDMonthlyOperationItem> revertible,
  }) = _RDBatchSelectionSummary;

  const RDBatchSelectionSummary._();

  int get count => items.length;
  double get totalAmount =>
      items.fold(0.0, (s, i) => s + i.installment.installmentAmount);
  double get collectedAmount => depositable
      .where((i) => i.installment.isInstallmentPaid)
      .fold(0.0, (s, i) => s + i.installment.installmentAmount);
  double get fromPocketAmount => depositable
      .where((i) => !i.installment.isInstallmentPaid)
      .fold(0.0, (s, i) => s + i.installment.outstandingPrincipal);
  int get collectedCount =>
      depositable.where((i) => i.installment.isInstallmentPaid).length;
  int get fromPocketCount =>
      depositable.where((i) => !i.installment.isInstallmentPaid).length;
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
    depositable: [for (final i in selected) if (i.canDepositToPo) i],
    revertible: [for (final i in selected) if (i.canRevertPo) i],
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

  Future<Result<void, String>> depositToPo(Iterable<RDMonthlyOperationItem> items) =>
      _perRd(items.where((i) => i.canDepositToPo), (rdId, nos) =>
          ref.read(rDLedgerControllerProvider.notifier).depositToPo(rdId: rdId, installmentNos: nos));

  Future<Result<void, String>> revertPo(Iterable<RDMonthlyOperationItem> items) =>
      _perRd(items.where((i) => i.canRevertPo), (rdId, nos) =>
          ref.read(rDLedgerControllerProvider.notifier).revertPoDeposit(rdId: rdId, installmentNos: nos));

  Future<Result<void, String>> depositSelectedToPo() async {
    final result = await depositToPo(ref.read(batchSelectionSummaryProvider).depositable);
    if (result case Success()) ref.read(rDHubSelectionProvider.notifier).exit();
    return result;
  }

  Future<Result<void, String>> revertSelectedPo() async {
    final result = await revertPo(ref.read(batchSelectionSummaryProvider).revertible);
    if (result case Success()) ref.read(rDHubSelectionProvider.notifier).exit();
    return result;
  }

  Future<Result<void, String>> forgiveFee(RDMonthlyOperationItem item) =>
      ref.read(rDLedgerControllerProvider.notifier).setFeeWaiver(
            rdId: item.deposit.id,
            installmentNo: item.installment.installmentNo!,
            waived: true,
          );

  /// Everything the payment sheet needs to open pre-filled for [item].
  Future<Result<({List<RDInstallment> schedule, double initialAmount, PaymentSplitMode? splitMode}), String>>
      prepareLogPayment(RDMonthlyOperationItem item) async {
    final provider = rdLedgerProjectionProvider(item.deposit.id);
    final sub = ref.listen(provider, (_, _) {});
    try {
      final projection = await ref.read(provider.future);
      final now = ref.read(clockProvider)().toDateOnly();
      return Success((
        schedule: projection.installments,
        initialAmount: item.initialPaymentAmount(now),
        splitMode: item.initialPaymentSplitMode(now),
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

  Future<Result<void, String>> _perRd(
    Iterable<RDMonthlyOperationItem> items,
    Future<Result<void, String>> Function(String rdId, Set<int> nos) op,
  ) async {
    final byRd = <String, Set<int>>{};
    for (final i in items) {
      byRd.putIfAbsent(i.deposit.id, () => {}).add(i.installment.installmentNo!);
    }
    if (byRd.isEmpty) return const Success(null);
    for (final e in byRd.entries) {
      final r = await op(e.key, e.value);
      if (r case Failure()) return r;
    }
    return const Success(null);
  }
}
