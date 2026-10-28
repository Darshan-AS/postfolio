import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
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
// Fixtures: ₹1,000/month, opened 10 Jan 2026 (due on the 15th), 12 months.
// ---------------------------------------------------------------------------------------------

const _rdId = 'rd-1';

RecurringDeposit deposit({
  double amount = 1000.0,
  DateTime? startDate,
  int termYears = 1,
  int termMonths = 0,
  int initialPaid = 0,
  double openingReceivable = 0.0,
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
      openingReceivable: openingReceivable,
    );

RDTransaction tx(String id, double amount, DateTime on, {RDPaymentMode mode = RDPaymentMode.cash}) =>
    RDTransaction(id: id, rdId: _rdId, paidDate: on, amount: amount, paymentMode: mode);

RDPoDeposit po(String id, int count, DateTime on, {double fee = 0}) => RDPoDeposit(
      id: id,
      rdId: _rdId,
      depositedOn: on,
      installmentCount: count,
      feePaid: fee,
      amount: count * 1000.0 + fee,
    );

RDFeeAbsorption absorb(int no, double amount) =>
    RDFeeAbsorption(rdId: _rdId, installmentNo: no, amount: amount, absorbedOn: DateTime(2026, 6, 1));

const projector = RDLedgerProjector.standard;

void main() {
  group('RDLedgerRules', () {
    const rules = RDLedgerRules.standard;

    test('paying on the due date is not in default, even with a time-of-day', () {
      final due = DateTime(2026, 9, 15);
      expect(rules.isInDefault(due, DateTime(2026, 9, 15, 10, 30)), isFalse);
      expect(rules.isInDefault(due, DateTime(2026, 9, 16, 0, 0, 1)), isTrue);
      expect(rules.defaultedMonths(due, DateTime(2026, 9, 16)), 1);
      expect(rules.defaultedMonths(due, DateTime(2026, 11, 20)), 2);
    });

    test('default fee is exact in paise and rounded up to whole rupees', () {
      expect(rules.defaultFeeFor(1000, 1), 10);
      expect(rules.defaultFeeFor(110, 10), 11, reason: 'no floating-point drift');
      expect(rules.defaultFeeFor(150, 1), 2, reason: '₹1 per ₹100 or part thereof');
      expect(rules.defaultFeeFor(1000, 0), 0);
    });

    test('due date follows the 15th / end-of-month rule', () {
      expect(rules.dueDateFor(DateTime(2026, 1, 10), DateTime(2026, 2, 10)), DateTime(2026, 2, 15));
      expect(rules.dueDateFor(DateTime(2026, 1, 20), DateTime(2026, 2, 20)), DateTime(2026, 2, 28));
      expect(rules.dueDateFor(DateTime(2028, 1, 31), DateTime(2028, 2, 29)), DateTime(2028, 2, 29));
    });
  });

  group('RDScheduleFactory', () {
    test('baseline marks opening months deposited and the rest pristine', () {
      final s = RDScheduleFactory.baselineSchedule(deposit(initialPaid: 2));
      expect(s, hasLength(12));
      expect(s[0].isOpeningBaseline, isTrue);
      expect(s[0].isPoDeposited, isTrue);
      expect(s[2].isOpeningBaseline, isFalse);
      expect(s[2].customerPaidAmount, 0);
      expect(s[2].installmentNo, 3);
    });
  });

  group('Customer side — sequential due amounts', () {
    test('no facts yields a pristine schedule and summary', () {
      final p = projector.project(RDLedgerFacts(deposit: deposit()), asOf: DateTime(2026, 1, 1));
      expect(p.installments, hasLength(12));
      expect(p.summary.paidThroughNo, 0);
      expect(p.summary.depositedThroughNo, 0);
      expect(p.summary.nextDueNo, 1);
      expect(p.summary.openItems, isEmpty);
      expect(p.poReadiness.hasReady, isFalse);
    });

    test('whole months fill in order; a shortfall is a partial on the earliest open month', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(initialPaid: 2), transactions: [tx('t1', 2500, DateTime(2026, 3, 10))]),
        asOf: DateTime(2026, 3, 10),
      );
      expect(p.byNo(3)!.isCustomerSettled, isTrue);
      expect(p.byNo(4)!.isCustomerSettled, isTrue);
      expect(p.byNo(5)!.customerPaidAmount, 500);
      expect(p.byNo(5)!.displayStatusAt(DateTime(2026, 3, 10)), RDInstallmentDisplayStatus.partiallyPaid);
      expect(p.summary.paidThroughNo, 4);
      expect(p.summary.nextDueNo, 5);
      expect(p.allocationsByTransaction['t1']!.map((s) => (s.installmentNo, s.amount)),
          [(3, 1000.0), (4, 1000.0), (5, 500.0)]);
    });

    test('several small payments in a month accumulate on the same month', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [
          tx('a', 300, DateTime(2026, 1, 3)),
          tx('b', 300, DateTime(2026, 1, 8)),
          tx('c', 400, DateTime(2026, 1, 14)),
        ]),
        asOf: DateTime(2026, 1, 14),
      );
      expect(p.byNo(1)!.isCustomerSettled, isTrue);
      expect(p.byNo(1)!.lateFee, 0, reason: 'completed on time');
      expect(p.summary.paidThroughNo, 1);
    });

    test('payment on the due date carries no fee', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, DateTime(2026, 1, 15, 10, 30))]),
        asOf: DateTime(2026, 1, 15, 18),
      );
      expect(p.byNo(1)!.isCustomerSettled, isTrue);
      expect(p.byNo(1)!.lateFee, 0);
    });

    test('fee is part of the due amount: ₹1,000 against a 1-month-late month leaves ₹10 open', () {
      final now = DateTime(2026, 2, 20);
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, now)]),
        asOf: now,
      );
      expect(p.byNo(1)!.dueAmount, 1010);
      expect(p.byNo(1)!.isCustomerSettled, isFalse);
      expect(p.byNo(1)!.outstandingAmount, 10);
      expect(p.byNo(1)!.displayStatusAt(now), RDInstallmentDisplayStatus.partiallyPaid);
      expect(p.summary.owedByCustomer, 10 + 1010, reason: '#1 fee + #2 (due 15 Feb, 1 month late)');
    });

    test('an unsettled month keeps accruing with asOf; a settled one is fixed at settlement', () {
      final partial = RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, DateTime(2026, 2, 20))]);
      expect(projector.project(partial, asOf: DateTime(2026, 2, 20)).byNo(1)!.outstandingAmount, 10);
      expect(projector.project(partial, asOf: DateTime(2026, 6, 20)).byNo(1)!.outstandingAmount, 50);

      final settled = RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1010, DateTime(2026, 2, 20))]);
      final late = projector.project(settled, asOf: DateTime(2026, 6, 20));
      expect(late.byNo(1)!.isCustomerSettled, isTrue, reason: 'customer fee fixed at 20 Feb');
      expect(late.byNo(1)!.lateFee, 10);
      expect(late.byNo(1)!.poLateFee, 50, reason: 'PO will charge 5 months if deposited today');
      expect(late.byNo(1)!.agentDelayCost, 40);
    });

    test('a month paid on time never accrues a customer fee just because the agent held the cash', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, DateTime(2026, 1, 10))]),
        asOf: DateTime(2026, 4, 20),
      );
      expect(p.byNo(1)!.isCustomerSettled, isTrue);
      expect(p.byNo(1)!.lateFee, 0);
      expect(p.byNo(1)!.poLateFee, 30);
      expect(p.summary.delayCostTotal, 0, reason: 'not yet deposited, so not yet a cost');
      expect(p.poReadiness.readyAmount, 1030);
    });

    test('overpayment beyond the schedule becomes credit, never lost', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(termYears: 0, termMonths: 2), transactions: [tx('t1', 2500, DateTime(2026, 1, 10))]),
        asOf: DateTime(2026, 1, 10),
      );
      expect(p.installments.every((i) => i.isCustomerSettled), isTrue);
      expect(p.summary.customerCredit, 500);
      expect(p.summary.nextDueNo, isNull);
      expect(p.allocationsByTransaction['t1']!.last.isCredit, isTrue);
    });

    test('opening receivable is repaid before any month is credited', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(initialPaid: 3, openingReceivable: 400), transactions: [tx('t1', 1000, DateTime(2026, 4, 10))]),
        asOf: DateTime(2026, 4, 10),
      );
      expect(p.summary.openingReceivableLeft, 0);
      expect(p.byNo(4)!.customerPaidAmount, 600);
      expect(p.allocationsByTransaction['t1']!.first.isOpeningReceivable, isTrue);
      expect(p.allocationsByTransaction['t1']!.first.amount, 400);
    });

    test('editing or deleting a transaction simply re-projects (single path)', () {
      final t1 = tx('t1', 1000, DateTime(2026, 1, 10));
      final t2 = tx('t2', 1000, DateTime(2026, 2, 10));
      final before = projector.project(RDLedgerFacts(deposit: deposit(), transactions: [t1, t2]), asOf: DateTime(2026, 2, 10));
      expect(before.summary.paidThroughNo, 2);
      final afterDelete = projector.project(RDLedgerFacts(deposit: deposit(), transactions: [t2]), asOf: DateTime(2026, 2, 10));
      // t2 (10 Feb) now lands on #1, which is 1 month late → ₹1,010 due → ₹10 short.
      expect(afterDelete.summary.paidThroughNo, 0);
      expect(afterDelete.byNo(1)!.outstandingAmount, 10);
      final afterEdit = projector.project(RDLedgerFacts(deposit: deposit(), transactions: [t1, t2.copyWith(amount: 500)]), asOf: DateTime(2026, 2, 10));
      expect(afterEdit.byNo(2)!.customerPaidAmount, 500);
    });

    test('money arithmetic is exact for fractional installments', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(amount: 333.33), transactions: [tx('a', 100.10, DateTime(2026, 1, 10)), tx('b', 233.23, DateTime(2026, 1, 11))]),
        asOf: DateTime(2026, 1, 11),
      );
      expect(p.byNo(1)!.customerPaidAmount, 333.33);
      expect(p.byNo(1)!.isCustomerSettled, isTrue);
    });
  });

  group('Post Office side — sequential events', () {
    test('an event covers the next N months in order and fixes their fee at the deposit date', () {
      final facts = RDLedgerFacts(
        deposit: deposit(),
        transactions: [tx('t1', 2020, DateTime(2026, 2, 20))],
        poDeposits: [po('e1', 2, DateTime(2026, 2, 25), fee: 20)],
      );
      final now = DateTime(2026, 7, 1);
      final p = projector.project(facts, asOf: now);
      expect(p.summary.depositedThroughNo, 2);
      expect(p.byNo(1)!.poDepositedOn, DateTime(2026, 2, 25));
      expect(p.byNo(1)!.lateFee, 10, reason: 'frozen at 25 Feb (1 month late), not re-accrued to July');
      expect(p.byNo(2)!.lateFee, 10);
      expect(p.byNo(1)!.displayStatusAt(now), RDInstallmentDisplayStatus.settled);
      expect(p.byNo(2)!.displayStatusAt(now), RDInstallmentDisplayStatus.settled);
      expect(p.byNo(3)!.displayStatusAt(now), RDInstallmentDisplayStatus.overdue);
    });

    test('depositing more than collected is a pocket advance → receivable and frontedByAgent', () {
      final now = DateTime(2026, 3, 1);
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, DateTime(2026, 1, 10))], poDeposits: [po('e1', 2, DateTime(2026, 2, 10))]),
        asOf: now,
      );
      expect(p.byNo(1)!.displayStatusAt(now), RDInstallmentDisplayStatus.settled);
      expect(p.byNo(2)!.displayStatusAt(now), RDInstallmentDisplayStatus.frontedByAgent);
      expect(p.summary.receivable, 1000, reason: '#2 deposited on time (15 Feb due, deposited 10 Feb) → no fee');
      expect(p.byNo(2)!.lateFee, 0, reason: 'customer fee fixed at the PO deposit date, not asOf');
      expect(p.summary.cashInHandCash, 0);
      expect(p.summary.owedByCustomer, 1000);
    });

    test('customer repaying a fronted month reduces the receivable, not cash in hand', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, DateTime(2026, 2, 20))], poDeposits: [po('e1', 1, DateTime(2026, 1, 12))]),
        asOf: DateTime(2026, 2, 20),
      );
      expect(p.summary.receivable, 0);
      expect(p.summary.cashInHandCash, 0);
      expect(p.byNo(1)!.isFullySettled, isTrue);
    });

    test('readiness counts contiguous collected months after the deposited pointer', () {
      final now = DateTime(2026, 4, 1);
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 3030, DateTime(2026, 3, 20))], poDeposits: [po('e1', 1, DateTime(2026, 1, 12))]),
        asOf: now,
      );
      // Customer on 20 Mar: #2 (1 month late → 10) and #3 (1 month late → 10) = 2020; 1010 left → #4 partial.
      // PO on 1 Apr would charge #2 two months (20) + #3 one month (10) = 2030; the ₹10 gap is agent delay.
      expect(p.poReadiness.readyCount, 2);
      expect(p.poReadiness.readyAmount, 2030);
      expect(p.poReadiness.readyFee, 30);
      expect(p.poReadiness.nextInstallmentNo, 2);
      expect(p.byNo(2)!.lateFee, 10, reason: 'customer fee fixed on 20 Mar');
      expect(p.byNo(2)!.poLateFee, 20, reason: 'PO estimate as of 1 Apr');
      expect(p.byNo(2)!.agentDelayCost, 10);
      // The first ₹1,000 repaid the fronted #1, so only ₹10 reached #4.
      expect(p.byNo(4)!.customerPaidAmount, 10);
      expect(p.summary.receivable, 0);
    });

    test('quoteNextDeposit matches what the counter will charge on that date', () {
      final facts = RDLedgerFacts(deposit: deposit(), poDeposits: [po('e1', 1, DateTime(2026, 1, 12))]);
      final q = projector.quoteNextDeposit(facts, count: 2, depositedOn: DateTime(2026, 3, 20));
      // #2 due 15 Feb → 1 month late; #3 due 15 Mar → 1 month late.
      expect(q.fee, 20);
      expect(q.amount, 2020);
    });

    test('events beyond the schedule are warnings, and the latest event is identifiable', () {
      final facts = RDLedgerFacts(
        deposit: deposit(termYears: 0, termMonths: 2),
        poDeposits: [po('e1', 1, DateTime(2026, 1, 12)), po('e2', 5, DateTime(2026, 2, 12))],
      );
      final p = projector.project(facts, asOf: DateTime(2026, 3, 1));
      expect(p.summary.depositedThroughNo, 2);
      expect(p.warnings, hasLength(1));
      expect(facts.latestPoDeposit!.id, 'e2');
    });
  });

  group('Absorbed fees', () {
    test('absorbing the fee lets the customer settle with the bare installment', () {
      final now = DateTime(2026, 2, 20);
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [tx('t1', 1000, now)], absorptions: [absorb(1, 10)]),
        asOf: now,
      );
      expect(p.byNo(1)!.dueAmount, 1000);
      expect(p.byNo(1)!.isCustomerSettled, isTrue);
      expect(p.byNo(1)!.lateFee, 10, reason: 'the PO still gets the fee');
      expect(p.summary.absorbedTotal, 10);
    });

    test('absorption is capped at the actual fee', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), absorptions: [absorb(1, 999)]),
        asOf: DateTime(2026, 2, 20),
      );
      expect(p.byNo(1)!.absorbedFee, 10);
    });
  });

  group('Agent float & arrears', () {
    test('cash in hand splits by payment mode and excludes fronted months', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), transactions: [
          tx('a', 1000, DateTime(2026, 1, 10)),
          tx('b', 1000, DateTime(2026, 2, 10), mode: RDPaymentMode.upi),
          tx('c', 1000, DateTime(2026, 3, 10)),
        ], poDeposits: [po('e1', 1, DateTime(2026, 1, 12))]),
        asOf: DateTime(2026, 3, 10),
      );
      expect(p.summary.cashInHandCash, 1000);
      expect(p.summary.cashInHandDigital, 1000);
      expect(p.summary.receivable, 0);
    });

    test('arrears counts unsettled past-due months, deposited or not', () {
      final p = projector.project(
        RDLedgerFacts(deposit: deposit(), poDeposits: [po('e1', 1, DateTime(2026, 1, 12))]),
        asOf: DateTime(2026, 4, 20),
      );
      // #1 fronted (unsettled), #2 #3 #4 unpaid & past due.
      expect(p.summary.arrearsCount, 4);
      expect(p.arrears.map((i) => i.installmentNo), [1, 2, 3, 4]);
    });

    test('financial terms lock on any ledger activity', () {
      expect(RDLedgerFacts(deposit: deposit(initialPaid: 3)).isFinancialTermsLocked, isFalse);
      expect(RDLedgerFacts(deposit: deposit(), poDeposits: [po('e1', 1, DateTime(2026, 1, 1))]).isFinancialTermsLocked, isTrue);
    });
  });

  group('RDLedgerSummary — hub reconstruction agrees with the full projection', () {
    test('every month reconstructed from the summary equals the projected month', () {
      final facts = RDLedgerFacts(
        deposit: deposit(initialPaid: 1, openingReceivable: 200),
        transactions: [
          tx('a', 1700, DateTime(2026, 2, 20)),
          tx('b', 500, DateTime(2026, 4, 1), mode: RDPaymentMode.upi),
        ],
        poDeposits: [po('e1', 2, DateTime(2026, 2, 22), fee: 10)],
        absorptions: [absorb(4, 10)],
      );
      final now = DateTime(2026, 5, 2);
      final p = projector.project(facts, asOf: now);

      for (final inst in p.installments) {
        final rebuilt = p.summary.installmentFor(facts.deposit, inst.installmentNo, now);
        expect(rebuilt, inst, reason: '#${inst.installmentNo}');
      }
    });

    test('priorOpenInstallments lists arrears before the selected month', () {
      final facts = RDLedgerFacts(deposit: deposit(), transactions: [tx('a', 1000, DateTime(2026, 1, 10))]);
      final now = DateTime(2026, 4, 20);
      final p = projector.project(facts, asOf: now);
      expect(p.summary.priorOpenInstallments(facts.deposit, 4, now).map((i) => i.installmentNo), [2, 3]);
    });

    test('summary round-trips through JSON', () {
      final s = projector
          .project(
            RDLedgerFacts(deposit: deposit(), transactions: [tx('a', 1010, DateTime(2026, 2, 20))], poDeposits: [po('e1', 1, DateTime(2026, 2, 21))]),
            asOf: DateTime(2026, 2, 21),
          )
          .summary;
      final back = RDLedgerSummary.fromJson(s.toJson());
      expect(back, s.copyWith(updatedAt: back.updatedAt));
    });
  });
}
