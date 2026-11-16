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
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
  bool retryFailedProviders = true,
}) {
  final ledger = FakeRDLedgerRepository(transactions: transactions, poDeposits: poDeposits);
  final depositRepo = FakeRecurringDepositRepository(deposits: deposits);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      rdLedgerRepositoryProvider.overrideWithValue(ledger),
      recurringDepositRepositoryProvider.overrideWithValue(depositRepo),
    ],
    // Riverpod retries a failed provider with backoff for ~38s before `.future` rejects.
    // Tests that exercise read failures turn that off to reach the end state at once.
    retry: retryFailedProviders ? null : (_, _) => null,
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

    test('a PO visit cannot be dated before the last recorded visit', () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't', 3000, DateTime(2026, 1, 12))]},
        poDeposits: {'rd1': [RDPoDeposit(id: 'e1', rdId: 'rd1', depositedOn: DateTime(2026, 3, 10), installmentCount: 1)]},
      );
      _keep(h.container, 'rd1');
      final n = h.container.read(rDLedgerControllerProvider.notifier);
      final back = await n.depositNextToPo(rdId: 'rd1', count: 1, depositedOn: DateTime(2026, 2, 1));
      expect(back, isA<Failure<void, String>>());
      expect(h.ledger.poDepositsOf('rd1'), hasLength(1));
      final same = await n.depositNextToPo(rdId: 'rd1', count: 1, depositedOn: DateTime(2026, 3, 10));
      expect(same, isA<Success<void, String>>(), reason: 'same day as the last visit is fine');
    });

    test('a deposit re-sent under the same id after a lost response is stored once and reported as saved',
        () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't', 3000, DateTime(2026, 1, 12))]},
      );
      final n = h.container.read(rDLedgerControllerProvider.notifier);
      h.ledger.failApplyAfterCommitOnce = 'response lost';

      final first = await n.depositNextToPo(rdId: 'rd1', count: 2, eventId: 'attempt-1');
      expect(first, isA<Failure<RDPoDeposit, String>>());
      expect(h.ledger.poDepositsOf('rd1'), hasLength(1), reason: 'the write itself went through');

      // By the time of the retry the sheet has refreshed and may ask for something else.
      final retry = await n.depositNextToPo(rdId: 'rd1', count: 1, eventId: 'attempt-1');

      final reported = (retry as Success<RDPoDeposit, String>).value;
      expect(reported.installmentCount, 2, reason: 'the caller is told what is actually stored');
      expect(h.ledger.poDepositsOf('rd1'), hasLength(1), reason: 'the retry must not deposit month 3');
      expect(h.ledger.summaryOf('rd1')!.depositedThroughNo, 2);

      final another = await n.depositNextToPo(rdId: 'rd1', count: 1, eventId: 'attempt-2');
      expect(another, isA<Success<RDPoDeposit, String>>());
      expect(h.ledger.poDepositsOf('rd1'), hasLength(2), reason: 'a new id is a new deposit');
    });

    test('recordPayment with cold rdLedgerFactsProvider does not double-count hub summary', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      final c = h.container;
      // Intentionally do NOT call _keep(c, 'rd1') or read rdLedgerFactsProvider beforehand —
      // mirrors collecting a payment from the Monthly Hub when detail screen was never opened.
      final result = await c.read(rDLedgerControllerProvider.notifier).recordPayment((
        rdId: 'rd1',
        transactionId: null,
        amount: 1000,
        paidDate: DateTime(2026, 1, 12),
        paymentMode: RDPaymentMode.cash,
      ));
      expect(result, isA<Success<void, String>>());

      final summary = h.ledger.summaryOf('rd1');
      expect(summary, isNotNull);
      expect(summary!.paidThroughNo, 1);
      expect(summary.cashInHandCash, 1000, reason: 'must be 1x 1000, never 2x 2000');
    });

    test('sequential recordPayment + absorbFee preserves both in summary without race', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      final n = h.container.read(rDLedgerControllerProvider.notifier);

      // Paid ₹1,000 on 10 Feb for #1 (due 15 Jan, 1 month late → ₹10 fee gap), then immediately absorb ₹10.
      expect(
        await n.recordPayment((
          rdId: 'rd1',
          transactionId: null,
          amount: 1000,
          paidDate: DateTime(2026, 2, 10),
          paymentMode: RDPaymentMode.cash,
        )),
        isA<Success<void, String>>(),
      );
      expect(
        await n.absorbFee(rdId: 'rd1', installmentNo: 1, amount: 10),
        isA<Success<void, String>>(),
      );

      final summary = h.ledger.summaryOf('rd1')!;
      expect(summary.paidThroughNo, 1);
      expect(summary.absorbedTotal, 10);
      expect(summary.cashInHandCash, 1000);
    });

    test('undoBatch rejects out-of-order batch undo and refreshes only touched RDs', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2'), _deposit('rd3', customer: 'c3')],
        transactions: {
          'rd1': [_tx('rd1', 't1', 1000, DateTime(2026, 1, 12))],
          'rd2': [_tx('rd2', 't2', 2000, DateTime(2026, 1, 12))],
        },
      );
      final n = h.container.read(rDLedgerControllerProvider.notifier);
      await n.rebuildSummary('rd3');
      final untouchedSummaryBefore = h.ledger.summaryOf('rd3');

      const batchId = 'batch-visit-1';
      expect(
        await n.depositNextToPo(rdId: 'rd1', count: 1, depositedOn: DateTime(2026, 3, 10), batchId: batchId),
        isA<Success<void, String>>(),
      );
      expect(
        await n.depositNextToPo(rdId: 'rd2', count: 1, depositedOn: DateTime(2026, 3, 10), batchId: batchId),
        isA<Success<void, String>>(),
      );
      // Newer standalone PO visit on rd2 makes batch-visit-1 non-latest on rd2.
      expect(
        await n.depositNextToPo(rdId: 'rd2', count: 1, depositedOn: DateTime(2026, 3, 20)),
        isA<Success<void, String>>(),
      );

      expect(await n.undoBatch(batchId), isA<Failure<void, String>>());
      expect(h.ledger.poDepositsOf('rd1'), hasLength(1));
      expect(h.ledger.poDepositsOf('rd2'), hasLength(2));

      // Undo the newer visit on rd2 first; now batch-visit-1 is latest across all its RDs.
      expect(await n.undoLatestPoDeposit('rd2'), isA<Success<void, String>>());
      expect(await n.undoBatch(batchId), isA<Success<void, String>>());
      expect(h.ledger.poDepositsOf('rd1'), isEmpty);
      expect(h.ledger.poDepositsOf('rd2'), isEmpty);
      expect(h.ledger.summaryOf('rd1')!.depositedThroughNo, 0);
      expect(h.ledger.summaryOf('rd2')!.depositedThroughNo, 0);
      expect(identical(h.ledger.summaryOf('rd3'), untouchedSummaryBefore), isTrue,
          reason: 'untouched RD summary must not be rewritten during undoBatch');
    });

    test('financial terms lock follows facts (including fee absorptions and tenure/baseline)', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      expect(await h.container.read(rdIsFinancialTermsLockedProvider('rd1').future), isFalse);
      await h.container
          .read(rDLedgerControllerProvider.notifier)
          .absorbFee(rdId: 'rd1', installmentNo: 1, amount: 10);
      await _settle();
      expect(await h.container.read(rdIsFinancialTermsLockedProvider('rd1').future), isTrue);

      final existing = _deposit('rd1', initialPaid: 2);
      expect(
        RecurringDeposit.validateUpdate(
          existing: existing,
          updated: existing.copyWith(initialPaidInstallments: 3),
          hasPayments: true,
        ),
        isA<Failure<void, String>>(),
      );
      expect(
        RecurringDeposit.validateUpdate(
          existing: existing,
          updated: existing.copyWith(termYears: 5),
          hasPayments: true,
        ),
        isA<Failure<void, String>>(),
      );
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

    test('PO visit planner supports counter fee override, preserves edits on includeUnready, and validates batches atomically', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2')],
        transactions: {
          'rd1': [_tx('rd1', 't1', 2000, DateTime(2026, 1, 10))],
        },
        // rd2 already has a PO deposit on 20 Apr, so a backdated 18 Apr batch must fail upfront!
        poDeposits: {
          'rd2': [
            RDPoDeposit(
              id: 'e-rd2',
              rdId: 'rd2',
              depositedOn: DateTime(2026, 4, 20),
              installmentCount: 1,
              feePaid: 30,
              amount: 1030,
            ),
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
      // Override counter fee on rd1 (#1 & #2 late on 20 Apr -> formula ₹50, counter waived to ₹0).
      planner.setFeeOverride('rd1', 0);
      expect(c.read(rDPoVisitPlannerProvider).totalFee, 0);
      expect(c.read(rDPoVisitPlannerProvider).totalAmount, 2000);
      expect(c.read(rDPoVisitPlannerProvider).cashLots.single.cashAmount, 2000);

      // Showing unready accounts keeps rd1's ₹0 fee override intact.
      planner.setIncludeUnready(true);
      final rd1Line = c.read(rDPoVisitPlannerProvider).lines.firstWhere((l) => l.rdId == 'rd1');
      expect(rd1Line.feeOverride, 0);
      expect(rd1Line.amount, 2000);

      // Front 1 month on rd2 and set visit date to 18 Apr (before rd2's existing 20 Apr PO visit).
      // All-or-nothing upfront validation must reject BEFORE writing rd1!
      planner.setFronted('rd2', 1);
      planner.setDate(DateTime(2026, 4, 18));
      final rejected = await planner.record();
      expect(rejected, isA<Failure<String, String>>());
      expect(h.ledger.poDepositsOf('rd1'), isEmpty, reason: 'atomic batch: rd1 not written when rd2 fails');
    });

    test('PO visit stays within the accounts it was opened for when "include unready" is toggled', () async {
      // rd1 and rd2 have collected money (ready); rd3 and rd4 have nothing collected (unready).
      final h = _harness(
        deposits: [
          _deposit('rd1'),
          _deposit('rd2', customer: 'c2'),
          _deposit('rd3', customer: 'c3'),
          _deposit('rd4', customer: 'c4'),
        ],
        transactions: {
          'rd1': [_tx('rd1', 't1', 2000, DateTime(2026, 1, 10))],
          'rd2': [_tx('rd2', 't2', 1000, DateTime(2026, 1, 10))],
        },
      );
      final c = h.container;
      _keepHub(c);
      c.listen(rDPoVisitPlannerProvider, (_, _) {});
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      final items = await c.read(monthlyOperationItemsProvider.future);
      final picked = [
        for (final i in items)
          if (i.deposit.id == 'rd1' || i.deposit.id == 'rd3') i,
      ];

      // The agent ticked rd1 (ready) and rd3 (unready) in the Hub and opened the planner.
      final planner = c.read(rDPoVisitPlannerProvider.notifier);
      planner.start(items: picked);
      List<String> lineIds() => [for (final l in c.read(rDPoVisitPlannerProvider).lines) l.rdId];
      expect(lineIds(), ['rd1'], reason: 'only the ready account of the selection is listed by default');

      planner.setIncludeUnready(true);
      expect(lineIds(), ['rd1', 'rd3'],
          reason: 'unready accounts come from the selection, never from the rest of the Hub');
      expect(c.read(rDPoVisitPlannerProvider).includeUnready, isTrue);

      planner.setIncludeUnready(false);
      expect(lineIds(), ['rd1'], reason: 'toggling back must not leave rd2 (never selected) in the visit');

      // An unready account the agent chose to front stays in the visit when the rest are hidden.
      planner.setIncludeUnready(true);
      planner.setFronted('rd3', 1);
      planner.setIncludeUnready(false);
      expect(lineIds(), ['rd1', 'rd3'], reason: 'hiding unready accounts must not drop a fronted line');

      final r = await planner.record();
      expect(r, isA<Success<String, String>>());
      expect(h.ledger.poDepositsOf('rd1'), hasLength(1));
      expect(h.ledger.poDepositsOf('rd3').single.installmentCount, 1);
      expect(h.ledger.poDepositsOf('rd2'), isEmpty, reason: 'rd2 was ready but never selected');
      expect(h.ledger.poDepositsOf('rd4'), isEmpty, reason: 'rd4 was never selected');

      // Opened from the Hub header (no selection) the scope is every account in the Hub.
      planner.start();
      planner.setIncludeUnready(true);
      expect(lineIds().toSet(), {'rd1', 'rd2', 'rd3', 'rd4'});
    });

    test('future-month Hub surfaces genuine past-due arrears while keeping healthy accounts calm', () async {
      // now is 20 Apr 2026 (_today).
      // rdArrears: unpaid since Jan (#1 due 15 Jan, #2 due 15 Feb, #3 due 15 Mar, #4 due 15 Apr — all 4 past due!).
      // rdHealthy: opened 25 Jan (due EOM!), paid #1..#3 (Jan..Mar); #4 (Apr) is due 30 Apr (NOT yet past due on 20 Apr!).
      final rdArrears = _deposit('rd-arrears');
      final rdHealthy = _deposit('rd-healthy', start: DateTime(2026, 1, 25));
      final h = _harness(
        deposits: [rdArrears, rdHealthy],
        transactions: {
          'rd-healthy': [_tx('rd-healthy', 't-ok', 3000, DateTime(2026, 1, 26))],
        },
      );
      final c = h.container;
      _keepHub(c);
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 5, 1)); // Future month: May 2026
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();

      final items = await c.read(monthlyOperationItemsProvider.future);
      final arrearsItem = items.firstWhere((i) => i.deposit.id == 'rd-arrears');
      final healthyItem = items.firstWhere((i) => i.deposit.id == 'rd-healthy');

      expect(arrearsItem.priorOverdueCount, 4, reason: 'Jan..Apr are genuinely past due on 20 Apr');
      expect(arrearsItem.hasPriorArrears, isTrue);
      expect(healthyItem.priorOverdueCount, 0, reason: 'Apr due 30 Apr is not overdue on 20 Apr');
      expect(healthyItem.hasOverdueDebt(_today), isFalse);
    });

    test('RecurringDepositsController enforces financial-terms lock in Dart; a payment and its summary are stored together or not at all', () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't1', 1000, DateTime(2026, 1, 10))]},
      );
      // Intentionally leave h.deposits.hasLedgerActivity = (_) => false AND keep
      // recurringDepositsControllerProvider cold/unlistened (like editing from a deep link).
      final c = h.container;

      final lockedEdit = await c.read(recurringDepositsControllerProvider.notifier).saveRecurringDeposit(
        id: 'rd1',
        installmentAmount: '2000', // Attempt to change financial term while locked!
        customerId: 'cust-1',
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2026, 1, 10),
      );
      expect(lockedEdit, isA<Failure<void, String>>());

      // The summary cannot be stored: the payment must not be stored on its own, or the
      // Monthly Hub would keep showing the customer as owing money already collected.
      h.ledger.failSummaryWith = 'summary rejected';
      final ledger = c.read(rDLedgerControllerProvider.notifier);
      RDPaymentDraft payment() => (
            rdId: 'rd1',
            transactionId: 'pay-2',
            amount: 1000.0,
            paidDate: DateTime(2026, 2, 10),
            paymentMode: RDPaymentMode.cash,
          );
      expect(await ledger.recordPayment(payment()), isA<Failure<void, String>>());
      expect(h.ledger.transactionsOf('rd1').map((t) => t.id), ['t1'],
          reason: 'nothing from the failed write is stored');
      expect(h.ledger.summaryOf('rd1'), isNull);
      expect(c.read(rDLedgerControllerProvider).isLoading, isFalse);

      // The same payment sent again once the server accepts it is stored exactly once.
      h.ledger.failSummaryWith = null;
      expect(await ledger.recordPayment(payment()), isA<Success<void, String>>());
      expect(await ledger.recordPayment(payment()), isA<Success<void, String>>());
      expect(h.ledger.transactionsOf('rd1').map((t) => t.id), ['t1', 'pay-2']);
      expect(h.ledger.summaryOf('rd1')!.paidThroughNo, 2);
    });
  });

  group('Financial-terms lock on edit', () {
    // Five-year accounts (the only tenure `RecurringDeposit.create` accepts for an RD).
    // rd1 has a recorded payment (locked); rd2 has no ledger activity.
    ({
      ProviderContainer c,
      FakeRDLedgerRepository ledger,
      FakeRecurringDepositRepository deposits,
    }) harness() {
      final h = _harness(
        deposits: [
          _deposit('rd1').copyWith(termYears: 5),
          _deposit('rd2', customer: 'c2').copyWith(termYears: 5),
        ],
        transactions: {'rd1': [_tx('rd1', 't1', 1000, DateTime(2026, 1, 10))]},
        retryFailedProviders: false,
      );
      return (c: h.container, ledger: h.ledger, deposits: h.deposits);
    }

    Future<Result<void, String>> save(
      ProviderContainer c,
      String id, {
      String amount = '1000',
      String? serialNo,
      String customerId = 'c1',
    }) =>
        c.read(recurringDepositsControllerProvider.notifier).saveRecurringDeposit(
              id: id,
              serialNo: serialNo,
              installmentAmount: amount,
              customerId: customerId,
              schemeType: RecurringSchemeType.recurringDeposit,
              startDate: DateTime(2026, 1, 10),
              termYears: 5,
              termMonths: 0,
              interestRate: '6.7',
            );

    RecurringDeposit stored(FakeRecurringDepositRepository repo, String id) =>
        repo.deposits.firstWhere((d) => d.id == id);

    String errorOf(Result<void, String> r) => (r as Failure<void, String>).error;

    test('a terms change is refused when the ledger cannot be checked', () async {
      final h = harness();
      h.ledger.failReadsWith = 'offline';

      final r = await save(h.c, 'rd1', amount: '2000');

      expect(r, isA<Failure<void, String>>(),
          reason: 'not knowing whether the account has history must not unlock it');
      expect(errorOf(r), t.recurringDeposits.fields.financialTermsUnverified);
      expect(stored(h.deposits, 'rd1').installmentAmount, 1000);
    });

    test('a locked account refuses a terms change and an unlocked one accepts it', () async {
      final h = harness();

      final locked = await save(h.c, 'rd1', amount: '2000');
      expect(locked, isA<Failure<void, String>>());
      expect(errorOf(locked), t.recurringDeposits.fields.financialTermsLocked);
      expect(stored(h.deposits, 'rd1').installmentAmount, 1000);

      expect(await save(h.c, 'rd2', amount: '2000', customerId: 'c2'), isA<Success<void, String>>());
      expect(stored(h.deposits, 'rd2').installmentAmount, 2000);
    });

    test('an edit that leaves the terms alone does not depend on the ledger being readable', () async {
      final h = harness();
      h.ledger.failReadsWith = 'offline';

      final r = await save(h.c, 'rd1', serialNo: '77');

      expect(r, isA<Success<void, String>>());
      expect(stored(h.deposits, 'rd1').serialNo, '77');
      expect(stored(h.deposits, 'rd1').installmentAmount, 1000);
    });

    test('editing an account that cannot be loaded is refused instead of saved blind', () async {
      final h = harness();

      final r = await save(h.c, 'no-such-account', amount: '2000');

      expect(r, isA<Failure<void, String>>());
      expect(errorOf(r), 'Recurring Deposit not found');
      expect(h.deposits.deposits.map((d) => d.id), ['rd1', 'rd2'],
          reason: 'an edit must never create a new account');
    });
  });

  group('PO visit write path', () {
    // rd1 has two collected months and rd2 one, all paid on time; the visit is on 20 Apr.
    Future<
        ({
          ProviderContainer c,
          FakeRDLedgerRepository ledger,
          RDPoVisitPlanner planner,
        })> openVisit() async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2')],
        transactions: {
          'rd1': [_tx('rd1', 't1', 2000, DateTime(2026, 1, 10))],
          'rd2': [_tx('rd2', 't2', 1000, DateTime(2026, 1, 10))],
        },
        retryFailedProviders: false,
      );
      // A real round trip is long enough for unlistened fact providers to be torn down.
      h.ledger.writeLatency = const Duration(milliseconds: 30);
      final c = h.container;
      _keepHub(c);
      c.listen(rDPoVisitPlannerProvider, (_, _) {});
      c.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 4, 1));
      await c.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      await _settle();
      await c.read(monthlyOperationItemsProvider.future);
      final planner = c.read(rDPoVisitPlannerProvider.notifier)..start();
      return (c: c, ledger: h.ledger, planner: planner);
    }

    test('a saved visit is reported as saved even if nothing can be read afterwards', () async {
      final v = await openVisit();
      v.ledger.onChangeApplied = () => v.ledger.failReadsWith = 'offline';

      final r = await v.planner.record();

      expect(r, isA<Success<String, String>>(),
          reason: 'the visit and its summaries are one write; nothing is read after it');
      expect(v.ledger.poDepositsOf('rd1').single.installmentCount, 2);
      expect(v.ledger.poDepositsOf('rd2').single.installmentCount, 1);
      expect(v.ledger.summaryOf('rd1')!.depositedThroughNo, 2,
          reason: 'summaries are projected from the facts already in hand, with no further reads');
      expect(v.ledger.summaryOf('rd2')!.depositedThroughNo, 1);
    });

    test('a visit and its summaries are stored together or not at all', () async {
      final v = await openVisit();
      v.ledger.failSummaryWith = 'summary rejected';

      expect(await v.planner.record(), isA<Failure<String, String>>());
      expect(v.ledger.poDepositsOf('rd1'), isEmpty,
          reason: 'deposits must not be stored while the Hub still shows them as pending');
      expect(v.ledger.poDepositsOf('rd2'), isEmpty);

      v.ledger.failSummaryWith = null;
      expect(await v.planner.record(), isA<Success<String, String>>());
      expect(v.ledger.poDepositsOf('rd1'), hasLength(1));
      expect(v.ledger.summaryOf('rd1')!.depositedThroughNo, 2);
    });

    test('retrying a visit whose first attempt was saved but reported as failed deposits nothing twice',
        () async {
      final v = await openVisit();
      v.ledger.failApplyAfterCommitOnce = 'response lost';

      expect(await v.planner.record(), isA<Failure<String, String>>());
      final retry = await v.planner.record();

      expect(retry, isA<Success<String, String>>());
      expect(v.ledger.poDepositsOf('rd1'), hasLength(1), reason: 'the retry must not deposit months 3 and 4');
      expect(v.ledger.poDepositsOf('rd2'), hasLength(1));
      expect(v.ledger.summaryOf('rd1')!.depositedThroughNo, 2);
      expect(v.ledger.summaryOf('rd2')!.depositedThroughNo, 1);
      final batchId = (retry as Success<String, String>).value;
      expect(v.ledger.poDepositsOf('rd1').single.batchId, batchId,
          reason: 'the returned id must undo the visit that was actually saved');
    });

    test('a visit is one batch read and one write, however many accounts it covers', () async {
      final v = await openVisit();
      final streamsBefore = v.ledger.streamOpenCount;
      final batchReadsBefore = v.ledger.batchFactFetchCount;
      final writesBefore = v.ledger.applyChangeCallCount;

      expect(await v.planner.record(), isA<Success<String, String>>());

      expect(v.ledger.streamOpenCount, streamsBefore, reason: 'no per-account fact streams');
      expect(v.ledger.batchFactFetchCount, batchReadsBefore + 1);
      expect(v.ledger.applyChangeCallCount, writesBefore + 1);
    });

    test('undoing a visit removes it and rewrites the summaries, or changes nothing', () async {
      final v = await openVisit();
      final batchId = (await v.planner.record() as Success<String, String>).value;

      // The visit cannot be checked while offline, so nothing is deleted.
      v.ledger.failReadsWith = 'offline';
      expect(await v.planner.undoVisit(batchId), isA<Failure<void, String>>());
      expect(v.ledger.poDepositsOf('rd1'), hasLength(1));
      expect(v.ledger.poDepositsOf('rd2'), hasLength(1));
      expect(v.ledger.summaryOf('rd1')!.depositedThroughNo, 2);

      v.ledger.failReadsWith = null;
      expect(await v.planner.undoVisit(batchId), isA<Success<void, String>>());
      expect(v.ledger.poDepositsOf('rd1'), isEmpty);
      expect(v.ledger.poDepositsOf('rd2'), isEmpty);
      expect(v.ledger.summaryOf('rd1')!.depositedThroughNo, 0);
      expect(v.ledger.summaryOf('rd2')!.depositedThroughNo, 0);

      // Undoing it again (a retry after a lost response) is a success, not an error.
      expect(await v.planner.undoVisit(batchId), isA<Success<void, String>>());
    });
  });
}
