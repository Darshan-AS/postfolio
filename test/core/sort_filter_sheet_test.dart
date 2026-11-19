import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_bottom_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_filter_section.dart';
import 'package:postfolio/core/widgets/feedback/app_sort_bottom_sheet.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The sort and filter sheets of the list screens, and the list row they sort and filter.
void main() {
  const phone = Size(360, 800);
  const desktop = Size(1100, 700);

  /// A page with one button that opens [open]'s sheet.
  Future<void> pumpAndOpen(
    WidgetTester tester, {
    required Future<void> Function(BuildContext context) open,
    Size size = phone,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('AppSortBottomSheet', () {
    const fields = ['Maturity Date', 'Start Date', 'Customer Name', 'Amount'];

    /// Opens the sheet over state the test can read: like the list screens, the sheet is
    /// rebuilt from that state after every choice.
    Future<({ValueNotifier<(String, SortDirection)> state, List<String> log})>
    openSort(
      WidgetTester tester, {
      Size size = phone,
      double textScale = 1.0,
      bool withReset = true,
    }) async {
      final state = ValueNotifier<(String, SortDirection)>((
        fields.first,
        SortDirection.asc,
      ));
      addTearDown(state.dispose);
      final log = <String>[];

      await pumpAndOpen(
        tester,
        size: size,
        textScale: textScale,
        open: (context) => AppSortBottomSheet.show<String>(
          context: context,
          builder: (context) => ValueListenableBuilder(
            valueListenable: state,
            builder: (context, value, _) => AppSortBottomSheet<String>(
              title: 'Sort By',
              fields: fields,
              selectedField: value.$1,
              selectedDirection: value.$2,
              fieldLabelBuilder: (field) => field,
              directionLabelBuilder: (field, direction) =>
                  direction == SortDirection.asc ? 'Sooner' : 'Later',
              onSelected: (field, direction) {
                log.add('$field ${direction.name}');
                state.value = (field, direction);
              },
              onReset: withReset
                  ? () {
                      log.add('reset');
                      state.value = (fields.first, SortDirection.asc);
                    }
                  : null,
            ),
          ),
        ),
      );
      return (state: state, log: log);
    }

    AppGroupTile tileOf(WidgetTester tester, String field) =>
        tester.widget<AppGroupTile>(
          find.ancestor(
            of: find.text(field),
            matching: find.byType(AppGroupTile),
          ),
        );

    testWidgets(
      'a field tap keeps the direction; a direction tap keeps the field',
      (tester) async {
        final sheet = await openSort(tester);
        expect(tileOf(tester, 'Maturity Date').selected, isTrue);
        expect(tileOf(tester, 'Amount').selected, isFalse);

        await tester.tap(find.text('Later'));
        await settle(tester);
        await tester.tap(find.text('Amount'));
        await settle(tester);
        // The direction already chosen is inert, as in any single-choice group.
        await tester.tap(find.text('Later'));
        await settle(tester);

        expect(sheet.log, ['Maturity Date desc', 'Amount desc']);
        expect(tileOf(tester, 'Amount').selected, isTrue);
        expect(tileOf(tester, 'Maturity Date').selected, isFalse);
      },
    );

    testWidgets('Clear resets and keeps the sheet open; close dismisses it', (
      tester,
    ) async {
      final sheet = await openSort(tester);
      await tester.tap(find.text('Start Date'));
      await settle(tester);

      await tester.tap(find.text(t.common.clear));
      await settle(tester);
      expect(sheet.log.last, 'reset');
      expect(find.text('Sort By'), findsOneWidget);
      expect(tileOf(tester, 'Maturity Date').selected, isTrue);

      await tester.tap(find.byTooltip(t.common.close));
      await settle(tester);
      expect(find.text('Sort By'), findsNothing);
    });

    testWidgets('without a reset callback there is no Clear', (tester) async {
      await openSort(tester, withReset: false);
      expect(find.text(t.common.clear), findsNothing);
    });

    testWidgets(
      'at 2.0x text every field is on screen above the direction buttons',
      (tester) async {
        await openSort(tester, textScale: 2.0);
        expect(tester.takeException(), isNull);

        final directionTop = tester
            .getRect(find.byType(AppButtonGroup<SortDirection>))
            .top;
        for (final field in fields) {
          final rect = tester.getRect(find.text(field));
          expect(rect.top, greaterThanOrEqualTo(0), reason: field);
          expect(rect.bottom, lessThanOrEqualTo(directionTop), reason: field);
        }
      },
    );

    testWidgets('a bottom sheet on a phone', (tester) async {
      await openSort(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a dialog on a wide window', (tester) async {
      await openSort(tester, size: desktop);
      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      // No drag handle in a dialog: the title must not sit on its top edge.
      final surface = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        tester.getRect(find.text('Sort By')).top - surface.top,
        greaterThanOrEqualTo(16),
      );
    });
  });

  group('AppFilterBottomSheet', () {
    const statuses = ['Active', 'Closed'];
    const schemes = ['TD', 'MIS', 'NSC', 'KVP'];

    Future<({ValueNotifier<Set<String>> state, List<String> log})> openFilters(
      WidgetTester tester, {
      Size size = phone,
      double textScale = 1.0,
    }) async {
      final state = ValueNotifier<Set<String>>({'Active'});
      addTearDown(state.dispose);
      final log = <String>[];

      void toggle(String option) {
        log.add(option);
        final next = {...state.value};
        if (!next.remove(option)) next.add(option);
        state.value = next;
      }

      await pumpAndOpen(
        tester,
        size: size,
        textScale: textScale,
        open: (context) => AppFilterBottomSheet.show(
          context: context,
          builder: (context) => ValueListenableBuilder(
            valueListenable: state,
            builder: (context, selected, _) => AppFilterBottomSheet(
              title: 'Filters',
              onClearAll: () {
                log.add('clear');
                state.value = {};
              },
              filterSections: [
                AppFilterSection<String>(
                  title: 'Status',
                  options: statuses,
                  selectedOptions: selected.toList(),
                  labelBuilder: (option) => option,
                  onSelected: toggle,
                ),
                AppFilterSection<String>(
                  title: 'Scheme Type',
                  options: schemes,
                  selectedOptions: selected.toList(),
                  labelBuilder: (option) => option,
                  onSelected: toggle,
                ),
              ],
            ),
          ),
        ),
      );
      return (state: state, log: log);
    }

    Tristate selectedFlag(WidgetTester tester, String option) => tester
        .getSemantics(
          find.ancestor(
            of: find.text(option),
            matching: find.byType(MergeSemantics),
          ),
        )
        .getSemanticsData()
        .flagsCollection
        .isSelected;

    testWidgets('options are independent toggles: on, on, and off again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final sheet = await openFilters(tester);
      expect(selectedFlag(tester, 'Active'), Tristate.isTrue);
      expect(selectedFlag(tester, 'Closed'), Tristate.isFalse);

      await tester.tap(find.text('Closed'));
      await settle(tester);
      await tester.tap(find.text('KVP'));
      await settle(tester);
      // Unlike a single-choice group, tapping a selected option is reported: it turns off.
      await tester.tap(find.text('Active'));
      await settle(tester);

      expect(sheet.log, ['Closed', 'KVP', 'Active']);
      expect(sheet.state.value, {'Closed', 'KVP'});
      expect(selectedFlag(tester, 'Active'), Tristate.isFalse);
      expect(selectedFlag(tester, 'Closed'), Tristate.isTrue);
      expect(selectedFlag(tester, 'KVP'), Tristate.isTrue);
      expect(selectedFlag(tester, 'TD'), Tristate.isFalse);
      semantics.dispose();
    });

    testWidgets(
      'each option is one button to a screen reader, and at least 48dp to touch',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await openFilters(tester);

        for (final option in [...statuses, ...schemes]) {
          final node = find.ancestor(
            of: find.text(option),
            matching: find.byType(MergeSemantics),
          );
          final data = tester.getSemantics(node).getSemanticsData();
          expect(data.label, option);
          expect(data.flagsCollection.isButton, isTrue, reason: option);
          expect(data.hasAction(SemanticsAction.tap), isTrue, reason: option);
          expect(
            tester.getSize(node).height,
            greaterThanOrEqualTo(48),
            reason: option,
          );
        }
        semantics.dispose();
      },
    );

    testWidgets('Clear empties the selection and keeps the sheet open', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final sheet = await openFilters(tester);

      await tester.tap(find.text(t.common.clear));
      await settle(tester);

      expect(sheet.log, ['clear']);
      expect(find.text('Filters'), findsOneWidget);
      expect(selectedFlag(tester, 'Active'), Tristate.isFalse);
      semantics.dispose();
    });

    testWidgets('at 2.0x text every option is whole and on screen', (
      tester,
    ) async {
      await openFilters(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);

      final screen = Offset.zero & phone;
      for (final option in [...statuses, ...schemes]) {
        final text = find.text(option);
        final rect = tester.getRect(text);
        expect(
          screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
          isTrue,
          reason: '$option at $rect',
        );
        // On one line and at full size: a label that did not fit would be painted smaller
        // than it was laid out.
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse, reason: option);
        expect(rect.width, closeTo(paragraph.size.width, 0.5), reason: option);
      }
    });

    testWidgets('a dialog on a wide window', (tester) async {
      await openFilters(tester, size: desktop);
      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('EntityListTile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required double textScale,
    }) async {
      tester.view.physicalSize = phone * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

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
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                EntityListTile(
                  leadingText: 'TD',
                  title: 'Arjun Mehta',
                  subtitle: const Text('500600705'),
                  trailing: const Text('₹1,00,000', key: ValueKey('trailing')),
                  actions: [
                    EntityAction(
                      label: 'Edit',
                      icon: const SizedBox.shrink(),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('at normal text the trailing block sits beside the title', (
      tester,
    ) async {
      await pumpTile(tester, textScale: 1.0);
      final title = tester.getRect(find.text('Arjun Mehta'));
      final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
      expect(trailing.left, greaterThan(title.right));
      expect(trailing.top, lessThan(title.bottom));
    });

    testWidgets(
      'at 2.0x text the trailing block moves below, so the name is not broken '
      'mid-word',
      (tester) async {
        await pumpTile(tester, textScale: 2.0);
        expect(tester.takeException(), isNull);

        final title = find.text('Arjun Mehta');
        final account = tester.getRect(find.text('500600705'));
        final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
        expect(trailing.top, greaterThanOrEqualTo(account.bottom));
        // Still at the end of the row, where the eye finds the amount at normal text.
        expect(trailing.center.dx, greaterThan(phone.width / 2));

        // The name wraps at its space or not at all; it is never cut.
        final paragraph = tester.renderObject<RenderParagraph>(title);
        expect(paragraph.didExceedMaxLines, isFalse);
        final lineBreaks = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 11),
            )
            .map((box) => box.top)
            .toSet();
        expect(lineBreaks.length, lessThanOrEqualTo(2));
        final firstName = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 5),
        );
        expect(
          firstName.map((box) => box.top).toSet(),
          hasLength(1),
          reason: '"Arjun" on one line',
        );
      },
    );
  });
}
