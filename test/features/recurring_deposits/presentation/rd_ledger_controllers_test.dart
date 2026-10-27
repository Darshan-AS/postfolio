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
        splitMode: PaymentSplitMode.includeFees,
        installmentComponent: 0,
        lateFeeComponent: 0,
      ));
      expect(result, isA<Success<void, String>>());
      await _settle();

      final stored = h.ledger.transactionsOf('rd1').single;
      expect(stored.paidDate, DateTime(2026, 2, 10), reason: 'paidDate is a calendar day');

      final summary = h.ledger.summaryOf('rd1');
      expect(summary, isNotNull);
      expect(summary!.paidThroughNo, 2);
      expect(summary.cashInHand, 2000);

      final projection = await c.read(rdLedgerProjectionProvider('rd1').future);
      expect(projection.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.collectedPendingPo);
      expect(projection.byNo(3)!.displayStatusAt(_today), RDInstallmentDisplayStatus.overdue);
      expect(c.read(rDLedgerControllerProvider).isLoading, isFalse);
    });

    test('a custom split that does not balance is rejected before any write', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      final result = await h.container.read(rDLedgerControllerProvider.notifier).recordPayment((
        rdId: 'rd1',
        transactionId: null,
        amount: 1000,
        paidDate: DateTime(2026, 2, 10),
        paymentMode: RDPaymentMode.cash,
        splitMode: PaymentSplitMode.custom,
        installmentComponent: 900,
        lateFeeComponent: 50,
      ));
      expect(result, isA<Failure<void, String>>());
      expect(h.ledger.transactionsOf('rd1'), isEmpty);
    });

    test('repository failures surface as Failure and clear the busy flag', () async {
      final h = _harness(deposits: [_deposit('rd1')]);
      _keep(h.container, 'rd1');
      h.ledger.failWith = 'offline';
      final r = await h.container
          .read(rDLedgerControllerProvider.notifier)
          .depositToPo(rdId: 'rd1', installmentNos: {1});
      expect((r as Failure).error, 'offline');
      expect(h.container.read(rDLedgerControllerProvider).isLoading, isFalse);
    });

    test('depositToPo and revertPoDeposit round-trip through facts', () async {
      final h = _harness(
        deposits: [_deposit('rd1')],
        transactions: {'rd1': [_tx('rd1', 't', 1000, DateTime(2026, 1, 12))]},
      );
      _keep(h.container, 'rd1');
      final n = h.container.read(rDLedgerControllerProvider.notifier);
      await h.container.read(rdLedgerFactsProvider('rd1').future);

      expect(await n.depositToPo(rdId: 'rd1', installmentNos: {1}), isA<Success<void, String>>());
      await _settle();
      var p = await h.container.read(rdLedgerProjectionProvider('rd1').future);
      expect(p.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.settled);
      expect(h.ledger.poDepositsOf('rd1').single.depositedOn, DateTime(2026, 4, 20));

      expect(await n.revertPoDeposit(rdId: 'rd1', installmentNos: {1}), isA<Success<void, String>>());
      await _settle();
      p = await h.container.read(rdLedgerProjectionProvider('rd1').future);
      expect(p.byNo(1)!.displayStatusAt(_today), RDInstallmentDisplayStatus.collectedPendingPo);
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
      expect(rd1.installment.isInstallmentPaid, isTrue);
      expect(rd1.priorOverdueCount, 0);

      final rd2 = items.firstWhere((i) => i.deposit.id == 'rd2');
      expect(rd2.installment.isInstallmentPaid, isFalse);
      // #1..#3 are unpaid and overdue as of 20 Apr.
      expect(rd2.priorOverdueCount, 3);
      expect(rd2.priorOverdueAmount, greaterThan(3000));
      expect(await c.read(rdIdsMissingSummaryProvider.future), isEmpty);
    });

    test('KPI partition and agent float derive from the same rows', () async {
      final h = _harness(
        deposits: [_deposit('rd1'), _deposit('rd2', customer: 'c2')],
        transactions: {'rd1': [_tx('rd1', 't', 4000, DateTime(2026, 1, 12))]},
        poDeposits: {'rd1': [RDPoDeposit(rdId: 'rd1', installmentNo: 1, depositedOn: DateTime(2026, 1, 13))]},
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
      expect(float.undepositedCashCount, 1);
      expect(float.undepositedCashAmount, 3000, reason: '#2,#3,#4 collected; #1 deposited');
      expect(float.pocketAdvancesCount, 0);
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
      expect(batch.totalAmount, 2000);
      expect(batch.collectedCount, 1);
      expect(batch.fromPocketCount, 1);
      expect(batch.fromPocketAmount, 1000);

      final r = await c.read(rDMonthlyOperationsActionsProvider.notifier).depositSelectedToPo();
      expect(r, isA<Success<void, String>>());
      expect(c.read(rDHubSelectionProvider).isSelectionMode, isFalse);
      expect(h.ledger.poDepositsOf('rd1').map((d) => d.installmentNo), [4]);
      expect(h.ledger.poDepositsOf('rd2').map((d) => d.installmentNo), [4]);
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

    test('prepareLogPayment pre-fills arrears + fee from the projection', () async {
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
      expect(prepared.splitMode, PaymentSplitMode.includeFees);
      expect(prepared.schedule, hasLength(12));
    });
  });
}
