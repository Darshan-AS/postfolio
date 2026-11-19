import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_menu.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('every menu is an AppMenu', () {
    // The official menus do not close on back, and the community one cuts its labels
    // unless it is opened through the wrapper.
    final direct = <String>[];
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'\b(MenuAnchor|PopupMenuButton|M3EMenu)\b',
      ).allMatches(source)) {
        if (file.path.endsWith('expressive/app_menu.dart')) continue;
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        direct.add('${file.path}:$line');
      }
    }

    expect(direct, isEmpty);
  });

  group('AppMenu', () {
    Future<List<String>> pumpMenu(
      WidgetTester tester, {
      double textScale = 1.0,
      List<String> labels = const ['Edit payment', 'Delete payment', 'Not now'],
    }) async {
      tester.view.physicalSize = const Size(360, 640) * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final chosen = <String>[];

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
            appBar: AppBar(
              title: const Text('Screen'),
              actions: [
                AppMenu(
                  entries: [
                    for (final (index, label) in labels.indexed)
                      AppMenuEntry(
                        label: label,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          size: AppDimensions.iconSm,
                        ),
                        isDestructive: index == 1,
                        // The last entry is disabled.
                        onPressed: index == labels.length - 1
                            ? null
                            : () => chosen.add(label),
                      ),
                  ],
                  anchorBuilder: (context, open) => IconButton(
                    tooltip: t.common.moreOptions,
                    onPressed: open,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMoreVertical,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return chosen;
    }

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byTooltip(t.common.moreOptions));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from its anchor, reports a choice and closes', (
      tester,
    ) async {
      final chosen = await pumpMenu(tester);
      expect(find.text('Edit payment'), findsNothing);

      await open(tester);
      expect(find.text('Edit payment'), findsOneWidget);
      expect(find.text('Delete payment'), findsOneWidget);

      await tester.tap(find.text('Edit payment'));
      await tester.pumpAndSettle();
      expect(chosen, ['Edit payment']);
      expect(find.text('Edit payment'), findsNothing);
    });

    testWidgets('a disabled entry does nothing and a tap outside closes', (
      tester,
    ) async {
      final chosen = await pumpMenu(tester);
      await open(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);

      await tester.tapAt(const Offset(20, 600));
      await tester.pumpAndSettle();
      expect(find.text('Edit payment'), findsNothing);
      expect(find.text('Screen'), findsOneWidget);
    });

    testWidgets('back closes the menu and leaves the screen', (tester) async {
      await pumpMenu(tester);
      await open(tester);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Handled here: the system is not asked to leave the app.
      expect(handled, isTrue);
      expect(find.text('Edit payment'), findsNothing);
      expect(find.text('Screen'), findsOneWidget);
    });

    testWidgets('a screen reader gets each entry as a button it can press', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMenu(tester);
      await open(tester);

      for (final label in ['Edit payment', 'Delete payment']) {
        final data = tester.getSemantics(find.text(label)).getSemanticsData();
        // The label alone: the icon beside it is not read out.
        expect(data.label, label);
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      handle.dispose();
    });

    testWidgets('is as wide as its longest label needs', (tester) async {
      // The community menu is 224dp wide from an icon button, whatever it holds.
      // 18 characters of the 14dp test font are 252dp.
      final labels = ['Delete payment now', 'Delete', 'Not now'];
      await pumpMenu(tester, labels: labels);
      await open(tester);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text(labels.first),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.width, greaterThan(224));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stops at the window\'s edges at 2.0x text', (tester) async {
      final passbook = t.recurringDeposits.ledger.passbook;
      await pumpMenu(
        tester,
        textScale: 2.0,
        labels: [
          passbook.depositFromPocket,
          passbook.undoLastDeposit,
          t.common.closeDeposit,
        ],
      );
      await open(tester);

      final label = tester.getRect(find.text(passbook.undoLastDeposit));
      expect(label.left, greaterThanOrEqualTo(AppDimensions.paddingSm));
      expect(label.right, lessThanOrEqualTo(360 - AppDimensions.paddingSm));
      expect(tester.takeException(), isNull);
    });
  });
}
