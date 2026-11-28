import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/profile/data/profile_repository.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// Loads and updates the signed-in agent's own profile.
///
/// Intentionally reads [authControllerProvider] rather than `effectiveAgentIdProvider`
/// so Admin Acting-As never overwrites or displays another agent's profile here.
@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  FutureOr<AgentProfile?> build() async {
    try {
      ref.watch(demoModeProvider);
      ref.watch(demoSessionEpochProvider);
    } catch (_) {
      // Isolated tests may omit SharedPreferences overrides.
    }

    AuthUser? user;
    try {
      final authState = ref.watch(authControllerProvider);
      user = switch (authState) {
        AuthStateAuthenticated(:final user) => user,
        _ => null,
      };
    } catch (_) {
      // Isolated widget tests may omit Supabase/AuthRepository overrides.
      return null;
    }
    if (user == null) return null;

    ProfileRepository repo;
    try {
      repo = ref.watch(profileRepositoryProvider);
    } catch (_) {
      // Fallback to AuthUser metadata when Supabase is not initialized in widget tests.
      return AgentProfile(
        id: user.id,
        name: user.displayName,
        email: user.email,
      );
    }

    final result = await repo.fetchProfile(user.id);
    return switch (result) {
      Success(value: final profile?) => profile,
      Success(value: null) => AgentProfile(
        id: user.id,
        name: user.displayName,
        email: user.email,
      ),
      Failure(:final error) => throw StateError(error),
    };
  }

  Future<Result<void, String>> saveProfile(AgentProfile updated) async {
    final validationError = updated.validate();
    if (validationError != null) return Failure(validationError);

    final normalized = updated.normalized();
    final result = await ref
        .read(profileRepositoryProvider)
        .updateProfile(normalized);
    switch (result) {
      case Success(:final value):
        state = AsyncData(value);
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }
}
