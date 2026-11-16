import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_transactions_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// On rows and headers an avatar's shape names a deposit scheme and nothing else. It also
/// stood for a row's status, a payment's mode, and (differently per person) for nothing.
void main() {
  final source = FakeDataSource();

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 2400),
    DateTime? now,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository(
      initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
    );
    addTearDown(authRepo.dispose);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now ?? DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(customers: source.customers),
        ),
        oneTimeDepositRepositoryProvider.overrideWithValue(
          FakeOneTimeDepositRepository(deposits: source.oneTimeDeposits),
        ),
        recurringDepositRepositoryProvider.overrideWithValue(
          FakeRecurringDepositRepository(deposits: source.recurringDeposits),
        ),
        rdLedgerRepositoryProvider.overrideWithValue(
          FakeRDLedgerRepository(
            transactions: source.rdTransactions,
            poDeposits: source.rdPoDeposits,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: SkeletonizerConfig(
              data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
              child: child!,
            ),
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  Set<AppAvatarShape> shapesIn(WidgetTester tester, Finder scope) => tester
      .widgetList<AppShapeAvatar>(find.descendant(of: scope, matching: find.byType(AppShapeAvatar)))
      .map((avatar) => avatar.shape)
      .toSet();

  final rdShape = RecurringSchemeType.recurringDeposit.avatarShape;

  test('every scheme has a shape of its own, and none is the shape of a person', () {
    final shapes = [
      for (final scheme in OneTimeSchemeType.values) scheme.avatarShape,
      for (final scheme in RecurringSchemeType.values) scheme.avatarShape,
    ];
    expect(shapes.toSet(), hasLength(shapes.length));
    expect(shapes, isNot(contains(AppAvatarShape.person)));
    expect(shapes, isNot(contains(AppAvatarShape.neutral)));
  });

  testWidgets('every customer in the list has the same shape', (tester) async {
    await pumpScreen(tester, const CustomersScreen());
    expect(find.byType(EntityListTile), findsNWidgets(source.customers.length));
    expect(shapesIn(tester, find.byType(EntityListTile)), {AppAvatarShape.person});
  });

  testWidgets('a customer has that shape on their own screen too', (tester) async {
    await pumpScreen(tester, CustomerDetailScreen(customerId: source.customers.first.id));
    expect(shapesIn(tester, find.byType(EntityDetailHeader)), {AppAvatarShape.person});
  });

  for (final (name, now) in [
    ('a settled month', DateTime(2026, 4, 20)),
    ('a month with arrears', DateTime(2026, 10, 20)),
  ]) {
    testWidgets('Monthly Hub rows have the recurring scheme\'s shape whatever their status '
        '($name)', (tester) async {
      await pumpScreen(tester, const RecurringDepositsScreen(initialView: 'hub'), now: now);
      final rows = find.descendant(
        of: find.byType(RDMonthlyOperationsView),
        matching: find.byType(EntityListTile),
      );
      expect(rows, findsWidgets);
      expect(shapesIn(tester, rows), {rdShape});
    });
  }

  testWidgets('a payment\'s avatar is the plain shape: its mode is the icon', (tester) async {
    final rd = source.recurringDeposits.first;
    await pumpScreen(
      tester,
      RecurringDepositDetailScreen(depositId: rd.id, initialTab: 'transactions'),
    );
    final tiles = tester.widgetList<AppShapeAvatar>(
      find.descendant(
        of: find.byType(RDTransactionsSection),
        matching: find.byType(AppShapeAvatar),
      ),
    );
    expect(tiles, isNotEmpty);
    expect(tiles.map((a) => a.shape).toSet(), {AppAvatarShape.neutral});
    expect(tiles.map((a) => a.size).toSet(), {AppDimensions.avatarMd});
  });
}
