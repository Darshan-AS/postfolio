import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('RDLedgerService.recomputeScheduleFromTransactions', () {
    final rdId = const Uuid().v4();
    final startDate = DateTime(2026, 1, 1);

    late List<RDInstallment> initialSchedule;

    setUp(() {
      initialSchedule = RDLedgerService.generateInitialSchedule(
        rdId: rdId,
        startDate: startDate,
        installmentAmount: 1000.0,
        termYears: 1,
        termMonths: 0,
        initialPaidInstallments: 0,
      );
    });

    test('recomputes schedule cleanly when deleting the only transaction', () {
      final tx1 = RDTransaction(
        id: 'tx-1',
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
      );

      // Allocate tx1
      final alloc = RDLedgerService.allocateCustomerPayment(
        currentSchedule: initialSchedule,
        paymentAmount: tx1.amount,
        paidDate: tx1.paidDate,
        paymentMode: tx1.paymentMode,
        rdId: rdId,
        transactionId: tx1.id,
      );

      final scheduleWithPayment = initialSchedule.map((inst) {
        return alloc.updatedInstallments.cast<RDInstallment?>().firstWhere(
                  (u) => u?.id == inst.id,
                  orElse: () => null,
                ) ??
            inst;
      }).toList();

      expect(scheduleWithPayment.first.customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithPayment.first.customerPaidAmount, 1000.0);

      // Recompute with empty transactions (simulating deletion of tx1)
      final recomputed = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleWithPayment,
        transactions: [],
        initialPaidInstallments: 0,
      );

      expect(recomputed.length, 12);
      for (final inst in recomputed) {
        expect(inst.customerStatus, RDInstallmentStatus.unpaid);
        expect(inst.customerPaidAmount, 0.0);
        expect(inst.lateFee, 0.0);
      }
    });

    test('recomputes schedule when deleting second transaction', () {
      final tx1 = RDTransaction(
        id: 'tx-1',
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
        createdAt: DateTime(2026, 1, 10, 10, 0),
      );

      final tx2 = RDTransaction(
        id: 'tx-2',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.upi,
        createdAt: DateTime(2026, 2, 10, 10, 0),
      );

      // Recompute with both tx1 and tx2
      final scheduleWithBoth = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [tx1, tx2],
        initialPaidInstallments: 0,
      );

      expect(scheduleWithBoth[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithBoth[1].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithBoth[2].customerStatus, RDInstallmentStatus.unpaid);

      // Now recompute without tx2 (deleted tx2)
      final scheduleWithoutTx2 = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleWithBoth,
        transactions: [tx1],
        initialPaidInstallments: 0,
      );

      expect(scheduleWithoutTx2[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithoutTx2[1].customerStatus, RDInstallmentStatus.unpaid);
      expect(scheduleWithoutTx2[1].customerPaidAmount, 0.0);
    });

    test('preserves opening baseline when recomputing transactions', () {
      final baselineSchedule = RDLedgerService.generateInitialSchedule(
        rdId: rdId,
        startDate: startDate,
        installmentAmount: 1000.0,
        termYears: 1,
        termMonths: 0,
        initialPaidInstallments: 2, // Months 1 and 2 are opening baseline
      );

      final tx1 = RDTransaction(
        id: 'tx-1',
        rdId: rdId,
        paidDate: DateTime(2026, 3, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
      );

      final scheduleWithPayment = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: baselineSchedule,
        transactions: [tx1],
        initialPaidInstallments: 2,
      );

      expect(scheduleWithPayment[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithPayment[1].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleWithPayment[2].customerStatus, RDInstallmentStatus.fullyPaid);

      // Now delete tx1
      final scheduleAfterDelete = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleWithPayment,
        transactions: [],
        initialPaidInstallments: 2,
      );

      expect(scheduleAfterDelete[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleAfterDelete[1].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleAfterDelete[2].customerStatus, RDInstallmentStatus.unpaid);
      expect(scheduleAfterDelete[2].customerPaidAmount, 0.0);
    });

    test('preserves PO settlement status (poStatus, poPaidDate) across recomputations', () {
      final poPaidDate = DateTime(2026, 1, 15);
      final scheduleWithPo = initialSchedule.map((inst) {
        if (inst.installmentDate.month == 1) {
          return inst.copyWith(
            poStatus: RDPoStatus.paid,
            poPaidDate: poPaidDate,
          );
        }
        return inst;
      }).toList();

      final tx1 = RDTransaction(
        id: 'tx-1',
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
      );

      final recomputed = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleWithPo,
        transactions: [tx1],
        initialPaidInstallments: 0,
      );

      expect(recomputed[0].poStatus, RDPoStatus.paid);
      expect(recomputed[0].poPaidDate, poPaidDate);
      expect(recomputed[0].customerStatus, RDInstallmentStatus.fullyPaid);

      // Even if customer payment is deleted, PO status remains intact (Advanced to PO)
      final afterDelete = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: recomputed,
        transactions: [],
        initialPaidInstallments: 0,
      );

      expect(afterDelete[0].poStatus, RDPoStatus.paid);
      expect(afterDelete[0].poPaidDate, poPaidDate);
      expect(afterDelete[0].customerStatus, RDInstallmentStatus.unpaid);
    });

    test('recomputes correctly when editing transaction amount', () {
      final txOriginal = RDTransaction(
        id: 'tx-1',
        rdId: rdId,
        paidDate: DateTime(2026, 1, 10),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
      );

      final scheduleOriginal = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [txOriginal],
        initialPaidInstallments: 0,
      );

      expect(scheduleOriginal[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleOriginal[0].customerPaidAmount, 1000.0);

      // Now edit tx1 to ₹500
      final txEditedDown = txOriginal.copyWith(amount: 500.0);
      final scheduleEditedDown = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleOriginal,
        transactions: [txEditedDown],
        initialPaidInstallments: 0,
      );

      expect(scheduleEditedDown[0].customerStatus, RDInstallmentStatus.partiallyPaid);
      expect(scheduleEditedDown[0].customerPaidAmount, 500.0);

      // Now edit tx1 to ₹2500 (covers month 1, month 2, and 500 into month 3)
      final txEditedUp = txOriginal.copyWith(amount: 2500.0);
      final scheduleEditedUp = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleOriginal,
        transactions: [txEditedUp],
        initialPaidInstallments: 0,
      );

      expect(scheduleEditedUp[0].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleEditedUp[0].customerPaidAmount, 1000.0);
      expect(scheduleEditedUp[1].customerStatus, RDInstallmentStatus.fullyPaid);
      expect(scheduleEditedUp[1].customerPaidAmount, 1000.0);
      expect(scheduleEditedUp[2].customerStatus, RDInstallmentStatus.partiallyPaid);
      expect(scheduleEditedUp[2].customerPaidAmount, 500.0);
    });

    test('paying round installment amount on overdue installment leaves default fee pending', () {
      // Month 1 due date is Jan 15/31, 2026. Payment made on Feb 20, 2026 (overdue).
      final txOverdue = RDTransaction(
        id: 'tx-overdue',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 20),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
        installmentAmount: 1000.0,
        lateFeeAmount: 0.0,
      );

      final schedule = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [txOverdue],
        initialPaidInstallments: 0,
      );

      final m1 = schedule[0];
      // Principal is fully paid
      expect(m1.customerPaidAmount, 1000.0);
      expect(m1.isInstallmentPaid, isTrue);
      // Late fee assessed because payment date is after due date
      expect(m1.lateFee, greaterThan(0.0));
      // Fee remains pending
      expect(m1.paidLateFee, 0.0);
      expect(m1.outstandingLateFee, greaterThan(0.0));
      expect(m1.isLateFeeResolved, isFalse);
      expect(m1.isFullySettled, isFalse);
    });

    test('paying round installments for 2 overdue months leaves fees pending for both', () {
      // Month 1 and Month 2 overdue. Payment of ₹2,000 made on March 20, 2026.
      final txTwoMonths = RDTransaction(
        id: 'tx-2m',
        rdId: rdId,
        paidDate: DateTime(2026, 3, 20),
        amount: 2000.0,
        paymentMode: RDPaymentMode.cash,
        installmentAmount: 2000.0,
        lateFeeAmount: 0.0,
      );

      final schedule = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [txTwoMonths],
        initialPaidInstallments: 0,
      );

      final m1 = schedule[0];
      final m2 = schedule[1];

      expect(m1.isInstallmentPaid, isTrue);
      expect(m1.paidLateFee, 0.0);
      expect(m1.lateFee, greaterThan(0.0));
      expect(m1.isFullySettled, isFalse);

      expect(m2.isInstallmentPaid, isTrue);
      expect(m2.paidLateFee, 0.0);
      expect(m2.lateFee, greaterThan(0.0));
      expect(m2.isFullySettled, isFalse);
    });

    test('paying fee-only transaction settles pending default fees', () {
      // Step 1: Pay principal ₹1,000 overdue
      final txPrincipal = RDTransaction(
        id: 'tx-p',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 20),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
        installmentAmount: 1000.0,
        lateFeeAmount: 0.0,
        createdAt: DateTime(2026, 2, 20, 10, 0),
      );

      final scheduleStep1 = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [txPrincipal],
        initialPaidInstallments: 0,
      );

      final pendingFee = scheduleStep1[0].outstandingLateFee;
      expect(pendingFee, greaterThan(0.0));

      // Step 2: Customer pays pending fee only
      final txFee = RDTransaction(
        id: 'tx-fee',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 25),
        amount: pendingFee,
        paymentMode: RDPaymentMode.upi,
        installmentAmount: 0.0,
        lateFeeAmount: pendingFee,
        createdAt: DateTime(2026, 2, 25, 10, 0),
      );

      final scheduleStep2 = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleStep1,
        transactions: [txPrincipal, txFee],
        initialPaidInstallments: 0,
      );

      final m1Settled = scheduleStep2[0];
      expect(m1Settled.isInstallmentPaid, isTrue);
      expect(m1Settled.paidLateFee, pendingFee);
      expect(m1Settled.outstandingLateFee, 0.0);
      expect(m1Settled.isLateFeeResolved, isTrue);
      expect(m1Settled.isFullySettled, isTrue);
    });

    test('fee forgiveness (isLateFeeWaived) persists across recomputations and avoids late fee assessment', () {
      // Waive late fee on Month 1
      final scheduleWithWaiver = initialSchedule.map((inst) {
        if (inst == initialSchedule.first) {
          return inst.copyWith(isLateFeeWaived: true);
        }
        return inst;
      }).toList();

      expect(scheduleWithWaiver[0].isLateFeeWaived, isTrue);
      expect(scheduleWithWaiver[0].effectiveLateFee, 0.0);
      expect(scheduleWithWaiver[0].outstandingLateFee, 0.0);
      expect(scheduleWithWaiver[0].isLateFeeResolved, isTrue);

      // Pay overdue
      final txOverdue = RDTransaction(
        id: 'tx-overdue',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 20),
        amount: 1000.0,
        paymentMode: RDPaymentMode.cash,
      );

      final recomputed = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: scheduleWithWaiver,
        transactions: [txOverdue],
        initialPaidInstallments: 0,
      );

      final m1 = recomputed[0];
      // Waiver is preserved!
      expect(m1.isLateFeeWaived, isTrue);
      expect(m1.lateFee, 0.0);
      expect(m1.paidLateFee, 0.0);
      expect(m1.isInstallmentPaid, isTrue);
      expect(m1.isFullySettled, isTrue);
    });

    test('split transaction with both principal and late fee replays accurately', () {
      // Month 1 due Jan 15, paid Feb 20 (1 month defaulted -> ₹10 late fee).
      final txSplit = RDTransaction(
        id: 'tx-split',
        rdId: rdId,
        paidDate: DateTime(2026, 2, 20),
        amount: 1010.0,
        installmentAmount: 1000.0,
        lateFeeAmount: 10.0,
        paymentMode: RDPaymentMode.cash,
      );

      final schedule = RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: initialSchedule,
        transactions: [txSplit],
        initialPaidInstallments: 0,
      );

      final m1 = schedule[0];
      expect(m1.customerPaidAmount, 1000.0);
      expect(m1.isInstallmentPaid, isTrue);
      expect(m1.paidLateFee, 10.0);
      expect(m1.outstandingLateFee, 0.0);
      expect(m1.isFullySettled, isTrue);
    });
  });
}
