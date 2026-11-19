import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/domain/local_seed_agent.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Sign in as seeded agent": the way past the login screen when the app runs against the
/// local Supabase stack, where Google sign-in needs this machine registered in Firebase.
/// A build that talks to any other backend must neither show it nor act on it.
void main() {
  Future<({ProviderContainer container, FakeAuthRepository auth})> harness({
    required bool? localBackend,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        // null leaves the provider as the app ships it.
        if (localBackend != null)
          seededAgentSignInAvailableProvider.overrideWithValue(localBackend),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authControllerProvider, (_, _) {});
    return (container: container, auth: auth);
  }

  Future<void> pumpLogin(
    WidgetTester tester,
    ProviderContainer container, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
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
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AuthController.signInAsSeededAgent', () {
    test('signs in with the credentials the seed file creates', () async {
      final (:container, :auth) = await harness(localBackend: true);

      final result = await container
          .read(authControllerProvider.notifier)
          .signInAsSeededAgent();
      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Success<void, String>>());
      expect(auth.passwordSignIns, [
        (email: LocalSeedAgent.email, password: LocalSeedAgent.password),
      ]);
      expect(
        container.read(authControllerProvider),
        const AuthState.authenticated(
          user: AuthUser(id: 'fake-agent-1', email: LocalSeedAgent.email),
        ),
      );
    });

    test('a failed sign-in is reported like a failed Google sign-in', () async {
      final (:container, :auth) = await harness(localBackend: true);
      auth.signInError = 'Invalid login credentials';

      final result = await container
          .read(authControllerProvider.notifier)
          .signInAsSeededAgent();

      expect(result, isA<Failure<void, String>>());
      expect(
        container.read(authControllerProvider),
        const AuthState.error('Invalid login credentials'),
      );
    });

    test(
      'is refused, and sends nothing, in a build that is not on the local stack',
      () async {
        // The provider as shipped: a test run passes no config, like a production build.
        final (:container, :auth) = await harness(localBackend: null);
        expect(container.read(seededAgentSignInAvailableProvider), isFalse);
        await Future<void>.delayed(Duration.zero);

        final result = await container
            .read(authControllerProvider.notifier)
            .signInAsSeededAgent();

        expect(result, isA<Failure<void, String>>());
        expect(auth.passwordSignIns, isEmpty);
        expect(
          container.read(authControllerProvider),
          const AuthState.unauthenticated(),
        );
      },
    );
  });

  group('LoginScreen', () {
    testWidgets('does not show the button off the local stack', (tester) async {
      final (:container, auth: _) = await harness(localBackend: null);
      await pumpLogin(tester, container);

      expect(find.text(t.auth.signInWithGoogle), findsOneWidget);
      expect(find.text(t.auth.tryDemoMode), findsOneWidget);
      expect(find.text(t.auth.signInAsSeededAgent), findsNothing);
    });

    testWidgets('on the local stack one tap signs in as the seeded agent', (
      tester,
    ) async {
      final (:container, :auth) = await harness(localBackend: true);
      await pumpLogin(tester, container);

      await tester.tap(find.text(t.auth.signInAsSeededAgent));
      await tester.pumpAndSettle();

      expect(auth.passwordSignIns, [
        (email: LocalSeedAgent.email, password: LocalSeedAgent.password),
      ]);
      expect(
        container.read(authControllerProvider),
        isA<AuthStateAuthenticated>(),
      );
    });

    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'with the button, 360dp wide at ${textScale}x text: nothing overflows '
        'and each label is whole',
        (tester) async {
          final (:container, auth: _) = await harness(localBackend: true);
          await pumpLogin(tester, container, textScale: textScale);

          expect(tester.takeException(), isNull);
          for (final label in [
            t.auth.signInWithGoogle,
            t.auth.signInAsSeededAgent,
            t.auth.tryDemoMode,
          ]) {
            final text = tester.renderObject<RenderParagraph>(find.text(label));
            expect(
              text.didExceedMaxLines,
              isFalse,
              reason: '"$label" is cut at ${textScale}x',
            );
          }
        },
      );
    }
  });
}
