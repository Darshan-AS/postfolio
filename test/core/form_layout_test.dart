import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/layout/form_screen_body.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Create / edit forms: one labelled way to save that stays in reach, and labels that are
/// read in full at any text size.
void main() {
  const phone = Size(360, 800);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget home, {double textScale = 1.0}) => MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: home,
  );

  group('saving a form', () {
    Future<void> pumpCustomerForm(WidgetTester tester, {double textScale = 1.0}) async {
      usePhone(tester);
      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(customers: const []),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app(const CustomerFormScreen(), textScale: textScale),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    final save = find.widgetWithText(AppButton, t.common.confirm);
    final nameRequired = Customer.validateName('')!;

    testWidgets('there is one way to save: a labelled button under the fields, on screen '
        'without scrolling', (tester) async {
      await pumpCustomerForm(tester);

      expect(save, findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(IconButton)), findsNothing);
      expect(find.byTooltip(t.common.confirm), findsNothing);

      final button = tester.getRect(save);
      expect(button.bottom, lessThanOrEqualTo(phone.height));
      expect(button.top, greaterThan(phone.height / 2));
      // Under the scrolling fields, not over them.
      expect(button.top, greaterThanOrEqualTo(tester.getRect(find.byType(Scrollable).first).bottom));
    });

    testWidgets('it saves: with nothing filled in, the required field reports itself', (
      tester,
    ) async {
      await pumpCustomerForm(tester);
      expect(find.text(nameRequired), findsNothing);

      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text(nameRequired), findsWidgets);
    });

    testWidgets('it stays above the keyboard', (tester) async {
      await pumpCustomerForm(tester);
      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 2);
      await tester.pumpAndSettle();

      final button = tester.getRect(save);
      expect(button.bottom, lessThanOrEqualTo(phone.height - keyboard));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text(nameRequired), findsWidgets);
    });

    testWidgets('at 2.0x text the button is still on screen and inside the window', (
      tester,
    ) async {
      await pumpCustomerForm(tester, textScale: 2.0);
      final button = tester.getRect(save);
      expect(button.left, greaterThanOrEqualTo(0));
      expect(button.right, lessThanOrEqualTo(phone.width));
      expect(button.bottom, lessThanOrEqualTo(phone.height));
    });

    testWidgets('on a wide window the button is as wide as the form, not the window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900) * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: FormScreenBody(
              isSaving: false,
              onSave: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      final button = tester.getRect(save);
      expect(button.width, AppDimensions.maxFormWidth);
      expect(button.center.dx, 700);
    });

    testWidgets('while saving it says so and ignores taps', (tester) async {
      usePhone(tester);
      var saves = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: FormScreenBody(
              isSaving: true,
              onSave: () => saves++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      expect(find.text(t.common.saving), findsOneWidget);
      expect(find.text(t.common.confirm), findsNothing);
      await tester.tap(find.byType(AppButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(saves, 0);
    });
  });

  group('field labels', () {
    const label = 'Installments deposited before the app';
    const icon = HugeIcon(icon: HugeIcons.strokeRoundedCoins01, size: AppDimensions.iconMd);

    Future<void> pumpFields(WidgetTester tester, double textScale) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTextField(labelText: label, prefixIcon: icon, isRequired: true),
                  AppSpacings.gapMd,
                  AppDropdownField<int>(
                    value: 5,
                    labelText: 'Term in years',
                    isRequired: true,
                    items: const [DropdownMenuItem(value: 5, child: Text('5'))],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
          textScale: textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    }

    Finder labelText(String text) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith(text),
    );

    for (final textScale in const [1.0, AppDimensions.largeTextScale]) {
      testWidgets('up to 1.3x (${textScale}x) the label is inside its field', (tester) async {
        await pumpFields(tester, textScale);
        expect(
          find.ancestor(of: labelText(label), matching: find.byType(TextFormField)),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: labelText('Term in years'),
            matching: find.byType(DropdownButtonFormField<int>),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('above 1.3x it is a line of its own above the field, in full, with the '
        'required marker', (tester) async {
      await pumpFields(tester, 2.0);

      for (final (text, field) in [
        (label, find.byType(TextFormField)),
        ('Term in years', find.byType(DropdownButtonFormField<int>)),
      ]) {
        final above = labelText(text);
        expect(above, findsOneWidget);
        expect(find.ancestor(of: above, matching: field), findsNothing);

        final paragraph = tester.renderObject<RenderParagraph>(above);
        expect(paragraph.text.toPlainText(), '$text *');
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.maxLines, isNull);

        final labelRect = tester.getRect(above);
        final fieldRect = tester.getRect(field);
        expect(labelRect.bottom, lessThanOrEqualTo(fieldRect.top));
        expect(labelRect.left, greaterThanOrEqualTo(fieldRect.left));
        expect(labelRect.right, lessThanOrEqualTo(fieldRect.right));
      }
      // The long one needed a second line; inside the field it had one and was cut.
      expect(
        tester.getSize(labelText(label)).height,
        greaterThan(tester.getSize(labelText('Term in years')).height),
      );
    });
  });

  group('a field of several rows', () {
    testWidgets('has its icon level with the first row; a one-row field has it centred', (
      tester,
    ) async {
      usePhone(tester);
      const notesKey = ValueKey('notes');
      const nameKey = ValueKey('name');
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(AppDimensions.pageMargin),
              child: Column(
                children: [
                  AppTextField(
                    key: nameKey,
                    labelText: 'Name',
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                  AppSpacings.gapMd,
                  AppTextField(
                    key: notesKey,
                    labelText: 'Notes',
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedNote01,
                      size: AppDimensions.iconMd,
                    ),
                    minLines: 3,
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Rect iconOf(Key key) => tester.getRect(
        find.descendant(of: find.byKey(key), matching: find.byType(HugeIcon)),
      );
      final name = tester.getRect(find.byKey(nameKey));
      final notes = tester.getRect(find.byKey(notesKey));
      expect(notes.height, greaterThan(name.height * 1.5));

      final nameIcon = iconOf(nameKey);
      final notesIcon = iconOf(notesKey);
      expect(nameIcon.center.dy, moreOrLessEquals(name.center.dy, epsilon: 1));
      // As far below the top of its field as the one-row field's icon is.
      expect(
        notesIcon.center.dy - notes.top,
        moreOrLessEquals(nameIcon.center.dy - name.top, epsilon: 1),
      );

      final labelTop = tester.getRect(find.text('Notes')).center.dy;
      expect(labelTop, moreOrLessEquals(notesIcon.center.dy, epsilon: 2));
    });
  });
}
