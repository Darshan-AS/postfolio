@Tags(['integration'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// End-to-end provider test against the LOCAL Supabase stack.
///
/// Self-contained: signs up a throwaway `@example.com` agent (ignored by the seed-adoption
/// trigger), creates one customer + one RD and the same ledger facts as `seed.sql`'s first
/// account, then exercises exactly what the RD tab, Monthly Hub and Detail screen read and
/// write. Cleans up by deleting the agent profile (cascades).
///
/// Run: flutter test test/supabase_rd_ledger_e2e_test.dart   (requires `supabase start`)
void main() {
  const url = 'http://127.0.0.1:54321';
  const anon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  late SupabaseClient client;
  late String agentId;
  late String rd1;
  late ProviderContainer container;

  setUpAll(() async {
    client = SupabaseClient(url, anon,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit));
    final res = await client.auth.signUp(
      email: 'testagent_e2e_${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'password123',
    );
    agentId = (res.user ?? client.auth.currentUser)!.id;
    await client.from('agent_profiles').upsert({'id': agentId, 'name': 'E2E Agent'});

    // Customer + RD: opened 15 Jan 2025 (due on the 15th), ₹5,000/month, 5 years,
    // onboarded with 12 months already at the PO → ledger starts at #13 (Jan 2026).
    final customerId = const Uuid().v4();
    final customer = (Customer.create(id: customerId, name: 'Arjun Mehta', phone: '9876543210')
        as Success<Customer, String>).value;
    await SupabaseCustomerRepository(client).createCustomer(customer);

    rd1 = const Uuid().v4();
    final rd = (RecurringDeposit.create(
      id: rd1,
      serialNo: '1',
      accountNo: '100200300',
      installmentAmount: 5000,
      customerId: customerId,
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 1, 15),
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      initialPaidInstallments: 12,
    ) as Success<RecurringDeposit, String>).value;
    expect(await SupabaseRecurringDepositRepository(client).saveRecurringDeposit(rd),
        isA<Success<void, String>>());

    final ledger = SupabaseRDLedgerRepository(client);
    RDTransaction tx(String d, double amount, RDPaymentMode mode) => RDTransaction(
        id: const Uuid().v4(), rdId: rd1, paidDate: DateTime.parse(d), amount: amount, paymentMode: mode);
    for (final t in [
      tx('2026-01-14', 5000, RDPaymentMode.cash),
      tx('2026-02-16', 5000, RDPaymentMode.upi),
      tx('2026-03-12', 5000, RDPaymentMode.cash),
      tx('2026-04-15', 5000, RDPaymentMode.cash),
      tx('2026-06-20', 5000, RDPaymentMode.cash),
      tx('2026-07-14', 5000, RDPaymentMode.upi),
      tx('2026-08-14', 5000, RDPaymentMode.cash),
      tx('2026-09-16', 100, RDPaymentMode.cash),
    ]) {
      expect(await ledger.addTransaction(t), isA<Success<void, String>>());
    }
    RDPoDeposit po(String d, double fee) => RDPoDeposit(
        id: const Uuid().v4(), rdId: rd1, depositedOn: DateTime.parse(d), installmentCount: 1,
        feePaid: fee, amount: 5000 + fee);
    for (final e in [
      po('2026-01-16', 0), po('2026-02-18', 50), po('2026-03-14', 0),
      po('2026-04-17', 50), po('2026-06-22', 50), po('2026-07-16', 50),
    ]) {
      expect(await ledger.addPoDeposit(e), isA<Success<void, String>>());
    }
    expect(
      await ledger.upsertFeeAbsorption(RDFeeAbsorption(
          rdId: rd1, installmentNo: 14, amount: 50, absorbedOn: DateTime(2026, 2, 18))),
      isA<Success<void, String>>(),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(client),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 10)),
      recurringDepositRepositoryProvider
          .overrideWithValue(SupabaseRecurringDepositRepository(client)),
      rdLedgerRepositoryProvider.overrideWithValue(SupabaseRDLedgerRepository(client)),
    ]);
    addTearDown(container.dispose);
  });

  tearDownAll(() async {
    await client.from('agent_profiles').delete().eq('id', agentId);
    await client.dispose();
  });

  test('RD tab: deposits list loads from recurring_deposit_details_view', () async {
    container.listen(filteredRecurringDepositsProvider, (_, _) {});
    final deposits = await container.read(filteredRecurringDepositsProvider.future);
    expect(deposits.map((d) => d.id), contains(rd1));
    expect(deposits.every((d) => d.customerName != null), isTrue);
  });

  test('Detail: facts stream + projection (same numbers as the seeded account)', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final p = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(p.installments, hasLength(60));
    expect(p.byNo(12)!.isOpeningBaseline, isTrue);
    expect(p.byNo(13)!.isFullySettled, isTrue);
    expect(p.byNo(14)!.absorbedFee, 50);
    expect(p.byNo(14)!.isFullySettled, isTrue);
    expect(p.summary.paidThroughNo, 18);
    expect(p.summary.depositedThroughNo, 18);
    expect(p.byNo(19)!.isPartiallyPaid, isTrue);
    expect(p.summary.arrearsCount, greaterThanOrEqualTo(3));
    expect(p.customerCredit, 0);
    expect(p.warnings, isEmpty);
  });

  test('Hub: summaries stream, backfill, rows, KPIs', () async {
    container.listen(monthlyOperationItemsProvider, (_, _) {});
    container.listen(monthlyOperationsKpiProvider, (_, _) {});
    container.listen(rdLedgerSummariesProvider, (_, _) {});
    container.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 10, 1));

    var items = await container.read(monthlyOperationItemsProvider.future);
    expect(items.map((i) => i.deposit.id), contains(rd1));

    await container.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final rows = await client.from('rd_ledger_summary').select('rd_id').eq('rd_id', rd1);
    expect(rows, hasLength(1));

    container.invalidate(monthlyOperationItemsProvider);
    items = await container.read(monthlyOperationItemsProvider.future);
    final rd1Item = items.firstWhere((i) => i.deposit.id == rd1);
    expect(rd1Item.hasSummary, isTrue);
    expect(rd1Item.installment.installmentNo, 22);
    expect(rd1Item.priorOverdueCount, 3, reason: '#19 partial, #20, #21 open');
    expect(rd1Item.readyForPoCount, 0);
    expect(container.read(monthlyOperationsKpiProvider).totalCount, greaterThanOrEqualTo(1));
  });

  test('Write path: record + delete a payment through the real tables', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final before = await container.read(rdLedgerProjectionProvider(rd1).future);
    final n = container.read(rDLedgerControllerProvider.notifier);
    final txId = const Uuid().v4();

    final r = await n.recordPayment((
      rdId: rd1,
      transactionId: txId,
      amount: 5000,
      paidDate: DateTime(2026, 10, 27, 9, 30),
      paymentMode: RDPaymentMode.cash,
    ));
    expect(r, isA<Success<void, String>>(), reason: (r as dynamic).toString());

    await Future<void>.delayed(const Duration(seconds: 1));
    final after = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(after.totalCollected, before.totalCollected + 5000);

    expect(await n.deletePayment(rdId: rd1, transactionId: txId), isA<Success<void, String>>());
  });

  test('Write path: PO event quote, insert and undo through the real tables', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final n = container.read(rDLedgerControllerProvider.notifier);
    final before = await container.read(rdLedgerProjectionProvider(rd1).future);
    final through = before.summary.depositedThroughNo;

    final r = await n.depositNextToPo(rdId: rd1, count: 1, depositedOn: DateTime(2026, 10, 27));
    expect(r, isA<Success<void, String>>(), reason: (r as dynamic).toString());
    await Future<void>.delayed(const Duration(seconds: 1));
    final after = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(after.summary.depositedThroughNo, through + 1);
    expect(after.byNo(through + 1)!.isFrontedByAgent, isTrue, reason: '#19 is only partially paid');

    expect(await n.undoLatestPoDeposit(rd1), isA<Success<void, String>>());
    await Future<void>.delayed(const Duration(seconds: 1));
    final reverted = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(reverted.summary.depositedThroughNo, through);
  });

  test('Write path: undoBatch removes every event of one visit', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final n = container.read(rDLedgerControllerProvider.notifier);
    final before = await container.read(rdLedgerProjectionProvider(rd1).future);
    const batch = 'e2e-batch';
    final batchId = const Uuid().v5(Namespace.url.value, batch);
    expect(await n.depositNextToPo(rdId: rd1, count: 1, batchId: batchId), isA<Success<void, String>>());
    expect(await n.undoBatch(batchId), isA<Success<void, String>>());
    await Future<void>.delayed(const Duration(seconds: 1));
    final after = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(after.summary.depositedThroughNo, before.summary.depositedThroughNo);
  });

  test('Batch facts read: more ids than one IN-chunk still returns each account\'s own facts', () async {
    // 250 ids → three chunks of the `rd_id IN (...)` filter; only rd1 exists.
    final ids = [for (var i = 0; i < 249; i++) const Uuid().v4(), rd1];
    final result = await SupabaseRDLedgerRepository(client).fetchRawFactsForRds(ids);
    final bundles = (result as Success<Map<String, RDRawFactsBundle>, String>).value;
    expect(bundles, hasLength(250));
    expect(bundles[rd1]!.transactions, hasLength(8));
    expect(bundles[rd1]!.poDeposits, hasLength(6));
    expect(bundles[rd1]!.absorptions, hasLength(1));
    expect(bundles[ids.first]!.transactions, isEmpty);
  });

  test('Atomic write: a change with one invalid part stores nothing, and a re-sent payment is one row', () async {
    final repo = SupabaseRDLedgerRepository(client);
    Future<int> txCount() async =>
        (await client.from('rd_transactions').select('id').eq('rd_id', rd1)).length;
    final before = await txCount();

    // A valid payment together with a PO event the database rejects (zero installments).
    final refused = await repo.applyChange(
      RDLedgerChange(
        upsertTransactions: [
          RDTransaction(
            id: const Uuid().v7(),
            rdId: rd1,
            paidDate: DateTime(2026, 10, 27),
            amount: 100,
            paymentMode: RDPaymentMode.cash,
          ),
        ],
        insertPoDeposits: [
          RDPoDeposit(
            id: const Uuid().v7(),
            rdId: rd1,
            depositedOn: DateTime(2026, 10, 27),
            installmentCount: 0,
          ),
        ],
      ),
    );
    expect(refused, isA<Failure<void, String>>());
    expect(await txCount(), before, reason: 'the payment must not be stored when the same call fails');

    // The same payment recorded twice through the controller (a retry) is one row.
    final n = container.read(rDLedgerControllerProvider.notifier);
    final txId = const Uuid().v7();
    RDPaymentDraft draft() => (
          rdId: rd1,
          transactionId: txId,
          amount: 5000.0,
          paidDate: DateTime(2026, 10, 27),
          paymentMode: RDPaymentMode.upi,
        );
    expect(await n.recordPayment(draft()), isA<Success<void, String>>());
    expect(await n.recordPayment(draft()), isA<Success<void, String>>());
    expect(await txCount(), before + 1);

    expect(await n.deletePayment(rdId: rd1, transactionId: txId), isA<Success<void, String>>());
    expect(await txCount(), before);
  });

  test('Write path: re-sending the same PO visit stores it once; undo restores the ledger', () async {
    final n = container.read(rDLedgerControllerProvider.notifier);
    final batchId = const Uuid().v7();
    Future<Result<String, String>> send() => n.depositBatchToPo(
          lines: [(rdId: rd1, count: 1, feeOverride: null)],
          depositedOn: DateTime(2026, 10, 27),
          batchId: batchId,
        );
    Future<List<Map<String, dynamic>>> visitRows() =>
        client.from('rd_po_deposits').select('id, installment_count').eq('batch_id', batchId);

    expect(await send(), isA<Success<String, String>>());
    expect(await send(), isA<Success<String, String>>(), reason: 'a re-sent visit is a no-op');
    final rows = await visitRows();
    expect(rows, hasLength(1));
    expect(rows.single['id'], RDLedgerController.poVisitEventId(batchId, rd1));
    final summary = await client
        .from('rd_ledger_summary')
        .select('deposited_through_no')
        .eq('rd_id', rd1)
        .single();
    expect(summary['deposited_through_no'], 19);

    expect(await n.undoBatch(batchId), isA<Success<void, String>>());
    expect(await visitRows(), isEmpty);
    final restored = await client
        .from('rd_ledger_summary')
        .select('deposited_through_no')
        .eq('rd_id', rd1)
        .single();
    expect(restored['deposited_through_no'], 18);
  });

  test('Stage 0 guards: cold recordPayment never double-counts summary and status toggle keeps summary', () async {
    // Ensure rdLedgerFactsProvider(rd1) is NOT subscribed before recording payment (cold cache).
    final n = container.read(rDLedgerControllerProvider.notifier);
    await n.rebuildSummary(rd1);
    final summaryBefore = await client
        .from('rd_ledger_summary')
        .select('cash_in_hand_cash')
        .eq('rd_id', rd1)
        .single();
    final cashBefore = (summaryBefore['cash_in_hand_cash'] as num).toDouble();

    final txId = const Uuid().v4();
    expect(
      await n.recordPayment((
        rdId: rd1,
        transactionId: txId,
        amount: 5000,
        paidDate: DateTime(2026, 10, 27),
        paymentMode: RDPaymentMode.cash,
      )),
      isA<Success<void, String>>(),
    );

    final summaryAfter = await client
        .from('rd_ledger_summary')
        .select('cash_in_hand_cash')
        .eq('rd_id', rd1)
        .single();
    expect(
      (summaryAfter['cash_in_hand_cash'] as num).toDouble(),
      cashBefore + 5000,
      reason: 'cold-cache recordPayment must add 1x 5000 to summary, never 2x 10000',
    );

    // Toggling deposit status on a locked RD must succeed and preserve rd_ledger_summary.
    expect(
      await container
          .read(recurringDepositsControllerProvider.notifier)
          .toggleDepositStatus(rd1, DepositStatus.closed),
      isA<Success<void, String>>(),
    );
    expect(
      await client.from('rd_ledger_summary').select('rd_id').eq('rd_id', rd1),
      hasLength(1),
    );
    expect(
      await container
          .read(recurringDepositsControllerProvider.notifier)
          .toggleDepositStatus(rd1, DepositStatus.active),
      isA<Success<void, String>>(),
    );

    expect(await n.deletePayment(rdId: rd1, transactionId: txId), isA<Success<void, String>>());
  });

  test('Stage 5 guards: multi-page .range() stitch, batch ensureSummaries, and RD delete protection', () async {
    // 1. Real PostgREST `.range()` pagination stitches 8 transactions across 2-row pages.
    final pagedTxs = await SupabasePaginatedQuery.fetchAllPages<RDTransaction>(
      pageSize: 2,
      fetchPage: (from, to) => client
          .from('rd_transactions')
          .select()
          .eq('rd_id', rd1)
          .order('paid_date', ascending: true)
          .order('id', ascending: true)
          .range(from, to),
      fromJson: RDTransaction.fromJson,
    );
    expect(pagedTxs, hasLength(8));

    // 2. Deleting an RD with recorded ledger facts fails cleanly with mapped 23503 message.
    final deleteBlocked =
        await SupabaseRecurringDepositRepository(client).deleteRecurringDeposit(rd1);
    expect(deleteBlocked, isA<Failure<void, String>>());

    // 3. Batch ensureSummaries(rebuildAll: true) fetches raw facts + bulk upserts summaries cleanly.
    container.listen(monthlyOperationItemsProvider, (_, _) {});
    await container.read(monthlyOperationItemsProvider.future);
    await container
        .read(rDMonthlyOperationsActionsProvider.notifier)
        .ensureSummaries(rebuildAll: true);
    final summaryRows =
        await client.from('rd_ledger_summary').select('rd_id, paid_through_no').eq('rd_id', rd1);
    expect(summaryRows, hasLength(1));
    expect(summaryRows.single['paid_through_no'], 18);
  });

  test('Hub summaries: a Realtime row updates the list without loading the list again', () async {
    final n = container.read(rDLedgerControllerProvider.notifier);
    expect(await n.rebuildSummary(rd1), isA<Success<void, String>>());

    // The same wiring as `SupabaseRDLedgerRepository.watchSummaries`, with the page loads
    // counted.
    var pageLoads = 0;
    final writes = StreamController<List<RDLedgerSummary>>();
    final lists = <List<RDLedgerSummary>>[];
    final sub = SupabasePaginatedQuery.watchKeyedTable<RDLedgerSummary>(
      client: client,
      channelPrefix: 'e2e-summaries',
      table: 'rd_ledger_summary',
      filterColumn: 'agent_id',
      filterValue: agentId,
      fetchPage: (from, to) {
        pageLoads++;
        return client
            .from('rd_ledger_summary')
            .select()
            .eq('agent_id', agentId)
            .order('rd_id', ascending: true)
            .range(from, to);
      },
      fromJson: RDLedgerSummary.fromJson,
      keyColumn: 'rd_id',
      keyOf: (summary) => summary.rdId,
      writes: writes.stream,
      shows: (held, written) =>
          held.copyWith(updatedAt: null) == written.copyWith(updatedAt: null),
    ).listen((result) {
      if (result case Success(:final value)) lists.add(value);
    });
    addTearDown(sub.cancel);
    addTearDown(writes.close);
    RDLedgerSummary shown() => lists.last.firstWhere((s) => s.rdId == rd1);

    await _until(() => lists.isNotEmpty);
    // Let the channel finish joining: Realtime never delivers a change made before that.
    await Future<void>.delayed(const Duration(seconds: 2));
    final loadsBefore = pageLoads;

    final changed = shown().copyWith(customerCredit: shown().customerCredit + 123.45, updatedAt: null);
    expect(
      await SupabaseRDLedgerRepository(client).upsertSummaries([changed]),
      isA<Success<void, String>>(),
    );
    writes.add([changed]);

    await _until(() => shown().customerCredit == changed.customerCredit);
    // Past the confirmation window: a row that was missing, incomplete, undecodable or not
    // recognised as the one just written would have been fetched by a reload by now.
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(pageLoads, loadsBefore, reason: 'the Realtime row was enough; the list was not loaded again');

    final stored = RDLedgerSummary.fromJson(
      await client.from('rd_ledger_summary').select().eq('rd_id', rd1).single(),
    );
    expect(shown(), stored, reason: 'a Realtime row decodes to exactly what a load returns');

    expect(await n.rebuildSummary(rd1), isA<Success<void, String>>());
  });
}

/// Waits until [condition] holds, checking every 50 ms; fails after [timeout].
Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
