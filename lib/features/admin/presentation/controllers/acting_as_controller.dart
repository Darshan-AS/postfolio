import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show ProviderException;
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'acting_as_controller.g.dart';

String? _authenticatedUserId(AuthState state) => switch (state) {
  AuthStateAuthenticated(:final user) => user.id,
  _ => null,
};

/// Delay before retrying a transient `is_admin` RPC failure (e.g. PostgREST `PGRST303`
/// "JWT issued at future" on a freshly minted sign-in token). Overridden in unit tests.
final isAdminRetryDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1200),
);

@Riverpod(keepAlive: true)
Future<bool> isAdmin(Ref ref) async {
  try {
    if (ref.watch(demoModeProvider)) return false;
  } catch (_) {
    // Isolated tests may omit SharedPreferences overrides.
  }

  try {
    final userId = ref.watch(
      authControllerProvider.select(_authenticatedUserId),
    );
    if (userId == null) return false;

    final repo = ref.watch(adminRepositoryProvider);
    var result = await repo.isCurrentUserAdmin();
    if (result is Failure<bool, String>) {
      final retryDelay = ref.read(isAdminRetryDelayProvider);
      if (retryDelay > Duration.zero) {
        await Future<void>.delayed(retryDelay);
      }
      if (!ref.mounted) return false;
      result = await repo.isCurrentUserAdmin();
    }
    return switch (result) {
      Success(:final value) => value,
      Failure() => false,
    };
  } on ProviderException catch (_) {
    // Fail closed when Supabase/auth providers are intentionally unmounted in unit tests.
    return false;
  } catch (e, st) {
    SupabaseErrorMapper.onUnexpected?.call(e, st);
    return false;
  }
}

@riverpod
Future<Result<List<AgentProfile>, String>> adminAgentsList(Ref ref) {
  return ref.watch(adminRepositoryProvider).listAgents();
}

@Riverpod(keepAlive: true)
class ActingAsController extends _$ActingAsController {
  @override
  ActingAsState build() {
    try {
      ref.watch(demoModeProvider);
    } catch (_) {
      // Isolated tests may omit SharedPreferences overrides.
    }
    try {
      ref.watch(authControllerProvider.select(_authenticatedUserId));
    } catch (_) {
      // Isolated tests may omit AuthRepository/Supabase overrides.
    }
    // Always starts cleared in memory and never persists to SharedPreferences.
    return const ActingAsState.none();
  }

  Future<void> startActingAs(AgentProfile target) async {
    if (_isDemoMode()) return;

    final authState = _readAuthState();
    if (authState != null && authState is! AuthStateAuthenticated) return;
    if (authState case AuthStateAuthenticated(
      :final user,
    ) when user.id == target.id) {
      await stopActingAs();
      return;
    }

    final previous = state;
    if (previous case ActingAsStateActive(
      :final targetAgent,
    ) when targetAgent.id == target.id) {
      return;
    }

    state = ActingAsState.active(targetAgent: target);

    if (previous case ActingAsStateActive(:final targetAgent)) {
      await _logEvent(
        targetAgentId: targetAgent.id,
        action: ActingAsAuditAction.end,
      );
    }
    await _logEvent(
      targetAgentId: target.id,
      action: ActingAsAuditAction.start,
    );
  }

  Future<void> stopActingAs() async {
    final previous = state;
    if (previous is! ActingAsStateActive) return;

    state = const ActingAsState.none();
    await _logEvent(
      targetAgentId: previous.targetAgent.id,
      action: ActingAsAuditAction.end,
    );
  }

  bool _isDemoMode() {
    try {
      return ref.read(demoModeProvider);
    } catch (_) {
      return false;
    }
  }

  AuthState? _readAuthState() {
    try {
      return ref.read(authControllerProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _logEvent({
    required String targetAgentId,
    required ActingAsAuditAction action,
  }) async {
    if (!ref.mounted) return;
    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .logActingAsEvent(targetAgentId: targetAgentId, action: action);
      if (result case Failure(:final error)) {
        SupabaseErrorMapper.onUnexpected?.call(
          StateError(error),
          StackTrace.current,
        );
      }
    } catch (e, st) {
      // Audit logging is non-blocking so session transitions and exit never fail.
      SupabaseErrorMapper.onUnexpected?.call(e, st);
    }
  }
}
