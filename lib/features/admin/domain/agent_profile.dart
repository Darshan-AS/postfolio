import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_profile.freezed.dart';
part 'agent_profile.g.dart';

@freezed
sealed class AgentProfile with _$AgentProfile {
  const AgentProfile._();

  const factory AgentProfile({
    required String id,
    String? name,
    String? email,
    String? agencyCode,
  }) = _AgentProfile;

  factory AgentProfile.fromJson(Map<String, dynamic> json) =>
      _$AgentProfileFromJson(json);

  String get displayLabel {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) return trimmedEmail;
    return id;
  }

  String? get supportingLabel {
    final primary = displayLabel;
    final trimmedEmail = email?.trim();
    final trimmedCode = agencyCode?.trim();
    final parts = <String>[
      if (trimmedEmail != null &&
          trimmedEmail.isNotEmpty &&
          trimmedEmail != primary)
        trimmedEmail,
      if (trimmedCode != null && trimmedCode.isNotEmpty) trimmedCode,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }
}
