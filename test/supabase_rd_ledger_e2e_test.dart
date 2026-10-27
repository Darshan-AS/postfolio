import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// End-to-end provider test against the LOCAL Supabase stack and the seeded agent
/// (`supabase/seed.sql`). Exercises exactly what the RD tab, Monthly Hub and Detail screen
/// read, so a backend/serialisation problem shows up here instead of as an app crash.
///
/// Run: flutter test test/supabase_rd_ledger_e2e_test.dart   (requires `supabase start` + seed)
void main() {
  const url = 'http://127.0.0.1:54321';
  const anon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  const rd1 = 'd1111111-1111-1111-1111-111111111111';

  late SupabaseClient client;
  late ProviderContainer container;

  setUpAll(() async {
    client = SupabaseClient(url, anon,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit));
    final res = await client.auth
        .signInWithPassword(email: 'agent@postfolio.com', password: 'password123');
    expect(res.user, isNotNull, reason: 'seed agent must exist (run seed.sql)');
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
    await client.from('rd_ledger_summary').delete().neq('rd_id', '00000000-0000-0000-0000-000000000000');
    await client.dispose();
  });

  test('RD tab: deposits list loads from recurring_deposit_details_view', () async {
    container.listen(filteredRecurringDepositsProvider, (_, _) {});
    final deposits = await container.read(filteredRecurringDepositsProvider.future);
    expect(deposits, hasLength(3));
    expect(deposits.every((d) => d.customerName != null), isTrue);
  });

  test('Detail: facts stream + projection for seeded RD', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final p = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(p.installments, hasLength(60));
    expect(p.byNo(12)!.isOpeningBaseline, isTrue);
    expect(p.byNo(13)!.isFullySettled, isTrue);
    expect(p.byNo(14)!.isLateFeeWaived, isTrue);
    expect(p.summary.paidThroughNo, greaterThanOrEqualTo(19));
    expect(p.customerCredit, 0);
    expect(p.warnings, isEmpty);
  });

  test('Hub: summaries stream, backfill, rows, KPIs', () async {
    container.listen(monthlyOperationItemsProvider, (_, _) {});
    container.listen(monthlyOperationsKpiProvider, (_, _) {});
    container.listen(rdLedgerSummariesProvider, (_, _) {});
    container.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 10, 1));

    var items = await container.read(monthlyOperationItemsProvider.future);
    expect(items, hasLength(3));

    await container.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Summaries must now exist server-side and round-trip through the realtime stream.
    final rows = await client.from('rd_ledger_summary').select('rd_id, facts_version, open_items');
    expect(rows, hasLength(3));

    container.invalidate(monthlyOperationItemsProvider);
    items = await container.read(monthlyOperationItemsProvider.future);
    final rd1Item = items.firstWhere((i) => i.deposit.id == rd1);
    expect(rd1Item.hasSummary, isTrue);
    expect(rd1Item.installment.installmentNo, 22);
    expect(rd1Item.priorOverdueCount, greaterThan(0), reason: 'Aug/Sep in arrears');

    final kpi = container.read(monthlyOperationsKpiProvider);
    expect(kpi.totalCount, 3);
  });

  test('Write path: record + delete a payment through the real tables', () async {
    container.listen(rdLedgerProjectionProvider(rd1), (_, _) {});
    final before = await container.read(rdLedgerProjectionProvider(rd1).future);
    final n = container.read(rDLedgerControllerProvider.notifier);

    final r = await n.recordPayment((
      rdId: rd1,
      transactionId: null,
      amount: 5000,
      paidDate: DateTime(2026, 10, 27, 9, 30),
      paymentMode: RDPaymentMode.cash,
      splitMode: PaymentSplitMode.includeFees,
      installmentComponent: 0,
      lateFeeComponent: 0,
    ));
    expect(r, isA<Success<void, String>>(), reason: (r as dynamic).toString());

    await Future<void>.delayed(const Duration(seconds: 1));
    final after = await container.read(rdLedgerProjectionProvider(rd1).future);
    expect(after.totalCollected, before.totalCollected + 5000);

    final txRows = await client
        .from('rd_transactions')
        .select('id')
        .eq('rd_id', rd1)
        .eq('paid_date', '2026-10-27');
    final tx = txRows.single['id'] as String;
    final d = await n.deletePayment(rdId: rd1, transactionId: tx);
    expect(d, isA<Success<void, String>>());
  });
}
