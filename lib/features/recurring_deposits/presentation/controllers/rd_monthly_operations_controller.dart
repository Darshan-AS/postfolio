import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_monthly_operations_controller.freezed.dart';
part 'rd_monthly_operations_controller.g.dart';

enum RDViewMode {
  accounts,
  monthlyHub,
}

enum RDMonthlyFilter {
  all,
  toCollect,
  readyForPo,
  settled,
  overdue,
}

@freezed
abstract class RDMonthlyOperationsState with _$RDMonthlyOperationsState {
  const factory RDMonthlyOperationsState({
    required DateTime selectedMonth,
    @Default(RDMonthlyFilter.all) RDMonthlyFilter selectedFilter,
    @Default('') String searchQuery,
    @Default(<String>{}) Set<String> selectedInstallmentIds,
    @Default(false) bool isSelectionMode,
  }) = _RDMonthlyOperationsState;
}

class RDMonthlyKpiSummary {
  final double toCollectAmount;
  final int toCollectCount;
  final double readyForPoAmount;
  final int readyForPoCount;
  final double settledAmount;
  final int settledCount;
  final double overdueAmount;
  final int overdueCount;
  final int priorArrearsAccountsCount;
  final double priorArrearsAmount;
  final int totalCount;

  const RDMonthlyKpiSummary({
    this.toCollectAmount = 0.0,
    this.toCollectCount = 0,
    this.readyForPoAmount = 0.0,
    this.readyForPoCount = 0,
    this.settledAmount = 0.0,
    this.settledCount = 0,
    this.overdueAmount = 0.0,
    this.overdueCount = 0,
    this.priorArrearsAccountsCount = 0,
    this.priorArrearsAmount = 0.0,
    this.totalCount = 0,
  });
}

@riverpod
class RDViewModeController extends _$RDViewModeController {
  @override
  RDViewMode build() => RDViewMode.accounts;

  void setMode(RDViewMode mode) => state = mode;
}

@riverpod
class RDMonthlyOperationsController extends _$RDMonthlyOperationsController {
  @override
  RDMonthlyOperationsState build() {
    final now = DateTime.now();
    return RDMonthlyOperationsState(
      selectedMonth: DateTime(now.year, now.month, 1),
    );
  }

  void setMonth(DateTime month) {
    state = state.copyWith(
      selectedMonth: DateTime(month.year, month.month, 1),
      selectedInstallmentIds: const {},
      isSelectionMode: false,
    );
  }

  void previousMonth() {
    final current = state.selectedMonth;
    setMonth(DateTime(current.year, current.month - 1, 1));
  }

  void nextMonth() {
    final current = state.selectedMonth;
    setMonth(DateTime(current.year, current.month + 1, 1));
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    setMonth(DateTime(now.year, now.month, 1));
  }

  void setFilter(RDMonthlyFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSelectionMode([bool? value]) {
    final newMode = value ?? !state.isSelectionMode;
    state = state.copyWith(
      isSelectionMode: newMode,
      selectedInstallmentIds: newMode ? state.selectedInstallmentIds : const {},
    );
  }

  void toggleSelection(String installmentId) {
    final current = Set<String>.from(state.selectedInstallmentIds);
    if (current.contains(installmentId)) {
      current.remove(installmentId);
    } else {
      current.add(installmentId);
    }
    state = state.copyWith(
      selectedInstallmentIds: current,
      isSelectionMode: current.isNotEmpty,
    );
  }

  void selectAll(List<String> ids) {
    state = state.copyWith(
      selectedInstallmentIds: ids.toSet(),
      isSelectionMode: ids.isNotEmpty,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedInstallmentIds: const {},
      isSelectionMode: false,
    );
  }

  Future<Result<void, String>> depositSelectedToPo(
    List<RDInstallment> installments,
  ) async {
    final toDeposit = installments
        .where((i) => state.selectedInstallmentIds.contains(i.id))
        .where((i) =>
            state.selectedInstallmentIds.contains(i.id) &&
            i.poStatus != RDPoStatus.paid)
        .map((i) => i.copyWith(
              poStatus: RDPoStatus.paid,
              poPaidDate: DateTime.now(),
            ))
        .toList();

    if (toDeposit.isEmpty) return const Success(null);

    final ledgerController = ref.read(rDLedgerControllerProvider.notifier);
    final result = await ledgerController.recordPoPayments(
      installments: toDeposit,
    );

    if (result case Success()) {
      clearSelection();
    }
    return result;
  }

  Future<Result<void, String>> revertSelectedPo(
    List<RDInstallment> installments,
  ) async {
    final toRevert = installments
        .where((i) =>
            state.selectedInstallmentIds.contains(i.id) &&
            i.poStatus == RDPoStatus.paid)
        .toList();

    if (toRevert.isEmpty) return const Success(null);

    final ledgerController = ref.read(rDLedgerControllerProvider.notifier);
    final result = await ledgerController.revertPoPayments(
      installments: toRevert,
    );

    if (result case Success()) {
      clearSelection();
    }
    return result;
  }
}

@riverpod
Stream<List<RDMonthlyOperationItem>> rawMonthlyOperationsStream(Ref ref) {
  final selectedMonth = ref.watch(
    rDMonthlyOperationsControllerProvider,
  ).selectedMonth;
  final repository = ref.watch(recurringDepositRepositoryProvider);

  return repository.watchInstallmentsForMonth(selectedMonth).asyncMap((result) async {
    final installments = switch (result) {
      Success(value: final list) => list,
      Failure(error: final err) => throw Exception(err),
    };

    final deposits = await ref.watch(recurringDepositsControllerProvider.future);
    final depositMap = {for (final d in deposits) d.id: d};

    final hasNullNames = deposits.any((d) => d.customerName == null);
    final Map<String, String> customerMap;
    if (hasNullNames) {
      final customers = await ref.watch(customersControllerProvider.future);
      customerMap = {for (final c in customers) c.id: c.name};
    } else {
      customerMap = const {};
    }

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month);
    final selectedMonthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final isFutureMonth = selectedMonthStart.isAfter(currentMonthStart);

    final Map<String, List<RDInstallment>> priorUnpaidByRd;
    if (isFutureMonth) {
      priorUnpaidByRd = const {};
    } else {
      final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final priorUnpaidResult = await repository.getUnpaidInstallmentsBefore(startOfMonth);
      final priorUnpaid = switch (priorUnpaidResult) {
        Success(value: final list) => list.where((p) => p.isOverdueAt(now)).toList(),
        Failure() => <RDInstallment>[],
      };

      priorUnpaidByRd = <String, List<RDInstallment>>{};
      for (final p in priorUnpaid) {
        priorUnpaidByRd.putIfAbsent(p.rdId, () => []).add(p);
      }
    }

    final items = <RDMonthlyOperationItem>[];
    for (final inst in installments) {
      var deposit = depositMap[inst.rdId];
      if (deposit == null) continue;

      if (deposit.customerName == null && customerMap.containsKey(deposit.customerId)) {
        deposit = deposit.copyWith(customerName: customerMap[deposit.customerId]);
      }

      if (deposit.status == DepositStatus.closed) continue;

      final priors = priorUnpaidByRd[inst.rdId] ?? const [];
      final priorCount = priors.length;
      final priorAmount = priors.fold<double>(
        0.0,
        (sum, p) => sum + p.outstandingAmountAt(now),
      );
      final priorFees = priors.fold<double>(
        0.0,
        (sum, p) => sum + p.outstandingLateFeeAt(now),
      );

      items.add(RDMonthlyOperationItem(
        deposit: deposit,
        installment: inst,
        priorOverdueCount: priorCount,
        priorOverdueAmount: priorAmount,
        priorOverdueFee: priorFees,
      ));
    }

    return items;
  });
}

@riverpod
RDMonthlyKpiSummary monthlyOperationsKpi(Ref ref) {
  final asyncItems = ref.watch(rawMonthlyOperationsStreamProvider);
  final items = asyncItems.value ?? const [];
  final now = DateTime.now();
  final selectedMonth = ref.watch(
    rDMonthlyOperationsControllerProvider,
  ).selectedMonth;
  final currentMonthStart = DateTime(now.year, now.month);
  final targetMonthStart = DateTime(selectedMonth.year, selectedMonth.month);
  final isFutureMonth = targetMonthStart.isAfter(currentMonthStart);

  double toCollectAmount = 0.0;
  int toCollectCount = 0;
  double readyForPoAmount = 0.0;
  int readyForPoCount = 0;
  double settledAmount = 0.0;
  int settledCount = 0;
  double overdueAmount = 0.0;
  int overdueCount = 0;
  int priorArrearsAccountsCount = 0;
  double priorArrearsAmount = 0.0;

  for (final item in items) {
    if (item.isSettled) {
      settledAmount += item.installment.installmentAmount;
      settledCount++;
    } else if (item.isReadyForPo) {
      readyForPoAmount += item.installment.installmentAmount;
      readyForPoCount++;
    } else if (item.isCustomerPending) {
      // Pending from customer
      final payable = item.totalPayable(now);
      toCollectAmount += payable;
      toCollectCount++;
    }

    // Overdue accounts: only active in current/past months, never in future planning months
    if (!isFutureMonth && item.hasOverdueDebt(now)) {
      overdueAmount += item.totalOutstandingPayable(now);
      overdueCount++;
    }

    if (!isFutureMonth && item.priorOverdueCount > 0) {
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
    overdueAmount: overdueAmount,
    overdueCount: overdueCount,
    priorArrearsAccountsCount: priorArrearsAccountsCount,
    priorArrearsAmount: priorArrearsAmount,
    totalCount: items.length,
  );
}

@riverpod
Future<UnmodifiableListView<RDMonthlyOperationItem>> filteredMonthlyOperations(
  Ref ref,
) async {
  final items = await ref.watch(rawMonthlyOperationsStreamProvider.future);
  final state = ref.watch(rDMonthlyOperationsControllerProvider);
  final filter = state.selectedFilter;
  final searchQuery = state.searchQuery;
  final now = DateTime.now();
  final isFutureMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month)
      .isAfter(DateTime(now.year, now.month));

  var filtered = items.where((item) {
    return switch (filter) {
      RDMonthlyFilter.all => true,
      RDMonthlyFilter.toCollect => item.isCustomerPending,
      RDMonthlyFilter.readyForPo => item.isReadyForPo,
      RDMonthlyFilter.settled => item.isSettled,
      RDMonthlyFilter.overdue => isFutureMonth ? false : item.hasOverdueDebt(now),
    };
  }).toList();

  if (searchQuery.isNotEmpty) {
    final q = searchQuery.toLowerCase().trim();
    filtered = filtered.where((item) {
      final name = item.deposit.customerName?.toLowerCase() ?? '';
      final acc = item.deposit.accountNo?.toLowerCase() ?? '';
      final serial = item.deposit.serialNo?.toLowerCase() ?? '';
      return name.contains(q) || acc.contains(q) || serial.contains(q);
    }).toList();
  }

  // Sort: Overdue first, then by serial number or account number
  // Sort: Overdue debt first (prioritizing more prior overdue months), then standard order
  filtered.sort((a, b) {
    final aOverdue = a.isOverdue(now) && a.isCustomerPending;
    final bOverdue = b.isOverdue(now) && b.isCustomerPending;
    if (aOverdue && !bOverdue) return -1;
    if (!aOverdue && bOverdue) return 1;
    final aHasOverdue = a.hasOverdueDebt(now);
    final bHasOverdue = b.hasOverdueDebt(now);
    if (aHasOverdue && !bHasOverdue) return -1;
    if (!aHasOverdue && bHasOverdue) return 1;

    if (a.priorOverdueCount != b.priorOverdueCount) {
      return b.priorOverdueCount.compareTo(a.priorOverdueCount);
    }

    return RecurringDeposit.defaultCompare(a.deposit, b.deposit);
  });

  return UnmodifiableListView(filtered);
}
