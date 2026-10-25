import 'package:uuid/uuid.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_payment_allocation_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

class RDLedgerService {
  /// Generates a deterministic UUIDv5 for a given RD account and 1-based installment number.
  static String deterministicInstallmentId(String rdId, int installmentNo) {
    return const Uuid().v5(
      Namespace.url.value,
      'postfolio:rd:$rdId:inst:$installmentNo',
    );
  }

  /// Resolves the 1-based installment sequence number (1..totalMonths) for a given calendar month.
  static int resolveInstallmentNo(DateTime startDate, DateTime installmentDate) {
    return (installmentDate.year - startDate.year) * 12 +
        (installmentDate.month - startDate.month) +
        1;
  }

  /// Safely adds calendar months to a start date without causing calendar overflow drift.
  /// E.g., Jan 31st + 1 month = Feb 28th/29th.
  static DateTime addMonths(DateTime start, int months) {
    int targetYear = start.year + (start.month + months - 1) ~/ 12;
    int targetMonth = (start.month + months - 1) % 12 + 1;
    int targetDay = start.day;
    int maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > maxDays) {
      targetDay = maxDays;
    }
    return DateTime(targetYear, targetMonth, targetDay);
  }

  /// Resolves the installment due date based on standard Indian Post Office rules.
  /// - Opened 1st to 15th: due on the 15th of that installment month.
  /// - Opened 16th to end of month: due on the last day of that installment month.
  static DateTime calculateDueDate(DateTime startDate, DateTime installmentDate) {
    if (startDate.day <= 15) {
      return DateTime(installmentDate.year, installmentDate.month, 15);
    } else {
      return DateTime(installmentDate.year, installmentDate.month + 1, 0);
    }
  }

  /// Generates the complete chronological list of installments for an RD account.
  static List<RDInstallment> generateInitialSchedule({
    required String rdId,
    required DateTime startDate,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required int initialPaidInstallments,
  }) {
    final int totalMonths = termYears * 12 + termMonths;
    final List<RDInstallment> schedule = [];

    for (int i = 0; i < totalMonths; i++) {
      final installmentNo = i + 1;
      final installmentDate = addMonths(startDate, i);
      final dueDate = calculateDueDate(startDate, installmentDate);
      final isPrePaid = i < initialPaidInstallments;

      schedule.add(
        RDInstallment(
          id: deterministicInstallmentId(rdId, installmentNo),
          rdId: rdId,
          installmentNo: installmentNo,
          installmentDate: installmentDate,
          dueDate: dueDate,
          installmentAmount: installmentAmount,
          customerPaidAmount: isPrePaid ? installmentAmount : 0.0,
          customerStatus: isPrePaid
              ? RDInstallmentStatus.fullyPaid
              : RDInstallmentStatus.unpaid,
          poStatus: isPrePaid ? RDPoStatus.paid : RDPoStatus.unpaid,
          poPaidDate: isPrePaid ? dueDate : null,
          lateFee: 0.0,
          paidLateFee: 0.0,
          isLateFeeWaived: false,
        ),
      );
    }

    return schedule;
  }

  /// Hydrates the full 60-month schedule in O(N) time by merging deterministic calendar
  /// baseline installments with sparse database installment rows.
  static List<RDInstallment> hydrateSchedule({
    required RecurringDeposit deposit,
    required List<RDInstallment> sparseInstallments,
  }) {
    final baseline = generateInitialSchedule(
      rdId: deposit.id,
      startDate: deposit.startDate,
      installmentAmount: deposit.installmentAmount,
      termYears: deposit.termYears,
      termMonths: deposit.termMonths,
      initialPaidInstallments: deposit.initialPaidInstallments,
    );

    if (sparseInstallments.isEmpty) return baseline;

    final byNo = <int, RDInstallment>{};
    final byMonthKey = <int, RDInstallment>{};
    for (final inst in sparseInstallments) {
      final resolvedNo = inst.installmentNo ??
          resolveInstallmentNo(deposit.startDate, inst.installmentDate);
      byNo[resolvedNo] = inst.copyWith(installmentNo: resolvedNo);
      byMonthKey[inst.installmentDate.year * 12 + inst.installmentDate.month] =
          inst.copyWith(installmentNo: resolvedNo);
    }

    return [
      for (final base in baseline)
        byNo[base.installmentNo!] ??
            byMonthKey[
                base.installmentDate.year * 12 + base.installmentDate.month] ??
            base,
    ];
  }

  /// Hydrates a single calendar month's installment in O(1) time without generating 60 rows.
  /// Returns null if the deposit is not active in [targetMonth].
  static RDInstallment? hydrateInstallmentForMonth({
    required RecurringDeposit deposit,
    required DateTime targetMonth,
    RDInstallment? sparseInstallment,
  }) {
    final installmentNo = resolveInstallmentNo(deposit.startDate, targetMonth);
    final totalMonths = deposit.totalMonths;
    if (installmentNo < 1 || installmentNo > totalMonths) {
      return null;
    }

    if (sparseInstallment != null) {
      return sparseInstallment.copyWith(
        installmentNo: sparseInstallment.installmentNo ?? installmentNo,
      );
    }

    final monthIndex = installmentNo - 1;
    final installmentDate = addMonths(deposit.startDate, monthIndex);
    final dueDate = calculateDueDate(deposit.startDate, installmentDate);
    final isPrePaid = monthIndex < deposit.initialPaidInstallments;

    return RDInstallment(
      id: deterministicInstallmentId(deposit.id, installmentNo),
      rdId: deposit.id,
      installmentNo: installmentNo,
      installmentDate: installmentDate,
      dueDate: dueDate,
      installmentAmount: deposit.installmentAmount,
      customerPaidAmount: isPrePaid ? deposit.installmentAmount : 0.0,
      customerStatus: isPrePaid
          ? RDInstallmentStatus.fullyPaid
          : RDInstallmentStatus.unpaid,
      poStatus: isPrePaid ? RDPoStatus.paid : RDPoStatus.unpaid,
      poPaidDate: isPrePaid ? dueDate : null,
      lateFee: 0.0,
      paidLateFee: 0.0,
      isLateFeeWaived: false,
    );
  }

  /// Filters a full schedule down to only the rows that deviate from the untouched baseline.
  static List<RDInstallment> extractSparseInstallments(
    List<RDInstallment> schedule, {
    required int initialPaidInstallments,
  }) {
    final sorted = [...schedule]
      ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));
    final sparse = <RDInstallment>[];

    for (int i = 0; i < sorted.length; i++) {
      final inst = sorted[i];
      final isPrePaid = i < initialPaidInstallments;
      if (isPrePaid) {
        final isUntouchedPrepaid =
            inst.customerPaidAmount == inst.installmentAmount &&
                inst.customerStatus == RDInstallmentStatus.fullyPaid &&
                inst.poStatus == RDPoStatus.paid &&
                inst.lateFee == 0.0 &&
                inst.paidLateFee == 0.0 &&
                !inst.isLateFeeWaived;
        if (!isUntouchedPrepaid) {
          sparse.add(inst.copyWith(installmentNo: inst.installmentNo ?? (i + 1)));
        }
      } else {
        final isUntouchedFuture = inst.customerPaidAmount == 0.0 &&
            inst.customerStatus == RDInstallmentStatus.unpaid &&
            inst.poStatus == RDPoStatus.unpaid &&
            inst.lateFee == 0.0 &&
            inst.paidLateFee == 0.0 &&
            !inst.isLateFeeWaived;
        if (!isUntouchedFuture) {
          sparse.add(inst.copyWith(installmentNo: inst.installmentNo ?? (i + 1)));
        }
      }
    }
    return sparse;
  }

  /// Computes the minimal delta of installments whose ledger state changed between [before] and [after].
  static List<RDInstallment> diffSchedules(
    List<RDInstallment> before,
    List<RDInstallment> after,
  ) {
    final beforeById = {for (final b in before) b.id: b};
    final beforeByMonth = {
      for (final b in before)
        (b.installmentDate.year * 12 + b.installmentDate.month): b,
    };

    final changed = <RDInstallment>[];
    for (int i = 0; i < after.length; i++) {
      final a = after[i];
      final b = beforeById[a.id] ??
          beforeByMonth[a.installmentDate.year * 12 + a.installmentDate.month];
      if (b == null || !_isSameLedgerState(b, a)) {
        changed.add(a.copyWith(installmentNo: a.installmentNo ?? (i + 1)));
      }
    }
    return changed;
  }

  static bool _isSameLedgerState(RDInstallment a, RDInstallment b) {
    return a.customerPaidAmount == b.customerPaidAmount &&
        a.customerStatus == b.customerStatus &&
        a.poStatus == b.poStatus &&
        a.poPaidDate == b.poPaidDate &&
        a.lateFee == b.lateFee &&
        a.paidLateFee == b.paidLateFee &&
        a.isLateFeeWaived == b.isLateFeeWaived;
  }

  /// Allocates an incoming customer payment across pending installments chronologically.
  /// Calculates and applies the standard 1% late fee if paid late and late fee is currently 0.
  /// Supports explicit split components: [installmentComponent] (principal) and [lateFeeComponent] (default fees).
  /// If split components are omitted, automatically prioritizes base installments, allocating excess funds to pending default fees.
  /// Respects [isLateFeeWaived] flags and returns the generated [RDTransaction], [RDPaymentAllocation] lineage, and updated installments.
  static RDAllocationResult allocateCustomerPayment({
    required List<RDInstallment> currentSchedule,
    required double paymentAmount,
    required DateTime paidDate,
    required RDPaymentMode paymentMode,
    required String rdId,
    PaymentSplitMode? splitMode,
    double? installmentComponent,
    double? lateFeeComponent,
    String? transactionId,
    bool allowPoolOverflow = false,
  }) {
    final txId = transactionId ?? const Uuid().v4();
    final startDate = currentSchedule.isNotEmpty
        ? currentSchedule.first.installmentDate
        : paidDate;

    // 1. Assess overdue late fees dynamically
    final (scheduleMap, assessedIds) =
        _assessOverdueLateFees(currentSchedule, paidDate);
    final Set<String> updatedIds = {...assessedIds};

    // 2. Resolve payment split pools (principal vs fees)
    final totalPendingLateFees =
        _calculatePendingLateFees(scheduleMap.values);
    final baseInstallment = currentSchedule.isNotEmpty
        ? currentSchedule.first.installmentAmount
        : 0.0;

    final resolvedMode = splitMode ??
        _inferSplitMode(
          paymentAmount: paymentAmount,
          installmentComponent: installmentComponent,
          lateFeeComponent: lateFeeComponent,
        );

    final (initialInstallmentPool, initialLateFeePool) = _resolveSplitPools(
      paymentAmount: paymentAmount,
      installmentComponent: installmentComponent,
      lateFeeComponent: lateFeeComponent,
      baseInstallment: baseInstallment,
      totalPendingLateFees: totalPendingLateFees,
    );

    final Map<int, ({double principal, double fee})> allocationsByMonth = {};

    // 3. Pass 1: Allocate principal pool chronologically
    var (principalLeftover, principalUpdatedIds) = _allocatePrincipalPool(
      scheduleMap: scheduleMap,
      pool: initialInstallmentPool,
      startDate: startDate,
      allocationsByMonth: allocationsByMonth,
    );
    updatedIds.addAll(principalUpdatedIds);

    // 4. Pass 2: Allocate late fee pool chronologically
    var (feeLeftover, feeUpdatedIds) = _allocateLateFeePool(
      scheduleMap: scheduleMap,
      pool: initialLateFeePool,
      startDate: startDate,
      allocationsByMonth: allocationsByMonth,
    );
    updatedIds.addAll(feeUpdatedIds);

    // 5. Pass 3 (Overflow Integrity): If replay/auto mode has leftover fee pool while principal is unpaid
    // (or leftover principal pool while fees are unpaid), overflow so customer funds are never silently dropped.
    final canOverflowToPrincipal = allowPoolOverflow &&
        resolvedMode != PaymentSplitMode.feesOnly &&
        feeLeftover > 0;
    if (canOverflowToPrincipal) {
      final (remPrincipal, extraIds) = _allocatePrincipalPool(
        scheduleMap: scheduleMap,
        pool: feeLeftover,
        startDate: startDate,
        allocationsByMonth: allocationsByMonth,
      );
      feeLeftover = remPrincipal;
      updatedIds.addAll(extraIds);
    }

    final canOverflowToFees = allowPoolOverflow &&
        resolvedMode != PaymentSplitMode.installmentsOnly &&
        principalLeftover > 0;
    if (canOverflowToFees) {
      final (remFee, extraIds) = _allocateLateFeePool(
        scheduleMap: scheduleMap,
        pool: principalLeftover,
        startDate: startDate,
        allocationsByMonth: allocationsByMonth,
      );
      principalLeftover = remFee;
      updatedIds.addAll(extraIds);
    }

    // Build normalized RDPaymentAllocation records
    final allocations = <RDPaymentAllocation>[];
    final sortedMonthNos = allocationsByMonth.keys.toList()..sort();
    double actualPrincipalAllocated = 0.0;
    double actualFeeAllocated = 0.0;

    for (final monthNo in sortedMonthNos) {
      final entry = allocationsByMonth[monthNo]!;
      if (entry.principal > 0 || entry.fee > 0) {
        actualPrincipalAllocated += entry.principal;
        actualFeeAllocated += entry.fee;
        allocations.add(
          RDPaymentAllocation(
            id: const Uuid().v5(
              Namespace.url.value,
              'postfolio:tx:$txId:inst:$monthNo',
            ),
            transactionId: txId,
            rdId: rdId,
            installmentNo: monthNo,
            principalAmount: entry.principal,
            lateFeeAmount: entry.fee,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    // 6. Construct resulting transaction & sorted updated installments
    final transaction = RDTransaction(
      id: txId,
      rdId: rdId,
      paidDate: paidDate,
      amount: paymentAmount,
      paymentMode: paymentMode,
      splitMode: resolvedMode,
      installmentAmount: allowPoolOverflow
          ? actualPrincipalAllocated
          : initialInstallmentPool,
      lateFeeAmount:
          allowPoolOverflow ? actualFeeAllocated : initialLateFeePool,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedInstallments =
        updatedIds.map((id) => scheduleMap[id]!).toList()
          ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    return RDAllocationResult(
      transaction: transaction,
      updatedInstallments: updatedInstallments,
      allocations: allocations,
      leftoverAmount: principalLeftover + feeLeftover,
    );
  }

  /// Recomputes all customer payment allocations and late fees across the entire schedule
  /// by resetting customer payments (respecting opening baseline and fee waivers) and sequentially replaying transactions.
  /// Preserves PO settlement status, fee waivers, and installment calendar identity.
  static List<RDInstallment> recomputeScheduleFromTransactions({
    required List<RDInstallment> currentSchedule,
    required List<RDTransaction> transactions,
    required int initialPaidInstallments,
  }) {
    final baselineSchedule =
        _buildBaselineSchedule(currentSchedule, initialPaidInstallments);
    final sortedTransactions = [...transactions]..sort(_chronologicalTxOrder);

    return sortedTransactions.fold<List<RDInstallment>>(
      baselineSchedule,
      (runningSchedule, tx) {
        final hasExplicitSplit =
            tx.installmentAmount > 0 || tx.lateFeeAmount > 0;
        final result = allocateCustomerPayment(
          currentSchedule: runningSchedule,
          paymentAmount: tx.amount,
          splitMode: tx.splitMode,
          installmentComponent:
              hasExplicitSplit ? tx.installmentAmount : null,
          lateFeeComponent: hasExplicitSplit ? tx.lateFeeAmount : null,
          paidDate: tx.paidDate,
          paymentMode: tx.paymentMode,
          rdId: tx.rdId,
          transactionId: tx.id,
          allowPoolOverflow: true,
        );

        final updatedMap = {
          for (final u in result.updatedInstallments) u.id: u,
        };
        return runningSchedule
            .map((inst) => updatedMap[inst.id] ?? inst)
            .toList();
      },
    );
  }

  // --- Pure Helper Functions ---

  static PaymentSplitMode _inferSplitMode({
    required double paymentAmount,
    required double? installmentComponent,
    required double? lateFeeComponent,
  }) {
    if (installmentComponent == null && lateFeeComponent == null) {
      return PaymentSplitMode.includeFees;
    }
    final inst = installmentComponent ?? 0.0;
    final fee = lateFeeComponent ?? 0.0;
    if (inst > 0 && fee == 0.0) return PaymentSplitMode.installmentsOnly;
    if (fee > 0 && inst == 0.0) return PaymentSplitMode.feesOnly;
    return PaymentSplitMode.includeFees;
  }

  /// Evaluates and assigns dynamic 1% default fees for overdue installments.
  static (Map<String, RDInstallment> scheduleMap, Set<String> assessedIds)
      _assessOverdueLateFees(
    List<RDInstallment> currentSchedule,
    DateTime paidDate,
  ) {
    final Map<String, RDInstallment> scheduleMap = {
      for (final inst in currentSchedule) inst.id: inst,
    };
    final Set<String> assessedIds = {};

    for (final inst in currentSchedule) {
      if (!inst.isLateFeeWaived &&
          inst.lateFee == 0.0 &&
          inst.isOverdueAt(paidDate)) {
        final fee = inst.computeExpectedLateFee(paidDate);
        if (fee > 0) {
          scheduleMap[inst.id] = inst.copyWith(lateFee: fee);
          assessedIds.add(inst.id);
        }
      }
    }
    return (scheduleMap, assessedIds);
  }

  /// Calculates the total pending (unpaid and unwaived) late fees across the schedule.
  static double _calculatePendingLateFees(
      Iterable<RDInstallment> installments) {
    return installments.fold<double>(
      0.0,
      (sum, inst) =>
          sum +
          (!inst.isLateFeeWaived
              ? (inst.lateFee - inst.paidLateFee).clamp(0.0, double.infinity)
              : 0.0),
    );
  }

  /// Pure mathematical function resolving (installmentPool, lateFeePool) across
  /// explicit split components and automatic heuristic allocations.
  static (double installmentPool, double lateFeePool) _resolveSplitPools({
    required double paymentAmount,
    required double? installmentComponent,
    required double? lateFeeComponent,
    required double baseInstallment,
    required double totalPendingLateFees,
  }) {
    if (installmentComponent != null && lateFeeComponent != null) {
      return (installmentComponent, lateFeeComponent);
    }
    if (installmentComponent != null) {
      final pool = installmentComponent;
      final fee = (paymentAmount - pool).clamp(0.0, double.infinity);
      return (pool, fee);
    }
    if (lateFeeComponent != null) {
      final fee = lateFeeComponent;
      final pool = (paymentAmount - fee).clamp(0.0, double.infinity);
      return (pool, fee);
    }

    // Heuristic allocation: round installment amounts clear principal first
    if (totalPendingLateFees <= 0.0) {
      return (paymentAmount, 0.0);
    }
    if (baseInstallment > 0 && paymentAmount >= baseInstallment) {
      final wholePortion = (paymentAmount ~/ baseInstallment) * baseInstallment;
      final remainder = paymentAmount - wholePortion;
      final feePool = remainder.clamp(0.0, totalPendingLateFees);
      return (paymentAmount - feePool, feePool);
    }
    if (baseInstallment > 0 && paymentAmount < baseInstallment) {
      final feePool = paymentAmount.clamp(0.0, totalPendingLateFees);
      return (paymentAmount - feePool, feePool);
    }

    return (paymentAmount, 0.0);
  }

  /// Allocates installment pool chronologically across pending base installments.
  static (double leftover, Set<String> updatedIds) _allocatePrincipalPool({
    required Map<String, RDInstallment> scheduleMap,
    required double pool,
    required DateTime startDate,
    required Map<int, ({double principal, double fee})> allocationsByMonth,
  }) {
    double remaining = pool;
    final Set<String> updatedIds = {};

    final unpaid = scheduleMap.values
        .where((inst) => inst.customerPaidAmount < inst.installmentAmount)
        .toList()
      ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    for (final inst in unpaid) {
      if (remaining <= 0) break;

      final needed = inst.installmentAmount - inst.customerPaidAmount;
      final monthNo =
          inst.installmentNo ?? resolveInstallmentNo(startDate, inst.installmentDate);
      final existingAlloc =
          allocationsByMonth[monthNo] ?? (principal: 0.0, fee: 0.0);
      final RDInstallment updated;
      final double applied;

      if (remaining >= needed) {
        applied = needed;
        remaining -= needed;
        updated = inst.copyWith(
          installmentNo: monthNo,
          customerPaidAmount: inst.installmentAmount,
          customerStatus: RDInstallmentStatus.fullyPaid,
          updatedAt: DateTime.now(),
        );
      } else {
        applied = remaining;
        updated = inst.copyWith(
          installmentNo: monthNo,
          customerPaidAmount: inst.customerPaidAmount + remaining,
          customerStatus: RDInstallmentStatus.partiallyPaid,
          updatedAt: DateTime.now(),
        );
        remaining = 0.0;
      }

      allocationsByMonth[monthNo] = (
        principal: existingAlloc.principal + applied,
        fee: existingAlloc.fee,
      );
      scheduleMap[updated.id] = updated;
      updatedIds.add(updated.id);
    }

    return (remaining, updatedIds);
  }

  /// Allocates late fee pool chronologically across pending default fees.
  static (double leftover, Set<String> updatedIds) _allocateLateFeePool({
    required Map<String, RDInstallment> scheduleMap,
    required double pool,
    required DateTime startDate,
    required Map<int, ({double principal, double fee})> allocationsByMonth,
  }) {
    double remaining = pool;
    final Set<String> updatedIds = {};

    final pendingFees = scheduleMap.values
        .where(
            (inst) => !inst.isLateFeeWaived && inst.lateFee > inst.paidLateFee)
        .toList()
      ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    for (final inst in pendingFees) {
      if (remaining <= 0) break;

      final feeNeeded = inst.lateFee - inst.paidLateFee;
      final monthNo =
          inst.installmentNo ?? resolveInstallmentNo(startDate, inst.installmentDate);
      final existingAlloc =
          allocationsByMonth[monthNo] ?? (principal: 0.0, fee: 0.0);
      final RDInstallment updated;
      final double applied;

      if (remaining >= feeNeeded) {
        applied = feeNeeded;
        remaining -= feeNeeded;
        updated = inst.copyWith(
          installmentNo: monthNo,
          paidLateFee: inst.lateFee,
          updatedAt: DateTime.now(),
        );
      } else {
        applied = remaining;
        updated = inst.copyWith(
          installmentNo: monthNo,
          paidLateFee: inst.paidLateFee + remaining,
          updatedAt: DateTime.now(),
        );
        remaining = 0.0;
      }

      allocationsByMonth[monthNo] = (
        principal: existingAlloc.principal,
        fee: existingAlloc.fee + applied,
      );
      scheduleMap[updated.id] = updated;
      updatedIds.add(updated.id);
    }

    return (remaining, updatedIds);
  }

  /// Resets all installments to opening baseline state while preserving PO settlement and fee waivers.
  static List<RDInstallment> _buildBaselineSchedule(
    List<RDInstallment> schedule,
    int initialPaidInstallments,
  ) {
    final sorted = [...schedule]
      ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    return [
      for (int i = 0; i < sorted.length; i++)
        sorted[i].copyWith(
          installmentNo: sorted[i].installmentNo ?? (i + 1),
          customerPaidAmount:
              i < initialPaidInstallments ? sorted[i].installmentAmount : 0.0,
          customerStatus: i < initialPaidInstallments
              ? RDInstallmentStatus.fullyPaid
              : RDInstallmentStatus.unpaid,
          lateFee: 0.0,
          paidLateFee: 0.0,
          isLateFeeWaived: sorted[i].isLateFeeWaived,
          updatedAt: DateTime.now(),
        ),
    ];
  }

  /// Stable comparator for transactions: paidDate -> createdAt -> id.
  static int _chronologicalTxOrder(RDTransaction a, RDTransaction b) {
    final dateComp = a.paidDate.compareTo(b.paidDate);
    if (dateComp != 0) return dateComp;
    if (a.createdAt != null && b.createdAt != null) {
      return a.createdAt!.compareTo(b.createdAt!);
    }
    return a.id.compareTo(b.id);
  }
}

class RDAllocationResult {
  final RDTransaction transaction;
  final List<RDInstallment> updatedInstallments;
  final List<RDPaymentAllocation> allocations;
  final double leftoverAmount;

  RDAllocationResult({
    required this.transaction,
    required this.updatedInstallments,
    this.allocations = const [],
    required this.leftoverAmount,
  });
}
