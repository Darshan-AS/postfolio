import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screen's one mark may open from another shape: once, and then it is still.
void main() {
  /// The shape the avatar is drawn in right now: what its surface is clipped to, which is
  /// not always the shape it was last given.
  ShapeBorder shapeOf(WidgetTester tester) {
    final surface = tester.widget<PhysicalShape>(
      find.descendant(
        of: find.byType(AppShapeAvatar),
        matching: find.byType(PhysicalShape),
      ),
    );
    return (surface.clipper as ShapeBorderClipper).shape;
  }

  Matcher isShape(AppAvatarShape shape) => isA<MaterialShapeBorder>().having(
    (border) => border.shape,
    'shape',
    shape.polygon,
  );

  Future<void> pumpAvatar(
    WidgetTester tester, {
    AppAvatarShape? opensFrom,
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: AppShapeAvatar(
            shape: AppAvatarShape.softBurst,
            opensFrom: opensFrom,
            child: const SizedBox(),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'an avatar that opens from a shape starts as it, turns into its own and stays',
    (tester) async {
      await pumpAvatar(tester, opensFrom: AppAvatarShape.circle);
      expect(shapeOf(tester), isShape(AppAvatarShape.circle));

      // It waits while the screen's content fades in, so that the turning is seen.
      await tester.pump(AppMotion.spatialFastDuration ~/ 2);
      expect(shapeOf(tester), isShape(AppAvatarShape.circle));

      // Then a blend of the two shapes, which is neither.
      await tester.pump(AppMotion.spatialFastDuration);
      expect(shapeOf(tester), isNot(isA<MaterialShapeBorder>()));

      // The turning ends when its time is up, with the avatar's own shape drawn: nothing
      // trails behind it.
      await tester.pump(AppMotion.spatialDuration);
      expect(shapeOf(tester), isShape(AppAvatarShape.softBurst));
      await tester.pumpAndSettle();
      expect(shapeOf(tester), isShape(AppAvatarShape.softBurst));
    },
  );

  testWidgets(
    'a device set to remove animations gets the avatar\'s own shape at once',
    (tester) async {
      await pumpAvatar(
        tester,
        opensFrom: AppAvatarShape.circle,
        disableAnimations: true,
      );
      expect(shapeOf(tester), isShape(AppAvatarShape.softBurst));
      // Nothing is left running that would turn it.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TweenAnimationBuilder<ShapeBorder?>,
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'an avatar with nothing to open from is its own shape from the first frame',
    (tester) async {
      await pumpAvatar(tester);
      expect(shapeOf(tester), isShape(AppAvatarShape.softBurst));
    },
  );

  testWidgets(
    'the sign-in mark opens from a circle as the screen arrives, and the screen '
    'comes to rest',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository();
      addTearDown(authRepo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      expect(shapeOf(tester), isShape(AppAvatarShape.circle));

      // An animation that never ends would time out here.
      await tester.pumpAndSettle();
      expect(shapeOf(tester), isShape(AppAvatarShape.softBurst));
      expect(tester.takeException(), isNull);
    },
  );
}
