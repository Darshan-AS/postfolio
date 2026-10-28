import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
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
}
