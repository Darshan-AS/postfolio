import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/local_seed_agent.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Whether the login screen offers "Sign in as seeded agent": only in a build that talks to
/// the local Supabase stack. Tests override it.
@riverpod
bool seededAgentSignInAvailable(Ref ref) => Env.isLocalBackend;

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final isDemoMode = ref.watch(demoModeProvider);

    if (isDemoMode) {
      // Instantly authenticate with a dummy user
      // so the router thinks we are authenticated in Demo Mode.
      return const AuthState.authenticated(
        user: AuthUser(
          id: 'demo_user',
          email: 'agent@demo.com',
          displayName: 'Demo Agent',
        ),
      );
    }

    final authRepository = ref.watch(authRepositoryProvider);

    final authStream = authRepository.authStateChanges;
    final subscription = authStream.listen((user) {
      Future.microtask(() {
        if (!ref.mounted) return;
        if (user != null) {
          state = AuthState.authenticated(user: user);
        } else {
          state = const AuthState.unauthenticated();
        }
      });
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    // Hydrate synchronously from the active session so Web F5 / deep links never flash /login.
    final currentUser = authRepository.currentUser;
    if (currentUser != null) {
      return AuthState.authenticated(user: currentUser);
    }
    return const AuthState.unauthenticated();
  }

  Future<Result<void, String>> signInWithGoogle() =>
      _signIn(() => ref.read(authRepositoryProvider).signInWithGoogle());

  /// Signs in as the agent `supabase/seed.sql` creates, who owns the seed data. Refused
  /// unless this build talks to the local Supabase stack.
  Future<Result<void, String>> signInAsSeededAgent() {
    if (!ref.read(seededAgentSignInAvailableProvider)) {
      return Future.value(Failure(t.errors.seededAgentLocalOnly));
    }
    return _signIn(
      () => ref
          .read(authRepositoryProvider)
          .signInWithPassword(
            email: LocalSeedAgent.email,
            password: LocalSeedAgent.password,
          ),
    );
  }

  Future<Result<void, String>> _signIn(
    Future<Result<AuthUser, String>> Function() attempt,
  ) async {
    state = const AuthState.loading();
    final result = await attempt();

    switch (result) {
      case Success():
        // The authStream listener will automatically update the state
        return const Success(null);
      case Failure(error: final error):
        state = AuthState.error(error);
        return Failure(error);
    }
  }

  Future<Result<void, String>> signOut() async {
    final isDemoMode = ref.read(demoModeProvider);
    if (isDemoMode) {
      await ref.read(demoModeProvider.notifier).disable();
      return const Success(null);
    }

    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signOut();

    switch (result) {
      case Success():
        // The authStream listener will automatically update the state
        return const Success(null);
      case Failure(error: final error):
        state = AuthState.error(error);
        return Failure(error);
    }
  }
}
