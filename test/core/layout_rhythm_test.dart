import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/accessible_theme_toggle.dart';
import 'package:postfolio/core/widgets/domain/wealth_accumulation_grid.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// Gaps and edges that several screens share: where an app bar's actions end, what ends a
/// detail row, how far apart fields and blocks are.
void main() {
  const phone = Size(360, 800);
  final source = FakeDataSource();

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = phone,
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

  testWidgets('a top-level app bar starts its title and ends its last icon on the page '
      'margin', (tester) async {
    await pumpScreen(tester, const CustomersScreen());
    final bar = find.byType(AppBar);

    final title = tester.getRect(find.descendant(of: bar, matching: find.byType(AppBarTitle)));
    expect(title.left, AppDimensions.pageMargin);

    final lastAction = tester.getRect(
      find.descendant(of: bar, matching: find.byType(AccessibleThemeToggle)),
    );
    // The icon is centred in its button.
    final iconRight = lastAction.right - (lastAction.width - AppDimensions.iconMd) / 2;
    expect(phone.width - iconRight, AppDimensions.pageMargin);
  });

  group('detail rows', () {
    const copyLabel = 'Account No.';
    const linkLabel = 'Customer';
    const plainLabel = 'Start Date';

    Future<void> pumpRows(WidgetTester tester) async {
      tester.view.physicalSize = phone * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              child: DetailSection(
                title: 'Account Information',
                children: [
                  const DetailItem(
                    label: copyLabel,
                    value: '100200301',
                    copyValue: '100200301',
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedTicket01, size: 24),
                  ),
                  DetailItem(
                    label: linkLabel,
                    value: 'Arjun Mehta',
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 24),
                    onTap: () {},
                  ),
                  const DetailItem(
                    label: plainLabel,
                    value: '10 Jan 2025',
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Finder rowOf(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(DetailItem));

    testWidgets('are one height, with or without a copy button', (tester) async {
      await pumpRows(tester);
      for (final label in [copyLabel, linkLabel, plainLabel]) {
        expect(tester.getSize(rowOf(label)).height, AppDimensions.rowMinHeight, reason: label);
      }
    });

    testWidgets('a copy button and a chevron end their rows on the same axis', (tester) async {
      await pumpRows(tester);

      final copy = tester.getRect(find.byKey(const ValueKey('copy_$copyLabel')));
      final chevron = tester.getRect(
        find.descendant(of: rowOf(linkLabel), matching: find.byType(HugeIcon)).last,
      );
      expect(copy.center.dx, chevron.center.dx);
      // A full touch target all the same.
      expect(copy.size, const Size.square(kMinInteractiveDimension));
      // And the leading icons share theirs.
      final leading = [
        for (final label in [copyLabel, linkLabel, plainLabel])
          tester.getRect(find.descendant(of: rowOf(label), matching: find.byType(HugeIcon)).first),
      ];
      expect(leading.map((r) => r.left).toSet(), hasLength(1));
    });
  });

  group('form fields are 16dp apart', () {
    for (final (name, screen) in [
      ('customer', const CustomerFormScreen() as Widget),
      ('recurring deposit', const RecurringDepositFormScreen()),
    ]) {
      testWidgets(name, (tester) async {
        await pumpScreen(tester, screen, size: const Size(360, 2400));

        final fields = [
          for (final element in find.byType(TextFormField).evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ]..sort((a, b) => a.top.compareTo(b.top));
        expect(fields.length, greaterThan(3));
        // The first two text fields of either form follow one another in a section.
        expect(fields[1].top - fields[0].bottom, AppDimensions.paddingLg);
      });
    }
  });

  group('a detail screen\'s blocks are 16dp apart', () {
    testWidgets('recurring deposit: the two figures, the projection, the first section', (
      tester,
    ) async {
      final rd = source.recurringDeposits.first;
      await pumpScreen(
        tester,
        RecurringDepositDetailScreen(depositId: rd.id, initialTab: 'info'),
        size: const Size(360, 2400),
      );

      final figures = tester.getRect(find.byType(DetailStatRow));
      final projection = tester.getRect(find.byType(WealthAccumulationGrid));
      final firstTitle = tester.getRect(find.byType(DetailSectionTitle).first);
      expect(projection.top - figures.bottom, AppDimensions.paddingLg);
      expect(firstTitle.top - projection.bottom, AppDimensions.paddingLg);

      // The two figures sit 8dp apart, like the tiles of the dashboard and the Hub.
      final cards = [
        for (final element in find.byType(DetailStatCard).evaluate())
          tester.getRect(find.byWidget(element.widget)),
      ]..sort((a, b) => a.left.compareTo(b.left));
      expect(cards, hasLength(2));
      expect(cards[1].left - cards[0].right, AppDimensions.paddingSm);
    });

    testWidgets('one-time deposit: the figures and the first section', (tester) async {
      final otd = source.oneTimeDeposits.first;
      await pumpScreen(
        tester,
        OneTimeDepositDetailScreen(depositId: otd.id),
        size: const Size(360, 2400),
      );

      final firstTitle = find.byType(DetailSectionTitle).first;
      final titleRect = tester.getRect(firstTitle);
      // Whatever block of figures the scheme has ends 16dp above the first section.
      final above = [
        for (final element in find.byType(Material).evaluate())
          tester.getRect(find.byWidget(element.widget)),
      ].where((r) => r.bottom <= titleRect.top && r.width > 300 && r.top > 100);
      final lowest = above.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      // The header's lines have heights that are not whole pixels; the sum can be off by
      // a rounding error.
      expect(titleRect.top - lowest, moreOrLessEquals(AppDimensions.paddingLg, epsilon: 0.01));
    });
  });
}
