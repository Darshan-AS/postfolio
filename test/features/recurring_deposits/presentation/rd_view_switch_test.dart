import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/features/profile/presentation/widgets/agent_avatar.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// The Accounts / Monthly Hub switch of the Recurring tab. It is the way into the Hub, so
/// it is labelled; it was a folder icon and a calendar icon.
void main() {
  final source = FakeDataSource();
  final views = t.recurringDeposits.views;

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 2;
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
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(customers: source.customers),
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
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: SkeletonizerConfig(
              data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
              child: child!,
            ),
          ),
          home: const RecurringDepositsScreen(initialView: 'accounts'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    return container;
  }

  final viewSwitch = find.byType(AppButtonGroup<RDViewMode>);
  Finder label(String text) =>
      find.descendant(of: viewSwitch, matching: find.text(text));

  testWidgets(
    'both views are named in the app bar, and a tap switches between them',
    (tester) async {
      final container = await pumpScreen(tester);
      RDViewMode mode() => container.read(rDViewModeControllerProvider);

      expect(label(views.accounts), findsOneWidget);
      expect(label(views.monthlyHub), findsOneWidget);
      expect(
        find.ancestor(of: viewSwitch, matching: find.byType(AppBar)),
        findsOneWidget,
      );

      expect(mode(), RDViewMode.accounts);
      expect(find.byType(RDMonthlyOperationsView), findsNothing);

      await tester.tap(label(views.monthlyHub));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));
      expect(mode(), RDViewMode.monthlyHub);
      expect(find.byType(RDMonthlyOperationsView), findsOneWidget);

      await tester.tap(label(views.accounts));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));
      expect(mode(), RDViewMode.accounts);
      expect(find.byType(RDMonthlyOperationsView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final textScale in const [1.0, 1.3, 2.0]) {
    testWidgets(
      'at ${textScale}x text the switch stays inside the bar, clear of the avatar '
      'button',
      (tester) async {
        await pumpScreen(tester, textScale: textScale);
        expect(tester.takeException(), isNull);

        final bar = tester.getRect(find.byType(AppBar));
        final control = tester.getRect(viewSwitch);
        final avatar = tester.getRect(find.byType(AgentAvatarButton));
        expect(control.left, greaterThanOrEqualTo(bar.left));
        expect(control.right, lessThanOrEqualTo(avatar.left));
        expect(control.top, greaterThanOrEqualTo(bar.top));
        expect(control.bottom, lessThanOrEqualTo(bar.bottom));
      },
    );
  }
}
