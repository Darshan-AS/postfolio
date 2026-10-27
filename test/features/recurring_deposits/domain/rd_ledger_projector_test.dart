import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

// ---------------------------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------------------------

const _rdId = 'rd-1';

RecurringDeposit deposit({
  double amount = 1000.0,
  DateTime? startDate,
  int termYears = 1,
  int termMonths = 0,
  int initialPaid = 0,
}) =>
    RecurringDeposit(
      id: _rdId,
      customerId: 'cust-1',
      schemeType: RecurringSchemeType.recurringDeposit,
      status: DepositStatus.active,
      installmentAmount: amount,
      interestRate: 6.7,
      termYears: termYears,
      termMonths: termMonths,
      startDate: startDate ?? DateTime(2026, 1, 10),
      initialPaidInstallments: initialPaid,
    );

RDTransaction tx(
  String id,
  double amount,
  DateTime paidDate, {
  PaymentSplitMode mode = PaymentSplitMode.includeFees,
  double inst = 0.0,
  double fee = 0.0,
}) =>
    RDTransaction(
      id: id,
      rdId: _rdId,
      paidDate: paidDate,
      amount: amount,
      paymentMode: RDPaymentMode.cash,
      splitMode: mode,
      installmentAmount: inst,
      lateFeeAmount: fee,
    );

RDPoDeposit po(int no, DateTime on) =>
    RDPoDeposit(rdId: _rdId, installmentNo: no, depositedOn: on);

RDFeeWaiver waiver(int no) =>
    RDFeeWaiver(rdId: _rdId, installmentNo: no, waivedOn: DateTime(2026, 6, 1));

const projector = RDLedgerProjector.standard;

void main() {
  group('RDLedgerRules', () {
    const rules = RDLedgerRules.standard;

    test('paying on the due date is not in default, even with a time-of-day', () {
      final due = DateTime(2026, 9, 15);
      expect(rules.isInDefault(due, DateTime(2026, 9, 15, 10, 30)), isFalse);
      expect(rules.isInDefault(due, DateTime(2026, 9, 16, 0, 0, 1)), isTrue);
      expect(rules.defaultedMonths(due, DateTime(2026, 9, 15, 23, 59)), 0);
      expect(rules.defaultedMonths(due, DateTime(2026, 9, 16)), 1);
      expect(rules.defaultedMonths(due, DateTime(2026, 11, 20)), 2);
    });

    test('default fee is exact in paise and rounded up to whole rupees', () {
      expect(rules.defaultFeeFor(1000, 1), 10);
      expect(rules.defaultFeeFor(1000, 3), 30);
      // 110 * 0.01 * 10 == 11.000000000000002 in doubles; must be 11, not 12.
      expect(rules.defaultFeeFor(110, 10), 11);
      // ₹1 per ₹100 or part thereof: 150 -> 1.5 -> 2.
      expect(rules.defaultFeeFor(150, 1), 2);
      expect(rules.defaultFeeFor(1000, 0), 0);
    });

    test('due date follows the 15th / end-of-month rule', () {
      expect(rules.dueDateFor(DateTime(2026, 1, 10), DateTime(2026, 2, 10)), DateTime(2026, 2, 15));
      expect(rules.dueDateFor(DateTime(2026, 1, 20), DateTime(2026, 2, 20)), DateTime(2026, 2, 28));
      expect(rules.dueDateFor(DateTime(2028, 1, 31), DateTime(2028, 2, 29)), DateTime(2028, 2, 29));
    });
  });

  group('RDScheduleFactory', () {
    test('addMonths clamps day overflow and installmentNoFor inverts it', () {
      final start = DateTime(2026, 1, 31);
      expect(RDScheduleFactory.addMonths(start, 1), DateTime(2026, 2, 28));
      expect(RDScheduleFactory.addMonths(start, 13), DateTime(2027, 2, 28));
      expect(RDScheduleFactory.installmentNoFor(start, DateTime(2027, 2, 1)), 14);
      expect(RDScheduleFactory.installmentNoFor(start, DateTime(2025, 12, 1)), 0);
    });

    test('baseline marks opening months paid+deposited and the rest pristine', () {
      final s = RDScheduleFactory.baselineSchedule(deposit(initialPaid: 2));
      expect(s, hasLength(12));
      expect(s[0].isOpeningBaseline, isTrue);
      expect(s[0].isPoDeposited, isTrue);
      expect(s[1].isInstallmentPaid, isTrue);
      expect(s[2].isOpeningBaseline, isFalse);
      expect(s[2].customerPaidAmount, 0);
      expect(s[2].isPoDeposited, isFalse);
      expect(s[2].installmentNo, 3);
      expect(s[2].id, RDScheduleFactory.installmentId(_rdId, 3));
    });
  });

  group('RDLedgerProjector — allocation', () {
    test('no facts yields a pristine schedule and summary', () {
      final p = projector.project(RDLedgerFacts(deposit: deposit()), asOf: DateTime(2026, 1, 1));
      expect(p.installments, hasLength(12));
      expect(p.installments.every((i) => !i.isInstallmentPaid), isTrue);
      expect(p.customerCredit, 0);
      expect(p.summary.paidThroughNo, 0);
      expect(p.summary.nextDueNo, 1);
      expect(p.summary.openItems, isEmpty);
    });

    test('allocates principal chronologically and respects the opening baseline', () {
      final facts = RDLedgerFacts(
        deposit: deposit(initialPaid: 2),
        transactions: [tx('t1', 2500, DateTime(2026, 3, 10))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 3, 10));
      expect(p.byNo(3)!.isInstallmentPaid, isTrue);
      expect(p.byNo(4)!.isInstallmentPaid, isTrue);
      expect(p.byNo(5)!.customerPaidAmount, 500);
      expect(p.byNo(5)!.customerStatus, RDInstallmentStatus.partiallyPaid);
      expect(p.summary.paidThroughNo, 4);
      expect(p.summary.nextDueNo, 5);
      final alloc = p.allocationsByTransaction['t1']!;
      expect(alloc.map((a) => a.installmentNo), [3, 4, 5]);
      expect(alloc.map((a) => a.principalAmount), [1000, 1000, 500]);
    });

    test('payment on the due date carries no fee', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 1000, DateTime(2026, 1, 15, 10, 30))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 1, 15, 18));
      expect(p.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p.byNo(1)!.lateFee, 0);
      expect(p.byNo(1)!.displayStatusAt(DateTime(2026, 1, 15, 18)),
          RDInstallmentDisplayStatus.collectedPendingPo);
    });

    test('fees accrue until settlement and freeze at the settlement date', () {
      // #1 due 15 Jan. A payment for #2 on 20 Feb assesses #1 at 1 month, but #1 stays
      // unpaid, so by 20 Jun it must owe 5 months, not 1.
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [
          tx('t1', 1000, DateTime(2026, 2, 20), mode: PaymentSplitMode.installmentsOnly),
        ],
      );
      // installmentsOnly means t1 cleared #1 (chronological), so use #1 settled on 20 Feb.
      final p1 = projector.project(facts, asOf: DateTime(2026, 6, 20));
      expect(p1.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p1.byNo(1)!.lateFee, 10, reason: 'frozen at 1 month on settlement day');
      // #2 (due 15 Feb) is still unpaid: 20 Feb .. 20 Jun = 4 months.
      expect(p1.byNo(2)!.lateFee, 40);
      expect(p1.byNo(2)!.outstandingLateFeeAt(DateTime(2026, 6, 20)), 40);
    });

    test('auto split sends whole installments to principal and remainder to fees', () {
      // #1 overdue since 15 Jan; on 20 Feb customer pays 1010 => 1000 principal + 10 fee.
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 1010, DateTime(2026, 2, 20))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 2, 20));
      expect(p.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p.byNo(1)!.paidLateFee, 10);
      expect(p.byNo(1)!.isFullySettled, isTrue);
      expect(p.customerCredit, 0);
    });

    test('feesOnly never touches principal; installmentsOnly never touches fees', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [
          tx('f', 10, DateTime(2026, 2, 20), mode: PaymentSplitMode.feesOnly),
          tx('p', 1000, DateTime(2026, 2, 21), mode: PaymentSplitMode.installmentsOnly),
        ],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 2, 21));
      expect(p.byNo(1)!.paidLateFee, 10);
      expect(p.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p.allocationsByTransaction['f']!.single.principalAmount, 0);
      expect(p.allocationsByTransaction['p']!.single.lateFeeAmount, 0);
    });

    test('custom split is honoured exactly', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [
          tx('c', 1500, DateTime(2026, 3, 20), mode: PaymentSplitMode.custom, inst: 1480, fee: 20),
        ],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 3, 20));
      // #1 fee 2 months = 20; #2 fee 1 month = 10. Fee pool 20 clears #1's fee only.
      expect(p.byNo(1)!.paidLateFee, 20);
      expect(p.byNo(2)!.paidLateFee, 0);
      expect(p.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p.byNo(2)!.customerPaidAmount, 480);
    });

    test('validateSplit rejects a custom split that does not add up', () {
      expect(
        RDLedgerProjector.validateSplit(
          tx('x', 100, DateTime(2026, 1, 1), mode: PaymentSplitMode.custom, inst: 90, fee: 5),
        ),
        isNotNull,
      );
      expect(
        RDLedgerProjector.validateSplit(
          tx('x', 100, DateTime(2026, 1, 1), mode: PaymentSplitMode.custom, inst: 90, fee: 10),
        ),
        isNull,
      );
    });

    test('overpayment beyond the schedule becomes customer credit, never lost', () {
      final facts = RDLedgerFacts(
        deposit: deposit(termYears: 0, termMonths: 2),
        transactions: [tx('t1', 2500, DateTime(2026, 1, 10))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 1, 10));
      expect(p.installments.every((i) => i.isInstallmentPaid), isTrue);
      expect(p.customerCredit, 500);
      expect(p.summary.customerCredit, 500);
      expect(p.summary.nextDueNo, isNull);
    });

    test('editing or deleting a transaction simply re-projects (single path)', () {
      final t1 = tx('t1', 1000, DateTime(2026, 1, 10));
      final t2 = tx('t2', 1000, DateTime(2026, 2, 10));
      final before = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [t1, t2]),
        asOf: DateTime(2026, 2, 10),
      );
      expect(before.summary.paidThroughNo, 2);

      final afterDelete = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [t2]),
        asOf: DateTime(2026, 2, 10),
      );
      expect(afterDelete.summary.paidThroughNo, 1);
      expect(afterDelete.byNo(2)!.isInstallmentPaid, isFalse);

      final afterEdit = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [t1, t2.copyWith(amount: 500)]),
        asOf: DateTime(2026, 2, 10),
      );
      expect(afterEdit.byNo(2)!.customerPaidAmount, 500);
    });

    test('transactions are replayed in paidDate order regardless of list order', () {
      final late = tx('late', 1000, DateTime(2026, 3, 1));
      final early = tx('early', 1000, DateTime(2026, 1, 12));
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [late, early]),
        asOf: DateTime(2026, 3, 1),
      );
      expect(p.allocationsByTransaction['early']!.single.installmentNo, 1);
      expect(p.allocationsByTransaction['late']!.single.installmentNo, 2);
    });

    test('money arithmetic is exact for fractional installments', () {
      final facts = RDLedgerFacts(
        deposit: deposit(amount: 333.33),
        transactions: [
          tx('a', 100.10, DateTime(2026, 1, 10)),
          tx('b', 233.23, DateTime(2026, 1, 11)),
        ],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 1, 11));
      expect(p.byNo(1)!.customerPaidAmount, 333.33);
      expect(p.byNo(1)!.isInstallmentPaid, isTrue);
      expect(p.byNo(1)!.outstandingPrincipal, 0);
    });
  });

  group('RDLedgerProjector — PO deposits & waivers', () {
    test('PO deposit on a paid month settles it; on an unpaid month is a pocket advance', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 1000, DateTime(2026, 1, 10))],
        poDeposits: [po(1, DateTime(2026, 1, 12)), po(2, DateTime(2026, 2, 12))],
      );
      final now = DateTime(2026, 2, 12);
      final p = projector.project(facts, asOf: now);
      expect(p.byNo(1)!.displayStatusAt(now), RDInstallmentDisplayStatus.settled);
      expect(p.byNo(1)!.poPaidDate, DateTime(2026, 1, 12));
      expect(p.byNo(2)!.displayStatusAt(now), RDInstallmentDisplayStatus.pocketAdvanced);
      expect(p.summary.cashInHand, 0);
      expect(p.summary.pocketAdvance, 1000);
      expect(p.readyForPo, isEmpty);
    });

    test('cash in hand counts principal and fee collected but not yet deposited', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 1010, DateTime(2026, 2, 20))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 2, 20));
      expect(p.summary.cashInHand, 1010);
      expect(p.readyForPo.single.installmentNo, 1);
    });

    test('a waiver zeroes the outstanding fee and is excluded from fee allocation', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 1000, DateTime(2026, 3, 20))],
        waivers: [waiver(1)],
      );
      final now = DateTime(2026, 3, 20);
      final p = projector.project(facts, asOf: now);
      expect(p.byNo(1)!.isLateFeeWaived, isTrue);
      expect(p.byNo(1)!.outstandingLateFeeAt(now), 0);
      expect(p.byNo(1)!.isFullySettled, isTrue);
      expect(p.byNo(1)!.paidLateFee, 0);
      // #2 is still unpaid and 1 month late; nothing was allocated to its fee.
      expect(p.byNo(2)!.outstandingLateFeeAt(now), 10);
    });

    test('financial terms lock only on transactions or post-onboarding PO deposits', () {
      expect(RDLedgerFacts(deposit: deposit(initialPaid: 3)).isFinancialTermsLocked, isFalse);
      expect(
        RDLedgerFacts(deposit: deposit(initialPaid: 3), poDeposits: [po(2, DateTime(2026, 2, 1))])
            .isFinancialTermsLocked,
        isFalse,
        reason: 'baseline months are implicit',
      );
      expect(
        RDLedgerFacts(deposit: deposit(initialPaid: 3), poDeposits: [po(4, DateTime(2026, 4, 1))])
            .isFinancialTermsLocked,
        isTrue,
      );
    });

    test('facts outside the schedule are reported as warnings, not crashes', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), poDeposits: [po(99, DateTime(2026, 1, 1))]),
        asOf: DateTime(2026, 1, 1),
      );
      expect(p.warnings, hasLength(1));
    });
  });

  group('RDLedgerSummary — hub reconstruction agrees with the full projection', () {
    test('every month reconstructed from the summary equals the projected month', () {
      final facts = RDLedgerFacts(
        deposit: deposit(initialPaid: 1),
        transactions: [
          tx('a', 1500, DateTime(2026, 2, 20)),
          tx('b', 10, DateTime(2026, 4, 1), mode: PaymentSplitMode.feesOnly),
        ],
        poDeposits: [po(2, DateTime(2026, 2, 22))],
        waivers: [waiver(4)],
      );
      final now = DateTime(2026, 5, 2);
      final p = projector.project(facts, asOf: now);

      for (final inst in p.installments) {
        final rebuilt = p.summary.installmentFor(facts.deposit, inst.installmentNo!);
        expect(rebuilt.customerPaidAmount, inst.customerPaidAmount, reason: '#${inst.installmentNo}');
        expect(rebuilt.paidLateFee, inst.paidLateFee, reason: '#${inst.installmentNo}');
        expect(rebuilt.poStatus, inst.poStatus, reason: '#${inst.installmentNo}');
        expect(rebuilt.isLateFeeWaived, inst.isLateFeeWaived, reason: '#${inst.installmentNo}');
        // Fees: frozen when settled, dynamic (recomputed as of now) when not.
        expect(rebuilt.outstandingLateFeeAt(now), inst.outstandingLateFeeAt(now),
            reason: '#${inst.installmentNo}');
        expect(rebuilt.displayStatusAt(now), inst.displayStatusAt(now),
            reason: '#${inst.installmentNo}');
      }
    });

    test('priorOpenInstallments lists arrears before the selected month', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('a', 1000, DateTime(2026, 1, 10))],
      );
      final now = DateTime(2026, 4, 20);
      final p = projector.project(facts, asOf: now);
      final priors = p.summary.priorOpenInstallments(facts.deposit, 4, now);
      expect(priors.map((i) => i.installmentNo), [2, 3]);
    });

    test('summary round-trips through JSON', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('a', 1010, DateTime(2026, 2, 20))],
        poDeposits: [po(1, DateTime(2026, 2, 21))],
      );
      final s = projector.project(facts, asOf: DateTime(2026, 2, 21)).summary;
      final json = s.toJson();
      expect(json['projected_on'] ?? json['projectedOn'], isA<String>());
      final back = RDLedgerSummary.fromJson(json);
      expect(back, s.copyWith(updatedAt: back.updatedAt));
    });
  });
}
