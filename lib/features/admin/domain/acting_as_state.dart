import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';

part 'acting_as_state.freezed.dart';

enum ActingAsAuditAction {
  start('start'),
  end('end');

  const ActingAsAuditAction(this.wireValue);

  final String wireValue;
}

@freezed
sealed class ActingAsState with _$ActingAsState {
  const ActingAsState._();

  const factory ActingAsState.none() = ActingAsStateNone;

  const factory ActingAsState.active({required AgentProfile targetAgent}) =
      ActingAsStateActive;

  bool get isActingAs => this is ActingAsStateActive;

  String? get targetAgentId => switch (this) {
    ActingAsStateNone() => null,
    ActingAsStateActive(:final targetAgent) => targetAgent.id,
  };
}
