import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';

/// Smoke tests: the RD tab, the Monthly Hub and the RD detail screen must build and settle
/// against the demo data without throwing.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  late FakeRDLedgerRepository ledger;
  late FakeRecurringDepositRepository deposits;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(Widget home) {
    final source = FakeDataSource();
    ledger = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
    );
    deposits = FakeRecurringDepositRepository();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 10)),
        rdLedgerRepositoryProvider.overrideWithValue(ledger),
        recurringDepositRepositoryProvider.overrideWithValue(deposits),
        customerRepositoryProvider.overrideWithValue(FakeCustomerRepository()),
      ],
      child: MaterialApp(home: home),
    );
  }

  tearDown(() {
    ledger.dispose();
    deposits.dispose();
  });

  testWidgets('RD tab (Accounts view) builds and settles', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const RecurringDepositsScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(RecurringDepositsScreen), findsOneWidget);
  });

  testWidgets('Monthly Hub builds, backfills summaries and settles', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const Scaffold(body: RDMonthlyOperationsView())));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RDMonthlyOperationsView)),
    );
    final items = await container.read(monthlyOperationItemsProvider.future);
    expect(items, isNotEmpty);
    expect(items.every((i) => i.hasSummary), isTrue, reason: 'ensureSummaries ran');
  });

  testWidgets('RD detail screen builds and settles', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final rd = FakeDataSource().recurringDeposits.first;
    await tester.pumpWidget(app(RecurringDepositDetailScreen(depositId: rd.id)));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
