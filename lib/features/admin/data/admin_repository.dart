import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/admin/domain/agent_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'admin_repository.g.dart';

abstract class AdminRepository {
  Future<Result<bool, String>> isCurrentUserAdmin();

  Future<Result<List<AgentProfile>, String>> listAgents();

  Future<Result<void, String>> logActingAsEvent({
    required String targetAgentId,
    required ActingAsAuditAction action,
  });
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<bool, String>> isCurrentUserAdmin() async {
    try {
      final Object? result = await _client.rpc<dynamic>('is_admin');
      return Success(result == true);
    } catch (e, st) {
      return Failure(SupabaseErrorMapper.describe(e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<AgentProfile>, String>> listAgents() async {
    try {
      final Object? raw = await _client.rpc<dynamic>('list_agents_for_admin');
      if (raw is! List) {
        return Failure(
          SupabaseErrorMapper.describe(
            const FormatException(
              'Unexpected response from list_agents_for_admin',
            ),
          ),
        );
      }
      final rows = <Map<String, dynamic>>[
        for (final item in raw)
          if (item is Map)
            Map<String, dynamic>.from(item)
          else
            throw const FormatException('Invalid agent profile row'),
      ];
      return Success(
        List<AgentProfile>.unmodifiable(
          decodeRows(rows, AgentProfile.fromJson),
        ),
      );
    } catch (e, st) {
      return Failure(SupabaseErrorMapper.describe(e, stackTrace: st));
    }
  }

  @override
  Future<Result<void, String>> logActingAsEvent({
    required String targetAgentId,
    required ActingAsAuditAction action,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'log_admin_acting_as_event',
        params: {
          'p_target_agent_id': targetAgentId,
          'p_action': action.wireValue,
        },
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(SupabaseErrorMapper.describe(e, stackTrace: st));
    }
  }
}

typedef ActingAsAuditRecord = ({
  String targetAgentId,
  ActingAsAuditAction action,
});

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    this.isAdmin = false,
    List<AgentProfile> agents = const [],
    this.isAdminError,
    this.transientIsAdminFailures = 0,
    this.listAgentsError,
    this.logEventError,
  }) : agents = List<AgentProfile>.of(agents);

  bool isAdmin;
  List<AgentProfile> agents;
  String? isAdminError;
  int transientIsAdminFailures;
  int isAdminCallCount = 0;
  String? listAgentsError;
  String? logEventError;
  final List<ActingAsAuditRecord> loggedEvents = [];

  @override
  Future<Result<bool, String>> isCurrentUserAdmin() async {
    isAdminCallCount++;
    if (transientIsAdminFailures > 0) {
      transientIsAdminFailures--;
      return Failure(isAdminError ?? 'Transient RPC error');
    }
    if (isAdminError != null) return Failure(isAdminError!);
    return Success(isAdmin);
  }

  @override
  Future<Result<List<AgentProfile>, String>> listAgents() async {
    if (listAgentsError != null) return Failure(listAgentsError!);
    return Success(List<AgentProfile>.unmodifiable(agents));
  }

  @override
  Future<Result<void, String>> logActingAsEvent({
    required String targetAgentId,
    required ActingAsAuditAction action,
  }) async {
    if (logEventError != null) return Failure(logEventError!);
    loggedEvents.add((targetAgentId: targetAgentId, action: action));
    return const Success(null);
  }
}

@riverpod
AdminRepository adminRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    return FakeAdminRepository(isAdmin: false);
  }
  return SupabaseAdminRepository(ref.watch(supabaseClientProvider));
}
