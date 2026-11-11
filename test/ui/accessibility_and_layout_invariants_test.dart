import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_form_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

void main() {
  group('360x800 @ 2.0x TextScaler Accessibility, Overflow & Tap-Target Matrix', () {
    final source = FakeDataSource();
    final customer = source.customers.first;
    final otd = source.oneTimeDeposits.first;
    final rd = source.recurringDeposits.first;

    final screens = <({String name, Widget Function() build})>[
      (name: 'LoginScreen', build: () => const LoginScreen()),
      (name: 'DashboardScreen', build: () => const DashboardScreen()),
      (name: 'CustomersScreen', build: () => const CustomersScreen()),
      (name: 'OneTimeDepositsScreen', build: () => const OneTimeDepositsScreen()),
      (
        name: 'RecurringDepositsScreen (Accounts)',
        build: () => const RecurringDepositsScreen(initialView: 'accounts'),
      ),
      (
        name: 'RecurringDepositsScreen (Monthly Hub)',
        build: () => const RecurringDepositsScreen(initialView: 'hub'),
      ),
      (
        name: 'CustomerDetailScreen',
        build: () => CustomerDetailScreen(customerId: customer.id),
      ),
      (
        name: 'OneTimeDepositDetailScreen',
        build: () => OneTimeDepositDetailScreen(depositId: otd.id),
      ),
      (
        name: 'RecurringDepositDetailScreen (Info)',
        build: () => RecurringDepositDetailScreen(
          depositId: rd.id,
          initialTab: 'info',
        ),
      ),
      (
        name: 'RecurringDepositDetailScreen (Passbook)',
        build: () => RecurringDepositDetailScreen(
          depositId: rd.id,
          initialTab: 'schedule',
        ),
      ),
      (
        name: 'CustomerFormScreen',
        build: () => const CustomerFormScreen(),
      ),
      (
        name: 'OneTimeDepositFormScreen',
        build: () => const OneTimeDepositFormScreen(),
      ),
      (
        name: 'RecurringDepositFormScreen',
        build: () => const RecurringDepositFormScreen(),
      ),
    ];

    for (final themeEntry in <({String name, ThemeData theme})>[
      (name: 'Light', theme: AppTheme.lightTheme),
      (name: 'Dark', theme: AppTheme.darkTheme),
    ]) {
      for (final screen in screens) {
        testWidgets(
          '${themeEntry.name} | ${screen.name}: 0 RenderFlex overflows, >=44dp tap targets, and labeled IconButtons at 360x800 @ 2.0x text',
          (tester) async {
            // 360x800 logical viewport
            tester.view.physicalSize = const Size(720, 1600);
            tester.view.devicePixelRatio = 2.0;
            addTearDown(tester.view.reset);

            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            final authRepo = FakeAuthRepository(
              initialUser: const AuthUser(
                id: 'agent-1',
                email: 'agent@postfolio.dev',
              ),
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
                  theme: themeEntry.theme,
                  builder: (context, child) {
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(
                        textScaler: const TextScaler.linear(2.0),
                        disableAnimations: true,
                      ),
                      child: SkeletonizerConfig(
                        data: AppTheme.skeletonizerConfig(
                          Theme.of(context).colorScheme,
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    );
                  },
                  home: screen.build(),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 250));
            await tester.pump(const Duration(milliseconds: 500));

            expect(tester.takeException(), isNull);

            // Verify every visible IconButton has a tooltip and >= 44x44dp hit box.
            for (final element in find.byType(IconButton).evaluate()) {
              final widget = element.widget as IconButton;
              final renderBox = element.renderObject as RenderBox?;
              if (renderBox == null || !renderBox.hasSize) continue;
              expect(
                widget.tooltip?.trim().isNotEmpty ?? false,
                isTrue,
                reason:
                    '${screen.name} has an unlabeled IconButton without tooltip: $widget',
              );
              expect(
                renderBox.size.width,
                greaterThanOrEqualTo(AppDimensions.minTapTarget),
                reason:
                    '${screen.name} IconButton (${widget.tooltip}) width ${renderBox.size.width} < ${AppDimensions.minTapTarget}',
              );
              expect(
                renderBox.size.height,
                greaterThanOrEqualTo(AppDimensions.minTapTarget),
                reason:
                    '${screen.name} IconButton (${widget.tooltip}) height ${renderBox.size.height} < ${AppDimensions.minTapTarget}',
              );
            }
          },
        );
      }
    }
  });
}
