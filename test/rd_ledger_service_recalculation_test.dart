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
  });
}
