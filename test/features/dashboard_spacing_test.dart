import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_chart_section.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_metrics_row.dart';
import 'package:postfolio/features/dashboard/presentation/widgets/dashboard_scheme_breakdown.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// Spacing on the dashboard: the scheme strip at the window's edge, the gaps between the
/// chart's controls, the tall overview tile.
void main() {
  final source = FakeDataSource();

  Future<void> pumpDashboard(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 1600) * 2;
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
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  /// The scheme pills, left to right. A pill is the strip's only stadium-shaped surface.
  List<Rect> pillRects(WidgetTester tester) {
    final pills = find.descendant(
      of: find.byType(DashboardSchemeBreakdown),
      matching: find.byWidgetPredicate((w) => w is Material && w.shape is StadiumBorder),
    );
    return [for (final element in pills.evaluate()) tester.getRect(find.byWidget(element.widget))]
      ..sort((a, b) => a.left.compareTo(b.left));
  }

  group('scheme strip', () {
    for (final width in const [360.0, 412.0]) {
      testWidgets('on a ${width.toInt()}dp phone about half of the next pill shows at the '
          'edge, and no pill ends on it', (tester) async {
        await pumpDashboard(tester, width: width);
        final pills = pillRects(tester);
        expect(pills.length, greaterThan(2), reason: 'fixture: several schemes');

        expect(pills.first.left, AppDimensions.pageMargin);
        final cut = pills.where((p) => p.left < width && p.right > width).toList();
        expect(cut, hasLength(1), reason: 'one pill runs off the edge');
        final showing = (width - cut.single.left) / cut.single.width;
        expect(showing, inInclusiveRange(0.4, 0.6));

        for (final pill in pills) {
          // Ending on the edge, or a hair inside it, is what looked cut off.
          expect((pill.right - width).abs(), greaterThan(AppDimensions.paddingSm));
        }
        // All the same width, so the strip scrolls in even steps.
        expect(pills.map((p) => p.width.round()).toSet(), hasLength(1));
      });
    }

    testWidgets('when every pill fits they share the width between the margins', (
      tester,
    ) async {
      const width = 1100.0;
      await pumpDashboard(tester, width: width);
      final pills = pillRects(tester);
      expect(pills.length, greaterThan(2));

      expect(pills.first.left, AppDimensions.pageMargin);
      expect(pills.last.right, width - AppDimensions.pageMargin);
      expect(pills.map((p) => p.width.round()).toSet(), hasLength(1));
      for (var i = 1; i < pills.length; i++) {
        expect(pills[i].left - pills[i - 1].right, AppDimensions.paddingSm);
      }
    });
  });

  testWidgets('the chart\'s rows of controls are the same distance apart', (tester) async {
    // Wide enough that the test font's title stays on the line of the first control.
    await pumpDashboard(tester, width: 700);
    final card = find.byType(DashboardChartSection);

    final aggregation = tester.getRect(
      find.descendant(of: card, matching: find.byType(AppButtonGroup<ChartAggregation>)),
    );
    final scheme = tester.getRect(
      find.descendant(of: card, matching: find.byType(AppButtonGroup<OneTimeSchemeType?>)),
    );
    final includeRds = tester.getRect(
      find.descendant(
        of: card,
        matching: find.widgetWithText(AppButton, t.dashboard.includeRecurringDeposits),
      ),
    );

    // Each is a 40dp pill in a 48dp touch target: 4dp between targets is 12dp between pills.
    expect(scheme.top - aggregation.bottom, AppDimensions.paddingXs);
    expect(includeRds.top - scheme.bottom, AppDimensions.paddingXs);
    for (final control in [aggregation, scheme, includeRds]) {
      expect(control.height, kMinInteractiveDimension);
    }
  });

  testWidgets('the tall overview tile is inset the same from its top as from its side', (
    tester,
  ) async {
    await pumpDashboard(tester, width: 360);

    // Only the tall tile has a shape badge.
    final badge = find.descendant(
      of: find.byType(DashboardMetricsRow),
      matching: find.byType(AppShapeAvatar),
    );
    expect(badge, findsOneWidget);
    final tile = tester.getRect(find.ancestor(of: badge, matching: find.byType(Material)).first);
    final badgeRect = tester.getRect(badge);

    expect(badgeRect.left - tile.left, AppDimensions.paddingLg);
    expect(badgeRect.top - tile.top, AppDimensions.paddingLg);
  });
}
