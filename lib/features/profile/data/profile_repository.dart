import 'package:postfolio/core/constants/supabase_constants.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_repository.g.dart';

abstract class ProfileRepository {
  Future<Result<AgentProfile?, String>> fetchProfile(String userId);

  Future<Result<AgentProfile, String>> updateProfile(AgentProfile profile);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, name, email, agency_code, phone, address, date_of_birth, '
      'post_office_branch, agency_types, mpkby_license_no, mpkby_valid_until, '
      'sas_license_no, sas_valid_until, pan_number, aadhaar_number, '
      'commission_sb_account, notes';

  @override
  Future<Result<AgentProfile?, String>> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from(SupabaseTables.agentProfiles)
          .select(_columns)
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return const Success(null);
      return Success(AgentProfile.fromJson(row));
    } catch (e, st) {
      return Failure(SupabaseErrorMapper.describe(e, stackTrace: st));
    }
  }

  @override
  Future<Result<AgentProfile, String>> updateProfile(
    AgentProfile profile,
  ) async {
    try {
      final row = await _client
          .from(SupabaseTables.agentProfiles)
          .update(profile.toUpdatePayload())
          .eq('id', profile.id)
          .select(_columns)
          .single();
      return Success(AgentProfile.fromJson(row));
    } catch (e, st) {
      return Failure(SupabaseErrorMapper.describe(e, stackTrace: st));
    }
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    AgentProfile? initialProfile,
    this.fetchError,
    this.updateError,
  }) : _profiles = {} {
    if (initialProfile != null) {
      _profiles[initialProfile.id] = initialProfile;
    }
  }

  factory FakeProfileRepository.demo({DateTime? today}) {
    final anchor = today ?? DateTime.now();
    final baseDate = DateTime(anchor.year, anchor.month, anchor.day);
    return FakeProfileRepository(
      initialProfile: AgentProfile(
        id: 'demo_user',
        name: 'Jim Gordon',
        email: 'agent@demo.com',
        agencyCode: 'DOP-GTM-001',
        phone: '9876543210',
        address: '14 Precinct Plaza, Gotham City',
        dateOfBirth: DateTime(1972, 11, 14),
        postOfficeBranch: 'Gotham Central HPO',
        agencyTypes: const [AgencyType.mpkby, AgencyType.sas],
        mpkbyLicenseNo: 'MPKBY/MH/2021/4812',
        mpkbyValidUntil: baseDate.add(const Duration(days: 140)),
        sasLicenseNo: 'SAS/MH/2020/1194',
        sasValidUntil: baseDate.add(const Duration(days: 30)),
        panNumber: 'ABCPG1234K',
        aadhaarNumber: '482910482910',
        commissionSbAccount: '0100090042',
        notes: 'Counter #3 window hours 10:00–13:30; SAS renewal due Dec.',
      ),
    );
  }

  final Map<String, AgentProfile> _profiles;
  String? fetchError;
  String? updateError;

  @override
  Future<Result<AgentProfile?, String>> fetchProfile(String userId) async {
    if (fetchError != null) return Failure(fetchError!);
    return Success(_profiles[userId]);
  }

  @override
  Future<Result<AgentProfile, String>> updateProfile(
    AgentProfile profile,
  ) async {
    if (updateError != null) return Failure(updateError!);
    _profiles[profile.id] = profile;
    return Success(profile);
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    ref.watch(demoSessionEpochProvider);
    final today = ref.watch(currentDateProvider);
    return FakeProfileRepository.demo(today: today);
  }
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
}
