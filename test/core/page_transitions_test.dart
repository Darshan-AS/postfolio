import 'package:animations/animations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_theme.dart';

void main() {
  group('Page transitions', () {
    final themes = <String, ThemeData Function()>{
      'light': () => AppTheme.lightTheme,
      'dark': () => AppTheme.darkTheme,
      'accessibleLight': () => AppTheme.accessibleLightTheme,
      'accessibleDark': () => AppTheme.accessibleDarkTheme,
    };

    for (final MapEntry(key: name, value: theme) in themes.entries) {
      test('$name: every platform has a transition of its own', () {
        final builders = theme().pageTransitionsTheme.builders;

        // A platform that is not listed falls back to the Android 10 zoom.
        expect(builders.keys, containsAll(TargetPlatform.values));

        // Follows the finger during a back swipe, fades forwards for a tap. Both screens
        // are drawn live meanwhile: a picture of each, taken on its first frame, would keep
        // a row's avatar and name in the list after they have set out for the next screen
        // (`EntityHero`), and would not show what fades in behind them.
        expect(
          builders[TargetPlatform.android],
          isA<PredictiveBackPageTransitionsBuilder>().having(
            (builder) => builder.allowSnapshotting,
            'allowSnapshotting',
            isFalse,
          ),
        );
        for (final desktop in const [
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.fuchsia,
        ]) {
          expect(
            builders[desktop],
            isA<SharedAxisPageTransitionsBuilder>().having(
              (builder) => builder.transitionType,
              'transitionType',
              SharedAxisTransitionType.horizontal,
            ),
            reason: '$desktop',
          );
        }
      });
    }

    Future<void> pumpDetailOverList(WidgetTester tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Text('List')),
        ),
      );
      // ignore: unawaited_futures
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Detail')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);
    }

    testWidgets('on iOS a screen is swiped back from the left edge', (
      tester,
    ) async {
      await pumpDetailOverList(tester);

      // An iPhone has no back button: the edge swipe is the system's way back.
      await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
      await tester.pumpAndSettle();

      expect(find.text('Detail'), findsNothing);
      expect(find.text('List'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets(
      'on a desktop a drag from the left edge is not a way back',
      (tester) async {
        await pumpDetailOverList(tester);

        await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
        await tester.pumpAndSettle();

        expect(find.text('Detail'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }),
    );
  });
}
