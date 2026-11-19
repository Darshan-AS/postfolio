import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

/// Canonical identity key for the active user/demo session
/// (`'demo'`, `'auth:<uid>'`, `'auth:<uid>:as:<targetUid>'`, or `null`).
///
/// Session-scoped `keepAlive` providers watch this key so signing out, switching accounts,
/// switching an admin acting-as target, or toggling Demo Mode automatically disposes and
/// resets cached state without cross-session leaks.
/// Gracefully returns `null` in isolated unit tests that do not initialize global singletons.
@riverpod
String? activeSessionKey(Ref ref) {
  try {
    if (ref.watch(demoModeProvider)) return 'demo';
  } catch (_) {
    // Isolated unit tests may omit SharedPreferences overrides when testing domain controllers.
  }

  try {
    final authState = ref.watch(authControllerProvider);
    final String? userId = switch (authState) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => null,
    };
    if (userId == null) return null;

    final targetId = ref.watch(
      actingAsControllerProvider.select((state) => state.targetAgentId),
    );
    if (targetId != null && targetId != userId) {
      return 'auth:$userId:as:$targetId';
    }
    return 'auth:$userId';
  } catch (_) {
    // Isolated unit tests may omit Supabase/AuthRepository overrides when testing repositories.
    return null;
  }
}
