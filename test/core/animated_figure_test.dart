import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/widgets/common/animated_figure.dart';

/// A figure that changes while it is on screen counts to its new value.
void main() {
  group('AnimatedFigure', () {
    String rupees(double value) => value.toRupeeFormat();

    Future<void> pumpFigure(
      WidgetTester tester,
      double value, {
      Object? of,
      bool disableAnimations = false,
    }) => tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Scaffold(
          body: AnimatedFigure(value: value, format: rupees, of: of),
        ),
      ),
    );

    /// The amount on screen, as a number.
    double shown(WidgetTester tester) {
      final text = tester.widget<Text>(find.byType(Text)).data!;
      return double.parse(text.replaceAll(RegExp('[^0-9.]'), ''));
    }

    testWidgets('the first value is shown as it is', (tester) async {
      await pumpFigure(tester, 32485);
      expect(find.text(rupees(32485)), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(rupees(32485)), findsOneWidget);
    });

    testWidgets(
      'a new value is counted to, without passing it and without paise',
      (tester) async {
        await pumpFigure(tester, 32485);
        await pumpFigure(tester, 27485.5);

        var last = 32485.0;
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 25));
          final now = shown(tester);
          // Down all the way, and never below where it is going.
          expect(now, lessThanOrEqualTo(last));
          expect(now, greaterThanOrEqualTo(27485.5));
          last = now;
        }
        // Part of the way it was neither the old value nor the new one, and whole rupees.
        await pumpFigure(tester, 32485);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final onTheWay = tester.widget<Text>(find.byType(Text)).data!;
        expect(onTheWay, isNot(rupees(27485.5)));
        expect(onTheWay, isNot(rupees(32485)));
        expect(onTheWay, isNot(contains('.')));

        await tester.pumpAndSettle();
        expect(find.text(rupees(32485)), findsOneWidget);
      },
    );

    testWidgets('another month\'s figure is shown at once', (tester) async {
      await pumpFigure(tester, 32485, of: DateTime(2026, 4));
      await pumpFigure(tester, 12000, of: DateTime(2026, 5));
      expect(find.text(rupees(12000)), findsOneWidget);
    });

    testWidgets('a device set to remove animations gets the value at once', (
      tester,
    ) async {
      await pumpFigure(tester, 32485, disableAnimations: true);
      await pumpFigure(tester, 27485, disableAnimations: true);
      expect(find.text(rupees(27485)), findsOneWidget);
    });
  });
}
