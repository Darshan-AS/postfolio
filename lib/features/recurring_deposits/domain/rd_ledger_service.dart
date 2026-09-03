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
      // Get last day of the installment month
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
        ),
      );
    }

    return schedule;
  }

  /// Allocates an incoming customer payment across pending installments chronologically.
  /// Calculates and applies the standard 1% late fee if paid late and late fee is currently 0.
  /// Returns the generated [RDTransaction] and list of only [RDInstallment]s that were updated.
  static RDAllocationResult allocateCustomerPayment({
    required List<RDInstallment> currentSchedule,
    required double paymentAmount,
    required DateTime paidDate,
    required RDPaymentMode paymentMode,
    required String rdId,
    String? transactionId,
  }) {
    final txId = transactionId ?? const Uuid().v4();
    final List<RDInstallment> updatedInstallments = [];
    double remainingPool = paymentAmount;

    // Create a mutable list of unpaid/partially paid installments sorted chronologically
    final List<RDInstallment> activeInstallments = currentSchedule
        .where((inst) => inst.customerStatus != RDInstallmentStatus.fullyPaid)
        .toList()
      ..sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    for (var inst in activeInstallments) {
      if (remainingPool <= 0) break;

      double currentLateFee = inst.lateFee;

      // Calculate 1% late fee if paid past due date and late fee is not already applied
      if (paidDate.isAfter(inst.dueDate) && inst.lateFee == 0.0) {
        currentLateFee = (inst.installmentAmount * 0.01).ceilToDouble();
      }

      final double outstanding =
          inst.installmentAmount + currentLateFee - inst.customerPaidAmount;

      RDInstallment updatedInst;

      if (remainingPool >= outstanding) {
        remainingPool -= outstanding;
        updatedInst = inst.copyWith(
          customerPaidAmount: inst.installmentAmount + currentLateFee,
          customerStatus: RDInstallmentStatus.fullyPaid,
          lateFee: currentLateFee,
          updatedAt: DateTime.now(),
        );
      } else {
        updatedInst = inst.copyWith(
          customerPaidAmount: inst.customerPaidAmount + remainingPool,
          customerStatus: RDInstallmentStatus.partiallyPaid,
          lateFee: currentLateFee,
          updatedAt: DateTime.now(),
        );
        remainingPool = 0.0;
      }

      updatedInstallments.add(updatedInst);
    }

    final transaction = RDTransaction(
      id: txId,
      rdId: rdId,
      paidDate: paidDate,
      amount: paymentAmount,
      paymentMode: paymentMode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return RDAllocationResult(
      transaction: transaction,
      updatedInstallments: updatedInstallments,
      leftoverAmount: remainingPool,
    );
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
