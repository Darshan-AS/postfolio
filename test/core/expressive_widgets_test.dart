import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_fab.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';

/// What the `App*` wrappers promise on top of the community Material 3 Expressive widgets.
///
/// Each case here was a defect seen with the bare community widget (a second copy of every
/// label in the tree, 40dp touch targets, labels cut or broken mid-word at large text, an
/// overflowing FAB). They are pinned so an upgrade of `material_3_expressive`, or a move of
/// a wrapper onto the official widget, cannot bring one back unnoticed.
void main() {
  const phone = Size(360, 800);

  Future<void> pumpOnPhone(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = phone * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: child,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('AppButtonGroup', () {
    Widget group({
      required String selected,
      required ValueChanged<String> onChanged,
    }) => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.pageMargin),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppButtonGroup<String>(
            key: const ValueKey('group'),
            selected: selected,
            onChanged: onChanged,
            segments: const [
              AppSegment(value: 'info', label: 'Info'),
              AppSegment(value: 'passbook', label: 'Passbook'),
              AppSegment(value: 'transactions', label: 'Transactions'),
            ],
          ),
        ),
      ),
    );

    testWidgets('each label is in the tree once, in full, at 360dp', (tester) async {
      await pumpOnPhone(tester, group(selected: 'info', onChanged: (_) {}));

      expect(tester.takeException(), isNull);
      for (final label in ['Info', 'Passbook', 'Transactions']) {
        expect(find.text(label), findsOneWidget);
        // Not shrunk either: at 1.0x on a phone the three labels fit at full size.
        final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
        expect(paragraph.didExceedMaxLines, isFalse);
        final fitted = tester.widget<FittedBox>(
          find.ancestor(of: find.text(label), matching: find.byType(FittedBox)).first,
        );
        expect(fitted.fit, BoxFit.scaleDown);
        expect(
          tester.getSize(find.text(label)).width,
          lessThanOrEqualTo(
            tester
                .getSize(
                  find.ancestor(of: find.text(label), matching: find.byType(FittedBox)).first,
                )
                .width,
          ),
          reason: '"$label" is wider than its slot, so it is being scaled down at 1.0x',
        );
      }
    });

    testWidgets('touch target is 48dp tall: a tap above the 40dp pill still selects', (
      tester,
    ) async {
      String? chosen;
      await pumpOnPhone(tester, group(selected: 'info', onChanged: (v) => chosen = v));

      final box = tester.getRect(find.byKey(const ValueKey('group')));
      expect(box.height, greaterThanOrEqualTo(AppDimensions.actionButtonSize));

      final label = tester.getRect(find.text('Transactions'));
      await tester.tapAt(Offset(label.center.dx, box.top + 1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(chosen, 'transactions');
    });

    testWidgets('tapping the selected segment reports nothing', (tester) async {
      var calls = 0;
      await pumpOnPhone(tester, group(selected: 'info', onChanged: (_) => calls++));

      await tester.tap(find.text('Info'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(calls, 0);
    });

    testWidgets('a labelled segment is one semantics node: name, button, selected', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpOnPhone(tester, group(selected: 'passbook', onChanged: (_) {}));

      for (final (label, isSelected) in [('Info', false), ('Passbook', true)]) {
        final data = tester
            .getSemantics(
              find.ancestor(of: find.text(label), matching: find.byType(MergeSemantics)),
            )
            .getSemanticsData();
        expect(data.label, label);
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          data.flagsCollection.isSelected,
          isSelected ? Tristate.isTrue : Tristate.isFalse,
        );
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      semantics.dispose();
    });

    testWidgets('above 1.3x text the segments stack so no label is cut', (tester) async {
      await pumpOnPhone(
        tester,
        group(selected: 'info', onChanged: (_) {}),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      final info = tester.getRect(find.text('Info'));
      final passbook = tester.getRect(find.text('Passbook'));
      final transactions = tester.getRect(find.text('Transactions'));
      expect(passbook.top, greaterThan(info.bottom));
      expect(transactions.top, greaterThan(passbook.bottom));
    });

    testWidgets('an icon-only segment is found, and announced, by its tooltip', (tester) async {
      final semantics = tester.ensureSemantics();
      String? chosen;
      await pumpOnPhone(
        tester,
        Scaffold(
          appBar: AppBar(
            title: const Text('Recurring Deposits'),
            actions: [
              AppButtonGroup<String>(
                expand: false,
                selected: 'accounts',
                onChanged: (v) => chosen = v,
                segments: const [
                  AppSegment(
                    value: 'accounts',
                    tooltip: 'Accounts',
                    icon: HugeIcons.strokeRoundedFolder01,
                  ),
                  AppSegment(
                    value: 'hub',
                    tooltip: 'Monthly Hub',
                    icon: HugeIcons.strokeRoundedCalendar03,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.byTooltip('Monthly Hub'), findsOneWidget);

      // One semantics node per segment carries the name, the button role, the selected
      // state and the tap action. Unmerged, the community button puts "selected" on one
      // node and an unnamed button on another.
      for (final (tooltip, isSelected) in [('Accounts', true), ('Monthly Hub', false)]) {
        final data = tester.getSemantics(find.byTooltip(tooltip)).getSemanticsData();
        // Named by its tooltip, exactly like the official IconButton.
        expect(data.tooltip, tooltip);
        expect(data.label, isEmpty, reason: 'the name must not be announced twice');
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          data.flagsCollection.isSelected,
          isSelected ? Tristate.isTrue : Tristate.isFalse,
        );
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      expect(
        tester.getSize(find.byTooltip('Monthly Hub')).height,
        greaterThanOrEqualTo(AppDimensions.minTapTarget),
      );

      await tester.tap(find.byTooltip('Monthly Hub'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(chosen, 'hub');
      semantics.dispose();
    });
  });

  group('AppButton', () {
    testWidgets('a money label that does not fit shrinks; it is never cut', (tester) async {
      const label = 'Deposit 6 installments · ₹1,27,420';
      await pumpOnPhone(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.pageMargin),
            child: Column(
              children: [
                AppButton(
                  label: label,
                  icon: HugeIcons.strokeRoundedTick01,
                  size: AppButtonSize.medium,
                  expand: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(label), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.text.toPlainText(), label);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.overflow, isNot(TextOverflow.ellipsis));

      // The whole label is painted inside the button.
      final button = tester.getRect(find.byType(AppButton));
      final text = tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(FittedBox)).first,
      );
      expect(text.left, greaterThanOrEqualTo(button.left));
      expect(text.right, lessThanOrEqualTo(button.right));
    });

    testWidgets('while loading it ignores taps; with no callback it is disabled', (
      tester,
    ) async {
      var presses = 0;
      await pumpOnPhone(
        tester,
        Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Save', onPressed: () => presses++),
              AppButton(label: 'Saving', isLoading: true, onPressed: () => presses++),
              const AppButton(label: 'Unavailable', onPressed: null),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(presses, 1);

      await tester.tap(find.text('Saving'), warnIfMissed: false);
      await tester.tap(find.text('Unavailable'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(presses, 1);
    });

    testWidgets('is at least 44dp tall to touch in every size', (tester) async {
      await pumpOnPhone(
        tester,
        Scaffold(
          body: Column(
            children: [
              for (final size in AppButtonSize.values)
                AppButton(
                  key: ValueKey(size),
                  label: size.name,
                  size: size,
                  onPressed: () {},
                ),
            ],
          ),
        ),
      );

      for (final size in AppButtonSize.values) {
        expect(
          tester.getSize(find.byKey(ValueKey(size))).height,
          greaterThanOrEqualTo(AppDimensions.minTapTarget),
          reason: '${size.name} button',
        );
      }
    });

    testWidgets('its tooltip is the official one, on the button\'s own semantics node', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpOnPhone(
        tester,
        Scaffold(
          body: AppButton.tonal(
            label: 'Collect',
            tooltip: 'Collect from customer',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byTooltip('Collect from customer'), findsOneWidget);
      final data = tester
          .getSemantics(find.byTooltip('Collect from customer'))
          .getSemanticsData();
      expect(data.label, 'Collect');
      expect(data.tooltip, 'Collect from customer');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });

  group('AppExtendedFab', () {
    testWidgets('stays inside a 360dp window at 2.0x text', (tester) async {
      var presses = 0;
      await pumpOnPhone(
        tester,
        Scaffold(
          floatingActionButton: AppExtendedFab(
            label: 'New Customer',
            icon: HugeIcons.strokeRoundedAdd01,
            onPressed: () => presses++,
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('New Customer'), findsOneWidget);
      final fab = tester.getRect(find.byType(AppExtendedFab));
      expect(fab.left, greaterThanOrEqualTo(0));
      expect(fab.right, lessThanOrEqualTo(phone.width));

      await tester.tap(find.text('New Customer'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(presses, 1);
    });
  });

  group('AppNavigationBar and AppNavigationRail', () {
    const destinations = [
      AppDestination(icon: HugeIcons.strokeRoundedDashboardSquare01, label: 'Dashboard'),
      AppDestination(icon: HugeIcons.strokeRoundedMoneyReceiveSquare, label: 'One-Time'),
      AppDestination(icon: HugeIcons.strokeRoundedTransaction, label: 'Recurring'),
      AppDestination(icon: HugeIcons.strokeRoundedUserMultiple, label: 'Customers'),
    ];

    testWidgets('bar labels stop growing at 1.3x text; selecting reports the index', (
      tester,
    ) async {
      int? selected;
      await pumpOnPhone(
        tester,
        Scaffold(
          bottomNavigationBar: AppNavigationBar(
            destinations: destinations,
            selectedIndex: 0,
            onSelected: (i) => selected = i,
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      for (final destination in destinations) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(destination.label),
        );
        // Uncapped, the community bar breaks "Dashboard" mid-word at 2.0x. (Whether a
        // label fits on one line at 1.3x depends on the font; this test font's glyphs are
        // a full em wide, so only the cap itself is asserted.)
        expect(paragraph.textScaler.scale(10), closeTo(13, 0.01));
      }

      await tester.tap(find.text('Customers'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(selected, 3);
    });

    testWidgets('rail gives each label an 80dp slot and selecting reports the index', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                AppNavigationRail(
                  destinations: destinations,
                  selectedIndex: 0,
                  onSelected: (i) => selected = i,
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      final rail = tester.getRect(find.byType(AppNavigationRail));
      for (final destination in destinations) {
        final label = find.text(destination.label);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        // The community rail leaves a label 56dp and clips the rest without an ellipsis;
        // "Dashboard" and "Customers" need about 62dp in Roboto (75dp at the 1.3x cap).
        // The wrapper widens the slot to 80dp.
        expect(
          paragraph.constraints.maxWidth,
          greaterThanOrEqualTo(80),
          reason: 'slot for "${destination.label}"',
        );
        final rect = tester.getRect(label);
        expect(rect.left, greaterThanOrEqualTo(rail.left));
        expect(rect.right, lessThanOrEqualTo(rail.right));
      }

      await tester.tap(find.text('Recurring'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(selected, 2);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('accepts a size below the 24dp the community widget asserts on', (
      tester,
    ) async {
      await pumpOnPhone(
        tester,
        const Scaffold(body: Center(child: AppLoadingIndicator(size: 16))),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppLoadingIndicator)).shortestSide,
        greaterThanOrEqualTo(AppLoadingIndicator.inlineSize),
      );
    });
  });
}
