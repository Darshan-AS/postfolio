import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  /// A screen inside a nested navigator, as a tab's screens are, with a button that asks
  /// for a delete confirmation and records the answer.
  Future<List<bool?>> pumpScreen(
    WidgetTester tester, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final answers = <bool?>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(
            height: 80,
            child: Text('navigation bar'),
          ),
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async => answers.add(
                    await AppDialogs.confirmDelete(
                      context,
                      title: 'Delete customer?',
                      content:
                          'Their deposits are deleted with them. This cannot be undone.',
                    ),
                  ),
                  child: const Text('ask'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return answers;
  }

  Future<void> ask(WidgetTester tester) async {
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.text('Delete customer?'), findsOneWidget);
  }

  testWidgets('each button answers and closes the dialog', (tester) async {
    final answers = await pumpScreen(tester);

    await ask(tester);
    await tester.tap(find.text(t.common.delete));
    await tester.pumpAndSettle();
    expect(find.text('Delete customer?'), findsNothing);

    await ask(tester);
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();

    expect(answers, [true, false]);
  });

  testWidgets('back closes it without an answer and the screen stays', (
    tester,
  ) async {
    final answers = await pumpScreen(tester);
    await ask(tester);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Delete customer?'), findsNothing);
    expect(find.text('ask'), findsOneWidget);
    expect(answers, [null]);
  });

  testWidgets('it opens over the navigation bar, not inside the tab', (
    tester,
  ) async {
    await pumpScreen(tester);
    await ask(tester);

    // The bar is under the dialog's scrim: a tap on it closes the dialog.
    await tester.tapAt(tester.getCenter(find.text('navigation bar')));
    await tester.pumpAndSettle();
    expect(find.text('Delete customer?'), findsNothing);
  });

  testWidgets(
    'a screen reader gets the title as the dialog\'s name and both buttons',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);
      await ask(tester);

      final root = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      final named = <String>[];
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.namesRoute) named.add(data.label);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root);
      expect(named, contains('Delete customer?'));

      for (final label in [t.common.cancel, t.common.delete]) {
        final data = tester.getSemantics(find.text(label)).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      handle.dispose();
    },
  );

  testWidgets('nothing overflows at 2.0x text', (tester) async {
    await pumpScreen(tester, textScale: 2.0);
    await ask(tester);

    expect(tester.takeException(), isNull);
    // Both actions are on screen, stacked if they must be.
    for (final label in [t.common.cancel, t.common.delete]) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: label);
      expect(rect.right, lessThanOrEqualTo(360), reason: label);
      expect(rect.bottom, lessThanOrEqualTo(800), reason: label);
    }
  });
}
