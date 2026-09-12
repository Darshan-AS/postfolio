import 'package:uuid/uuid.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';

class RDLedgerService {
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
      final installmentDate = addMonths(startDate, i);
      final dueDate = calculateDueDate(startDate, installmentDate);
      final isPrePaid = i < initialPaidInstallments;

      schedule.add(
        RDInstallment(
          id: const Uuid().v4(),
          rdId: rdId,
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

  /// Allocates an incoming customer payment across pending installments chronologically.
  /// Calculates and applies the standard 1% late fee if paid late and late fee is currently 0.
  /// Supports explicit split components: [installmentComponent] (principal) and [lateFeeComponent] (default fees).
  /// If split components are omitted, automatically prioritizes base installments, allocating excess funds to pending default fees.
  /// Respects [isLateFeeWaived] flags and returns the generated [RDTransaction] and updated installments.
  static RDAllocationResult allocateCustomerPayment({
    required List<RDInstallment> currentSchedule,
    required double paymentAmount,
    required DateTime paidDate,
    required RDPaymentMode paymentMode,
    required String rdId,
    double? installmentComponent,
    double? lateFeeComponent,
    String? transactionId,
  }) {
    final txId = transactionId ?? const Uuid().v4();

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

    final (installmentPool, lateFeePool) = _resolveSplitPools(
      paymentAmount: paymentAmount,
      installmentComponent: installmentComponent,
      lateFeeComponent: lateFeeComponent,
      baseInstallment: baseInstallment,
      totalPendingLateFees: totalPendingLateFees,
    );

    // 3. Pass 1: Allocate principal pool chronologically
    final (principalLeftover, principalUpdatedIds) =
        _allocatePrincipalPool(scheduleMap: scheduleMap, pool: installmentPool);
    updatedIds.addAll(principalUpdatedIds);

    // 4. Pass 2: Allocate late fee pool chronologically
    final (feeLeftover, feeUpdatedIds) =
        _allocateLateFeePool(scheduleMap: scheduleMap, pool: lateFeePool);
    updatedIds.addAll(feeUpdatedIds);

    // 5. Construct resulting transaction & sorted updated installments
    final transaction = RDTransaction(
      id: txId,
      rdId: rdId,
      paidDate: paidDate,
      amount: paymentAmount,
      paymentMode: paymentMode,
      installmentAmount: installmentPool,
      lateFeeAmount: lateFeePool,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedInstallments =
        updatedIds.map((id) => scheduleMap[id]!).toList()
          ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    return RDAllocationResult(
      transaction: transaction,
      updatedInstallments: updatedInstallments,
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
        final result = allocateCustomerPayment(
          currentSchedule: runningSchedule,
          paymentAmount: tx.amount,
          installmentComponent:
              (tx.installmentAmount > 0 || tx.lateFeeAmount > 0)
                  ? tx.installmentAmount
                  : null,
          lateFeeComponent:
              (tx.installmentAmount > 0 || tx.lateFeeAmount > 0)
                  ? tx.lateFeeAmount
                  : null,
          paidDate: tx.paidDate,
          paymentMode: tx.paymentMode,
          rdId: tx.rdId,
          transactionId: tx.id,
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
          paidDate.isAfter(inst.dueDate)) {
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
      final RDInstallment updated;

      if (remaining >= needed) {
        remaining -= needed;
        updated = inst.copyWith(
          customerPaidAmount: inst.installmentAmount,
          customerStatus: RDInstallmentStatus.fullyPaid,
          updatedAt: DateTime.now(),
        );
      } else {
        updated = inst.copyWith(
          customerPaidAmount: inst.customerPaidAmount + remaining,
          customerStatus: RDInstallmentStatus.partiallyPaid,
          updatedAt: DateTime.now(),
        );
        remaining = 0.0;
      }

      scheduleMap[updated.id] = updated;
      updatedIds.add(updated.id);
    }

    return (remaining, updatedIds);
  }

  /// Allocates late fee pool chronologically across pending default fees.
  static (double leftover, Set<String> updatedIds) _allocateLateFeePool({
    required Map<String, RDInstallment> scheduleMap,
    required double pool,
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
      final RDInstallment updated;

      if (remaining >= feeNeeded) {
        remaining -= feeNeeded;
        updated = inst.copyWith(
          paidLateFee: inst.lateFee,
          updatedAt: DateTime.now(),
        );
      } else {
        updated = inst.copyWith(
          paidLateFee: inst.paidLateFee + remaining,
          updatedAt: DateTime.now(),
        );
        remaining = 0.0;
      }

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
  final double leftoverAmount;

  RDAllocationResult({
    required this.transaction,
    required this.updatedInstallments,
    required this.leftoverAmount,
  });
}
