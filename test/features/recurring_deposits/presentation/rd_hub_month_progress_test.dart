import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_month_progress.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The Hub's line on how far the month is, and the statement that replaces it when the
/// month is done.
void main() {
  final strings = t.recurringDeposits.monthlyOperations.progress;
  final april = DateTime(2026, 4);

  Future<void> pumpProgress(
    WidgetTester tester, {
    required int settled,
    required int total,
    bool isPast = false,
    bool disableAnimations = false,
    double textScale = 1.0,
  }) {
    tester.view.physicalSize = const Size(360, 800) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RDHubMonthProgress(
              month: april,
              settled: settled,
              total: total,
              isPast: isPast,
            ),
          ),
        ),
      ),
    );
  }

  final bar = find.byKey(const ValueKey('bar'));
  final statement = find.byKey(const ValueKey('settled'));

  testWidgets(
    'a month under way shows how many accounts are settled, as one sentence to a '
    'screen reader',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpProgress(tester, settled: 9, total: 18);

      expect(
        find.text(strings.settledOf(settled: 9, total: 18)),
        findsOneWidget,
      );
      expect(
        tester.widget<AppLinearProgress>(find.byType(AppLinearProgress)).value,
        0.5,
      );
      // The share is a fact, not something in motion: the flat track, which stands still.
      expect(
        tester.widget<AppLinearProgress>(find.byType(AppLinearProgress)).wavy,
        isFalse,
      );
      // The wavy track never comes to rest, and this would time out.
      await tester.pumpAndSettle();
      expect(statement, findsNothing);

      final sentence = strings.semantics(settled: 9, total: 18, month: 'April');
      expect(find.bySemanticsLabel(sentence), findsOneWidget);
      expect(
        find.bySemanticsLabel(strings.settledOf(settled: 9, total: 18)),
        findsNothing,
      );
      semantics.dispose();
    },
  );

  testWidgets('a month whose last account is settled says so instead', (
    tester,
  ) async {
    await pumpProgress(tester, settled: 18, total: 18);

    expect(find.text(strings.settledTitle(month: 'April')), findsOneWidget);
    expect(find.text(strings.settledBody), findsOneWidget);
    expect(bar, findsNothing);
    expect(find.byType(AppLinearProgress), findsNothing);
  });

  testWidgets(
    'nothing is said of a month with no account, or of a past month that is '
    'settled',
    (tester) async {
      await pumpProgress(tester, settled: 0, total: 0);
      expect(tester.getSize(find.byType(RDHubMonthProgress)), Size.zero);

      await pumpProgress(tester, settled: 18, total: 18, isPast: true);
      expect(tester.getSize(find.byType(RDHubMonthProgress)), Size.zero);

      // A past month that is not settled still says how far it got.
      await pumpProgress(tester, settled: 16, total: 18, isPast: true);
      expect(bar, findsOneWidget);
    },
  );

  testWidgets(
    'the statement arrives over time when the month becomes settled on screen',
    (tester) async {
      await pumpProgress(tester, settled: 17, total: 18);
      await pumpProgress(tester, settled: 18, total: 18);
      await tester.pump();

      // On the way the bar is still leaving and the statement is short of its size.
      await tester.pump(AppMotion.spatialDuration ~/ 5);
      expect(bar, findsOneWidget);
      expect(statement, findsOneWidget);
      final onTheWay = tester.getRect(statement).width;

      await tester.pumpAndSettle();
      expect(bar, findsNothing);
      expect(tester.getRect(statement).width, greaterThan(onTheWay));
    },
  );

  testWidgets(
    'a month that is settled when it is opened shows the statement at full size '
    'at once',
    (tester) async {
      await pumpProgress(tester, settled: 18, total: 18);
      final atOnce = tester.getRect(statement);
      await tester.pumpAndSettle();
      expect(tester.getRect(statement), atOnce);
    },
  );

  testWidgets(
    'on a device that removes animations the statement replaces the bar in one '
    'frame',
    (tester) async {
      await pumpProgress(
        tester,
        settled: 17,
        total: 18,
        disableAnimations: true,
      );
      await pumpProgress(
        tester,
        settled: 18,
        total: 18,
        disableAnimations: true,
      );

      expect(bar, findsNothing);
      expect(statement, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('both fit a 360dp phone at 2.0x text', (tester) async {
    await pumpProgress(tester, settled: 9, total: 18, textScale: 2.0);
    expect(tester.takeException(), isNull);
    await pumpProgress(
      tester,
      settled: 18,
      total: 18,
      textScale: 2.0,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
  });
}
