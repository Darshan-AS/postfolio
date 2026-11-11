import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/domain/investment_projection_card.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
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
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_po_strip.dart';
import 'package:postfolio/i18n/strings.g.dart';
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

  group('1280x800 Desktop Visual Sanctity & Flush-Right Row Geometry', () {
    final source = FakeDataSource();

    Future<ProviderContainer> createDesktopContainer() async {
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
      return container;
    }

    Future<void> pumpDesktop(
      WidgetTester tester,
      ProviderContainer container,
      Widget home,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(disableAnimations: true),
                child: SkeletonizerConfig(
                  data: AppTheme.skeletonizerConfig(
                    Theme.of(context).colorScheme,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: home,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }

    testWidgets(
      'OTD, RD, and Customer list views pin 3-dot menus flush-right and align SearchBar top & width',
      (tester) async {
        final container = await createDesktopContainer();
        final searchBarTops = <String, double>{};

        for (final entry in <({String name, Widget screen})>[
          (name: 'OneTimeDepositsScreen', screen: const OneTimeDepositsScreen()),
          (
            name: 'RecurringDepositsScreen',
            screen: const RecurringDepositsScreen(initialView: 'accounts'),
          ),
          (name: 'CustomersScreen', screen: const CustomersScreen()),
        ]) {
          await pumpDesktop(tester, container, entry.screen);

          final searchBarRect = tester.getRect(find.byType(SearchBar));
          searchBarTops[entry.name] = searchBarRect.top;
          expect(
            1280.0 - searchBarRect.width,
            lessThanOrEqualTo(40.0),
            reason: '${entry.name} SearchBar should span full content width',
          );

          final tiles = find.byType(EntityListTile);
          expect(tiles, findsWidgets);
          for (var i = 0; i < tiles.evaluate().length; i++) {
            final tileFinder = tiles.at(i);
            final tileRect = tester.getRect(tileFinder);
            final menuFinder = find.descendant(
              of: tileFinder,
              matching: find.byTooltip(t.common.moreOptions),
            );
            expect(menuFinder, findsOneWidget);
            final menuRect = tester.getRect(menuFinder);
            expect(menuRect.width, equals(AppDimensions.minTapTarget));
            expect(
              tileRect.right - menuRect.right,
              equals(0.0),
              reason:
                  '${entry.name} row #$i left dead empty space (${tileRect.right - menuRect.right}px) after 3-dot menu',
            );
          }
        }

        expect(
          searchBarTops['RecurringDepositsScreen'],
          equals(searchBarTops['OneTimeDepositsScreen']),
          reason: 'SearchBar vertical offset should not jump between OTD and RD tabs',
        );
        expect(
          searchBarTops['CustomersScreen'],
          equals(searchBarTops['OneTimeDepositsScreen']),
        );
      },
    );

    testWidgets(
      'Monthly Hub, RD Passbook, and Live Projection Card align trailing figures & actions flush-right on desktop',
      (tester) async {
        final container = await createDesktopContainer();

        // 1. Monthly Hub cards
        await pumpDesktop(
          tester,
          container,
          const RecurringDepositsScreen(initialView: 'hub'),
        );
        final hubCards = find.byType(RDMonthlyOperationCard);
        expect(hubCards, findsWidgets);
        final firstHubCard = hubCards.first;
        final cardRect = tester.getRect(firstHubCard);
        final owesTexts = find.descendant(
          of: firstHubCard,
          matching: find.textContaining('₹'),
        );
        expect(owesTexts, findsWidgets);
        // At least one money label (headline or button) reaches near the right margin.
        final headlineRect = tester.getRect(owesTexts.first);
        expect(
          cardRect.right - headlineRect.right,
          lessThanOrEqualTo(24.0),
          reason:
              'Monthly Hub money headline floated in the middle (${cardRect.right - headlineRect.right}px from right)',
        );

        // 2. RD Passbook PO strip & installment tiles
        await pumpDesktop(
          tester,
          container,
          RecurringDepositDetailScreen(
            depositId: source.recurringDeposits.first.id,
            initialTab: 'schedule',
          ),
        );
        final poStrip = find.byType(RDPassbookPoStrip);
        expect(poStrip, findsOneWidget);
        final stripRect = tester.getRect(poStrip);
        final stripMenuRect = tester.getRect(
          find.descendant(
            of: poStrip,
            matching: find.byTooltip(t.common.moreOptions),
          ),
        );
        expect(
          stripRect.right - stripMenuRect.right,
          lessThanOrEqualTo(20.0),
          reason: 'RDPassbookPoStrip left dead right space after 3-dot menu',
        );

        final instTile = find.byType(RDInstallmentTile).first;
        final instRect = tester.getRect(instTile);
        final instMoney = find.descendant(
          of: instTile,
          matching: find.textContaining('₹'),
        );
        expect(
          instRect.right - tester.getRect(instMoney.first).right,
          lessThanOrEqualTo(28.0),
          reason: 'RDInstallmentTile amount floated away from right edge',
        );

        // 3. InvestmentProjectionCard on OTD form
        await pumpDesktop(tester, container, const OneTimeDepositFormScreen());
        final principalField = find.ancestor(
          of: find.textContaining(t.oneTimeDeposits.fields.principalAmount),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(principalField, '100000');
        await tester.pumpAndSettle();

        final projCard = find.byType(InvestmentProjectionCard);
        expect(projCard, findsOneWidget);
        final projRect = tester.getRect(projCard);
        final projMoney = find.descendant(
          of: projCard,
          matching: find.textContaining('₹1,00,000'),
        );
        expect(
          projRect.right - tester.getRect(projMoney.first).right,
          lessThanOrEqualTo(24.0),
          reason: 'InvestmentProjectionCard value floated in center instead of flush-right',
        );
      },
    );
  });
}
