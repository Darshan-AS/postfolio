import 'dart:ui' show Tristate;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// The choices that used to be chips: the dashboard chart's scheme selector and its
/// "Include RDs" switch, and the quick amounts on the collect sheet.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Tristate selectedFlag(WidgetTester tester, Finder inside) => tester
      .getSemantics(find.ancestor(of: inside, matching: find.byType(MergeSemantics)).first)
      .getSemanticsData()
      .flagsCollection
      .isSelected;

  group('Dashboard chart selectors', () {
    final source = FakeDataSource();
    const td = OneTimeSchemeType.timeDeposit;
    const mis = OneTimeSchemeType.monthlyIncomeScheme;

    final schemeGroup = find.byType(AppButtonGroup<OneTimeSchemeType?>);
    Finder option(String label) => find.descendant(of: schemeGroup, matching: find.text(label));
    final includeRds = find.widgetWithText(AppButton, t.dashboard.includeRecurringDeposits);

    /// The dashboard in a window tall enough to show the whole chart card.
    Future<ProviderContainer> pumpDashboard(
      WidgetTester tester, {
      double textScale = 1.0,
      double height = 1400,
    }) async {
      tester.view.physicalSize = Size(360, height) * 2;
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
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
                child: child!,
              ),
            ),
            home: const DashboardScreen(),
          ),
        ),
      );
      await settle(tester);
      await settle(tester);
      return container;
    }

    testWidgets('a scheme replaces All, and the same scheme again goes back to All', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await pumpDashboard(tester);
      OneTimeSchemeType? filter() => container.read(dashboardChartFilterProvider);

      expect(filter(), isNull);
      expect(selectedFlag(tester, option(t.dashboard.all)), Tristate.isTrue);
      expect(selectedFlag(tester, option(td.shortName)), Tristate.isFalse);

      await tester.tap(option(td.shortName));
      await settle(tester);
      expect(filter(), td);
      expect(selectedFlag(tester, option(td.shortName)), Tristate.isTrue);
      expect(selectedFlag(tester, option(t.dashboard.all)), Tristate.isFalse);

      await tester.tap(option(mis.shortName));
      await settle(tester);
      expect(filter(), mis);
      expect(selectedFlag(tester, option(td.shortName)), Tristate.isFalse);

      await tester.tap(option(mis.shortName));
      await settle(tester);
      expect(filter(), isNull);
      expect(selectedFlag(tester, option(t.dashboard.all)), Tristate.isTrue);

      // All is already chosen: tapping it changes nothing.
      await tester.tap(option(t.dashboard.all));
      await settle(tester);
      expect(filter(), isNull);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('Include RDs switches only while All is chosen, and is remembered', (
      tester,
    ) async {
      final container = await pumpDashboard(tester);
      bool included() => container.read(dashboardChartIncludeRdsProvider);
      AppButton button() => tester.widget<AppButton>(includeRds);

      expect(included(), isFalse);
      expect(button().selected, isFalse);
      expect(button().onPressed, isNotNull);

      await tester.tap(includeRds);
      await settle(tester);
      expect(included(), isTrue);
      expect(button().selected, isTrue);

      // Under one scheme the switch is off and cannot be pressed.
      await tester.tap(option(td.shortName));
      await settle(tester);
      expect(button().onPressed, isNull);
      expect(button().selected, isFalse);
      await tester.tap(includeRds, warnIfMissed: false);
      await settle(tester);
      expect(included(), isTrue);

      // Back on All it shows the choice made before.
      await tester.tap(option(t.dashboard.all));
      await settle(tester);
      expect(button().onPressed, isNotNull);
      expect(button().selected, isTrue);

      await tester.tap(includeRds);
      await settle(tester);
      expect(included(), isFalse);
      expect(button().selected, isFalse);
    });

    for (final textScale in const [1.0, 1.3, 2.0]) {
      testWidgets('every option is inside a 360dp window at ${textScale}x text', (
        tester,
      ) async {
        await pumpDashboard(tester, textScale: textScale, height: 2400);
        expect(tester.takeException(), isNull);

        final labels = [
          t.dashboard.all,
          for (final scheme in OneTimeSchemeType.values) scheme.shortName,
        ];
        for (final label in labels) {
          final rect = tester.getRect(option(label));
          expect(rect.left, greaterThanOrEqualTo(0), reason: label);
          expect(rect.right, lessThanOrEqualTo(360), reason: label);
        }
        final toggle = tester.getRect(includeRds);
        expect(toggle.left, greaterThanOrEqualTo(0));
        expect(toggle.right, lessThanOrEqualTo(360));
        expect(toggle.height, greaterThanOrEqualTo(48));
      });
    }
  });

  group('Dashboard chart axis', () {
    // The labels on the value axis stop growing at 1.3x text. Their column was a fixed
    // 40dp, so at large text "₹10L" lost its unit and read "₹10".
    for (final (textScale, factor) in const [(1.0, 1.0), (1.3, 1.3), (2.0, 1.3)]) {
      testWidgets('the value column is ${factor}x wide at ${textScale}x text', (tester) async {
        tester.view.physicalSize = const Size(360, 2400) * 2;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);
        final source = FakeDataSource();
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
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: SkeletonizerConfig(
                  data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
                  child: child!,
                ),
              ),
              home: const DashboardScreen(),
            ),
          ),
        );
        await settle(tester);
        await settle(tester);

        final chart = tester.widget<BarChart>(find.byType(BarChart));
        expect(
          chart.data.titlesData.leftTitles.sideTitles.reservedSize,
          closeTo(AppDimensions.chartYAxisReservedSize * factor, 0.01),
        );
      });
    }
  });

  group('Collect sheet quick amounts', () {
    final today = DateTime(2026, 4, 20);
    // Due on the 15th from January: three months open on 20 April.
    final rd = RecurringDeposit(
      id: 'rd-101',
      customerId: 'cust-1',
      customerName: 'Anita Sharma',
      serialNo: '12',
      accountNo: '9988776655',
      schemeType: RecurringSchemeType.recurringDeposit,
      status: DepositStatus.active,
      installmentAmount: 1000,
      interestRate: 6.7,
      termYears: 5,
      termMonths: 0,
      startDate: DateTime(2026, 1, 5),
    );

    Future<void> openCollectSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800) * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => today),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(
              customers: const [Customer(id: 'cust-1', name: 'Anita Sharma')],
            ),
          ),
          recurringDepositRepositoryProvider.overrideWithValue(
            FakeRecurringDepositRepository(deposits: [rd]),
          ),
          rdLedgerRepositoryProvider.overrideWithValue(FakeRDLedgerRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showRDLogPaymentSheet(context, rdId: rd.id),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    List<AppButton> quickAmounts(WidgetTester tester) => tester
        .widgetList<AppButton>(find.byType(AppButton))
        .where((button) => button.selected != null)
        .toList();

    testWidgets('one is marked when the amount is exactly its amount', (tester) async {
      await openCollectSheet(tester);

      final before = quickAmounts(tester);
      expect(before.length, greaterThanOrEqualTo(2));
      expect(before.every((button) => button.selected == false), isTrue);

      final first = before.first.label;
      final second = before[1].label;
      await tester.tap(find.text(first));
      await tester.pumpAndSettle();
      expect(
        [for (final button in quickAmounts(tester)) if (button.selected!) button.label],
        [first],
      );

      await tester.tap(find.text(second));
      await tester.pumpAndSettle();
      expect(
        [for (final button in quickAmounts(tester)) if (button.selected!) button.label],
        [second],
      );

      // Typing another amount leaves none marked.
      await tester.enterText(find.byType(EditableText).first, '1');
      await tester.pumpAndSettle();
      expect(quickAmounts(tester).every((button) => button.selected == false), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each keeps its amount whole and is at least 48dp to touch', (tester) async {
      await openCollectSheet(tester);

      for (final button in quickAmounts(tester)) {
        final label = find.text(button.label);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        // Painted at the size it was laid out at: a label that did not fit would shrink.
        expect(tester.getRect(label).width, closeTo(paragraph.size.width, 0.5),
            reason: button.label);
        final box = tester.getRect(
          find.ancestor(of: label, matching: find.byType(AppButton)),
        );
        expect(box.height, greaterThanOrEqualTo(48), reason: button.label);
        expect(box.left, greaterThanOrEqualTo(0), reason: button.label);
        expect(box.right, lessThanOrEqualTo(360), reason: button.label);
      }
    });
  });
}
