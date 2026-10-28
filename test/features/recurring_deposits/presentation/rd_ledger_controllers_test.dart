import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';

// ---------------------------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------------------------

final _today = DateTime(2026, 4, 20, 10, 30); // wall-clock time on purpose

RecurringDeposit _deposit(String id, {DateTime? start, String customer = 'c1', int initialPaid = 0}) =>
    RecurringDeposit(
      id: id,
      customerId: customer,
      customerName: 'Customer $customer',
      schemeType: RecurringSchemeType.recurringDeposit,
      status: DepositStatus.active,
      installmentAmount: 1000,
      interestRate: 6.7,
      termYears: 1,
      termMonths: 0,
      startDate: start ?? DateTime(2026, 1, 10),
      initialPaidInstallments: initialPaid,
    );

RDTransaction _tx(String rdId, String id, double amount, DateTime on) => RDTransaction(
      id: id,
      rdId: rdId,
      paidDate: on,
      amount: amount,
      paymentMode: RDPaymentMode.cash,
    );

({ProviderContainer container, FakeRDLedgerRepository ledger, FakeRecurringDepositRepository deposits})
    _harness({
  required List<RecurringDeposit> deposits,
  Map<String, List<RDTransaction>>? transactions,
  Map<String, List<RDPoDeposit>>? poDeposits,
}) {
  final ledger = FakeRDLedgerRepository(transactions: transactions, poDeposits: poDeposits);
  final depositRepo = FakeRecurringDepositRepository(deposits: deposits);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      rdLedgerRepositoryProvider.overrideWithValue(ledger),
      recurringDepositRepositoryProvider.overrideWithValue(depositRepo),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(ledger.dispose);
  addTearDown(depositRepo.dispose);
  return (container: container, ledger: ledger, deposits: depositRepo);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

/// Riverpod 3 disposes unlistened autoDispose providers between reads; pin the ones a test
/// depends on for the duration of the test (mirrors a mounted widget).
void _keep(ProviderContainer c, String rdId) {
  c.listen(rdLedgerFactsProvider(rdId), (_, _) {});
  c.listen(rdLedgerProjectionProvider(rdId), (_, _) {});
  c.listen(rdIsFinancialTermsLockedProvider(rdId), (_, _) {});
}

void _keepHub(ProviderContainer c) {
  c.listen(monthlyOperationItemsProvider, (_, _) {});
  c.listen(filteredMonthlyOperationsProvider, (_, _) {});
  c.listen(monthlyOperationsKpiProvider, (_, _) {});
  c.listen(globalAgentFloatProvider, (_, _) {});
  c.listen(batchSelectionSummaryProvider, (_, _) {});
  c.listen(rdIdsMissingSummaryProvider, (_, _) {});
  c.listen(rDHubSelectionProvider, (_, _) {});
  c.listen(rDHubFiltersProvider, (_, _) {});
}

void main() {
  group('RDLedgerController', () {
    test('recordPayment writes the fact and refreshes the hub summary', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      final c = h.container;
      _keep(c, 'rd1');
      // Warm the facts provider so the summary refresh has a base to apply to.
      await c.read(rdLedgerFactsProvider('rd1').future);

      final result = await c.read(rDLedgerControllerProvider.notifier).recordPayment((
        rdId: 'rd1',
        transactionId: null,
        amount: 2000,
        paidDate: DateTime(2026, 2, 10, 15, 45),
        paymentMode: RDPaymentMode.upi,
      ));
      expect(result, isA<Success<void, String>>());
      await _settle();

      final stored = h.ledger.transactionsOf('rd1').single;
      expect(stored.paidDate, DateTime(2026, 2, 10), reason: 'paidDate is a calendar day');

      final summary = h.ledger.summaryOf('rd1');
      expect(summary, isNotNull);
      // 10 Feb: #1 (due 15 Jan) is 1 month late → ₹1,010; #2 (due 15 Feb) on time → ₹1,000 → ₹10 short.
      expect(summary!.paidThroughNo, 1);
      expect(summary.cashInHandDigital, 2000);
      expect(summary.cashInHandCash, 0);

      final projection = await c.read(rdLedgerProjectionProvider('rd1').future);
      expect(projection.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.collectedPendingPo);
      expect(projection.byNo(2)!.displayStatusAt(_today), RDInstallmentDisplayStatus.partiallyPaid);
      expect(projection.byNo(3)!.displayStatusAt(_today), RDInstallmentDisplayStatus.overdue);
      expect(c.read(rDLedgerControllerProvider).isLoading, isFalse);
    });

    test('a non-positive amount is rejected before any write', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      final result = await h.container.read(rDLedgerControllerProvider.notifier).recordPayment((
        rdId: 'rd1',
        transactionId: null,
        amount: 0,
        paidDate: DateTime(2026, 2, 10),
        paymentMode: RDPaymentMode.cash,
      ));
      expect(result, isA<Failure<void, String>>());
      expect(h.ledger.transactionsOf('rd1'), isEmpty);
    });

    test('repository failures surface as Failure and clear the busy flag', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      h.ledger.failWith = 'offline';
      await h.container.read(rdLedgerFactsProvider('rd1').future);
      final r = await h.container
          .read(rDLedgerControllerProvider.notifier)
          .depositNextToPo(rdId: 'rd1', count: 1);
      expect((r as Failure).error, 'offline');
      expect(h.container.read(rDLedgerControllerProvider).isLoading, isFalse);
    });

    test('depositNextToPo quotes the counter amount and undoLatest reverts it', () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't', 1000, DateTime(2026, 1, 12))]},
      );
      _keep(h.container, 'rd1');
      final n = h.container.read(rDLedgerControllerProvider.notifier);
      await h.container.read(rdLedgerFactsProvider('rd1').future);

      // Deposit the next 2 months on 20 Apr: #1 paid on time (fee at PO: 3 months late = 30),
      // #2 unpaid (fronted; 2 months late = 20).
      expect(await n.depositNextToPo(rdId: 'rd1', count: 2), isA<Success<void, String>>());
      await _settle();
      final event = h.ledger.poDepositsOf('rd1').single;
      expect(event.depositedOn, DateTime(2026, 4, 20));
      expect(event.installmentCount, 2);
      expect(event.feePaid, 50);
      expect(event.amount, 2050);

      var p = await h.container.read(rdLedgerProjectionProvider('rd1').future);
      expect(p.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.settled);
      expect(p.byNo(1)!.agentDelayCost, 30, reason: 'customer paid on time; agent deposited late');
      expect(p.byNo(2)!.displayStatusAt(_today), RDInstallmentDisplayStatus.frontedByAgent);
      expect(p.summary.receivable, 1020);

      expect(await n.undoLatestPoDeposit('rd1'), isA<Success<void, String>>());
      await _settle();
      p = await h.container.read(rdLedgerProjectionProvider('rd1').future);
      expect(p.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.collectedPendingPo);
      expect(h.ledger.poDepositsOf('rd1'), isEmpty);
      expect(await n.undoLatestPoDeposit('rd1'), isA<Failure<void, String>>());
    });

    test('financial terms lock follows facts', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      expect(await h.container.read(rdIsFinancialTermsLockedProvider('rd1').future), isFalse);
      await h.ledger.addTransaction(_tx('rd1', 't', 1000, DateTime(2026, 1, 12)));
      await _settle();
      expect(await h.container.read(rdIsFinancialTermsLockedProvider('rd1').future), isTrue);
    });
  });

  group('Monthly Hub providers', () {
    test('rows come from summaries; RDs without a summary are flagged for backfill', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2'), _deposit('closed')],
        transactions: {'rd1': [_tx('rd1', 't', 4000, DateTime(2026, 1, 12))]},
      );
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));

      // No summaries yet: everything is pristine and all three are "missing".
      var items = await c.read(monthlyOperationItemsProvider.future);
      expect(items, hasLength(3));
      expect(await c.read(rdIdsMissingSummaryProvider.future), hasLength(3));

      // Backfill builds summaries from facts; rd1 now shows April (#4) paid and arrears none.
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      items = await c.read(monthlyOperationItemsProvider.future);
      final rd1 = items.firstWhere((i) => i.deposit.id == 'rd1');
      expect(rd1.installment.installmentNo, 4);
      expect(rd1.installment.isCustomerSettled, isTrue);
      expect(rd1.priorOverdueCount, 0);
      expect(rd1.readyForPoCount, 4);

      final rd2 = items.firstWhere((i) => i.deposit.id == 'rd2');
      expect(rd2.installment.isCustomerSettled, isFalse);
      // #1..#3 are unpaid and overdue as of 20 Apr.
      expect(rd2.priorOverdueCount, 3);
      expect(rd2.priorOverdueAmount, greaterThan(3000));
      expect(await c.read(rdIdsMissingSummaryProvider.future), isEmpty);
    });

    test('KPI partition and agent float derive from the same rows', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2')],
        transactions: {'rd1': [_tx('rd1', 't', 4000, DateTime(2026, 1, 12))]},
        poDeposits: {'rd1': [RDPoDeposit(id: 'e1', rdId: 'rd1', depositedOn: DateTime(2026, 1, 13), installmentCount: 1)]},
      );
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      await c.read(monthlyOperationItemsProvider.future);

      final kpi = c.read(monthlyOperationsKpiProvider);
      expect(kpi.totalCount, 2);
      expect(kpi.readyForPoCount, 1, reason: 'rd1 #4 collected, not deposited');
      expect(kpi.toCollectCount, 1, reason: 'rd2 #4 unpaid');
      expect(kpi.overdueCount, 1);
      expect(kpi.priorArrearsAccountsCount, 1);

      final float = c.read(globalAgentFloatProvider);
      expect(float.cashInHandAccounts, 1);
      expect(float.cashInHandCash, 3000, reason: '#2,#3,#4 collected; #1 deposited');
      expect(float.receivableAccounts, 0);
      expect(float.arrearsAccounts, 1, reason: 'rd2 has 4 unpaid past-due months');
    });

    test('selection unions and only exits via clear; batch summary splits collected vs pocket', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2')],
        transactions: {'rd1': [_tx('rd1', 't', 4000, DateTime(2026, 1, 12))]},
      );
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      final items = await c.read(monthlyOperationItemsProvider.future);
      final ids = items.map((i) => i.installment.id).toList();

      final sel = c.read(rDHubSelectionProvider.notifier);
      sel.toggle(ids[0]);
      sel.selectAll([ids[1]]);
      expect(c.read(rDHubSelectionProvider).count, 2, reason: 'selectAll is a union');
      sel.toggle(ids[0]);
      sel.toggle(ids[1]);
      expect(c.read(rDHubSelectionProvider).isSelectionMode, isTrue,
          reason: 'un-ticking the last row must not exit selection mode');
      sel.selectAll(ids);

      final batch = c.read(batchSelectionSummaryProvider);
      expect(batch.count, 2);
      expect(batch.depositable.map((i) => i.deposit.id), ['rd1'], reason: 'rd2 has nothing collected');
      expect(batch.readyInstallments, 4);
    });

    test('PO visit planner quotes the counter amount, groups cash lots, records one batch and undoes it', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2')],
        transactions: {
          'rd1': [_tx('rd1', 't', 4000, DateTime(2026, 1, 12))],
          'rd2': [
            RDTransaction(id: 'u', rdId: 'rd2', paidDate: DateTime(2026, 1, 12), amount: 1000, paymentMode: RDPaymentMode.upi),
          ],
        },
      );
      final c = h.container;
      _keepHub(c);
      c.listen(rDPoVisitPlannerProvider, (_, _) {});
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      await c.read(monthlyOperationItemsProvider.future);

      final planner = c.read(rDPoVisitPlannerProvider.notifier);
      planner.start();
      var plan = c.read(rDPoVisitPlannerProvider);
      expect(plan.lines.map((l) => l.rdId), ['rd1', 'rd2']);
      expect(plan.accountCount, 2);
      expect(plan.installmentCount, 5);
      // rd1: #1..#4 paid on time; depositing on 20 Apr → fees 30+20+10+10 = 70 → 4070 (all cash).
      // rd2: #1 paid on time (UPI); deposited 20 Apr → fee 30 → 1030 (digital).
      expect(plan.totalAmount, 5100);
      expect(plan.totalFee, 100);
      expect(plan.totalCash, 4070);
      expect(plan.totalDigital, 1030);
      expect(plan.totalFromPocket, 0);
      expect(plan.cashLots.single.cashAmount, 4070);

      // Front one extra month for rd2 (#2, due 15 Feb, 2 months late → 20) from pocket.
      planner.setFronted('rd2', 1);
      plan = c.read(rDPoVisitPlannerProvider);
      final rd2 = plan.lines.firstWhere((l) => l.rdId == 'rd2');
      expect(rd2.count, 2);
      expect(rd2.fromPocket, 1020);
      expect(plan.totalFromPocket, 1020);

      // Excluding an account removes it from the visit.
      planner.toggleIncluded('rd1');
      expect(c.read(rDPoVisitPlannerProvider).accountCount, 1);
      planner.toggleIncluded('rd1');

      final r = await planner.record();
      expect(r, isA<Success<String, String>>());
      final batchId = (r as Success<String, String>).value;
      expect(h.ledger.poDepositsOf('rd1').single.batchId, batchId);
      expect(h.ledger.poDepositsOf('rd1').single.installmentCount, 4);
      expect(h.ledger.poDepositsOf('rd1').single.amount, 4070);
      expect(h.ledger.poDepositsOf('rd2').single.installmentCount, 2);

      expect(await planner.undoVisit(batchId), isA<Success<void, String>>());
      expect(h.ledger.poDepositsOf('rd1'), isEmpty);
      expect(h.ledger.poDepositsOf('rd2'), isEmpty);
    });

    test('filters: search by name, status, and due window; month change clears selection', () async {
      final h = _harness(deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2', start: DateTime(2026, 1, 20))]);
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(monthlyOperationItemsProvider.future);

      final f = c.read(rDHubFiltersProvider.notifier);
      f.setSearchQuery('c2');
      expect((await c.read(filteredMonthlyOperationsProvider.future)).single.deposit.id, 'rd2');
      f.clear();
      f.toggleDueWindow(RDDueWindowFilter.secondHalf);
      expect((await c.read(filteredMonthlyOperationsProvider.future)).single.deposit.id, 'rd2',
          reason: 'start on the 20th → due at end of month');
      f.clear();
      f.setStatus(RDMonthlyFilter.settled);
      expect(await c.read(filteredMonthlyOperationsProvider.future), isEmpty);

      c.read(rDHubSelectionProvider.notifier).toggle('x');
      c.read(rDHubMonthProvider.notifier).nextMonth();
      expect(c.read(rDHubSelectionProvider).count, 0);
      expect(c.read(rDHubMonthProvider), DateTime(2026, 5, 1));
    });

    test('prepareLogPayment pre-fills everything the customer owes today', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      final item = (await c.read(monthlyOperationItemsProvider.future)).single;
      final r = await c.read(rDMonthlyOperationsActionsProvider.notifier).prepareLogPayment(item);
      final prepared = (r as Success).value;
      // #1 (3 months late: 30), #2 (2: 20), #3 (1: 10) + #4 (1: 10, due 15 Apr, now 20 Apr) = 4000 + 70
      expect(prepared.initialAmount, 4070);
      expect(prepared.schedule, hasLength(12));
    });

    test('depositNextToPo fronts through a month; absorbRemainingFee closes a fee-only gap', () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't', 1000, DateTime(2026, 2, 20))]},
      );
      final c = h.container;
      _keepHub(c);
      _keep(c, 'rd1');
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 1, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      var item = (await c.read(monthlyOperationItemsProvider.future)).single;
      // #1: due 1010 as of 20 Apr?? no — customer fee is dynamic until settled: 3 months late → 30 → owes 30.
      // Customer paid ₹1,000 on 20 Feb; still open, so the fee keeps accruing: 3 months → owes ₹30 today.
      expect(item.installment.isPartiallyPaid, isTrue);
      expect(item.installment.outstandingAmount, 30);

      final actions = c.read(rDMonthlyOperationsActionsProvider.notifier);
      expect(await actions.absorbRemainingFee(item), isA<Success<void, String>>());
      await _settle();
      c.invalidate(monthlyOperationItemsProvider);
      item = (await c.read(monthlyOperationItemsProvider.future)).single;
      // Absorbing the fee lets the 20 Feb payment settle the month *as of 20 Feb* (1 month late),
      // so only ₹10 of fee ever existed for the customer — the projector caps the absorption there.
      expect(item.installment.isCustomerSettled, isTrue);
      expect(item.installment.lateFee, 10);
      expect(item.installment.absorbedFee, 10);
      expect(item.readyForPoCount, 1);

      // Front through #3 from pocket (deposits #1 ready + #2, #3 unpaid) via the deposit sheet path.
      expect(
        await c.read(rDLedgerControllerProvider.notifier).depositNextToPo(rdId: 'rd1', count: 3),
        isA<Success<void, String>>(),
      );
      await _settle();
      final event = h.ledger.poDepositsOf('rd1').single;
      expect(event.installmentCount, 3);
      final p = await c.read(rdLedgerProjectionProvider('rd1').future);
      expect(p.summary.depositedThroughNo, 3);
      expect(p.byNo(2)!.isFrontedByAgent, isTrue);
      expect(p.summary.receivable, p.byNo(2)!.outstandingAmount + p.byNo(3)!.outstandingAmount);
    });
  });
}
