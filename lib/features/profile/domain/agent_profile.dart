import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/identity_validators.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'agent_profile.freezed.dart';
part 'agent_profile.g.dart';

enum LicenseValidityStatus { valid, expiringSoon, expired }

@freezed
sealed class AgentProfile with _$AgentProfile {
  const AgentProfile._();

  static const int licenseExpiringSoonDays = 60;

  const factory AgentProfile({
    required String id,
    String? name,
    String? email,
    String? agencyCode,
    String? phone,
    String? address,
    @NullableDateOnlyConverter() DateTime? dateOfBirth,
    String? postOfficeBranch,
    @Default(<AgencyType>[]) List<AgencyType> agencyTypes,
    String? mpkbyLicenseNo,
    @NullableDateOnlyConverter() DateTime? mpkbyValidUntil,
    String? sasLicenseNo,
    @NullableDateOnlyConverter() DateTime? sasValidUntil,
    String? panNumber,
    String? aadhaarNumber,
    String? commissionSbAccount,
    String? notes,
  }) = _AgentProfile;

  factory AgentProfile.fromJson(Map<String, dynamic> json) =>
      _$AgentProfileFromJson(json);

  /// Resolves the UI-facing profile by falling back to signed-in [authUser] identity
  /// when no fetched row exists yet.
  static AgentProfile effectiveFrom(
    AgentProfile? profile,
    AuthUser? authUser,
  ) =>
      profile ??
      AgentProfile(
        id: authUser?.id ?? '',
        name: authUser?.displayName,
        email: authUser?.email,
      );

  static int? licenseDaysRemainingAt(DateTime? validUntil, DateTime now) {
    if (validUntil == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(validUntil.year, validUntil.month, validUntil.day);
    return expiry.difference(today).inDays;
  }

  static LicenseValidityStatus? licenseStatusAt(
    DateTime? validUntil,
    DateTime now,
  ) {
    final daysRemaining = licenseDaysRemainingAt(validUntil, now);
    if (daysRemaining == null) return null;
    if (daysRemaining < 0) return LicenseValidityStatus.expired;
    if (daysRemaining <= licenseExpiringSoonDays) {
      return LicenseValidityStatus.expiringSoon;
    }
    return LicenseValidityStatus.valid;
  }

  static String? validateName(String? value) =>
      IdentityValidators.validateRequiredName(
        value,
        fieldLabel: t.settings.profileFields.displayName,
      );

  static String? validatePhone(String? value) =>
      IdentityValidators.validateOptionalPhone(value);

  static String? validateAadhaar(String? value) =>
      IdentityValidators.validateOptionalAadhaar(value);

  static String? validatePan(String? value) =>
      IdentityValidators.validateOptionalPan(value);

  /// Validates all editable profile invariants before saving.
  String? validate() =>
      validateName(name) ??
      validatePhone(phone) ??
      validatePan(panNumber) ??
      validateAadhaar(aadhaarNumber);

  /// Returns a canonical copy ready for persistence: trimmed optional strings,
  /// date-only timestamps, uppercase PAN, stripped Aadhaar, and sorted [agencyTypes].
  AgentProfile normalized() => copyWith(
    name: name!.trim(),
    agencyCode: IdentityValidators.normalizeOptionalText(agencyCode),
    phone: IdentityValidators.normalizeOptionalText(phone),
    address: IdentityValidators.normalizeOptionalText(address),
    dateOfBirth: IdentityValidators.normalizeDateOnly(dateOfBirth),
    postOfficeBranch: IdentityValidators.normalizeOptionalText(
      postOfficeBranch,
    ),
    agencyTypes: AgencyType.values.where(agencyTypes.contains).toList(),
    mpkbyLicenseNo: IdentityValidators.normalizeOptionalText(mpkbyLicenseNo),
    mpkbyValidUntil: IdentityValidators.normalizeDateOnly(mpkbyValidUntil),
    sasLicenseNo: IdentityValidators.normalizeOptionalText(sasLicenseNo),
    sasValidUntil: IdentityValidators.normalizeDateOnly(sasValidUntil),
    panNumber: IdentityValidators.normalizePan(panNumber),
    aadhaarNumber: IdentityValidators.normalizeAadhaar(aadhaarNumber),
    commissionSbAccount: IdentityValidators.normalizeOptionalText(
      commissionSbAccount,
    ),
    notes: IdentityValidators.normalizeOptionalText(notes),
  );

  /// Mutable DB column map generated via `toJson()` so enums and dates stay aligned
  /// with Freezed/JsonSerializable converters.
  Map<String, dynamic> toUpdatePayload() {
    final json = toJson();
    json.remove('id');
    json.remove('email');
    return json;
  }

  String resolveDisplayName({AuthUser? fallbackUser, String? emptyFallback}) {
    final candidates = [
      name?.trim(),
      fallbackUser?.displayName?.trim(),
      email?.trim(),
      fallbackUser?.email?.trim(),
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return emptyFallback ?? t.common.notProvided;
  }

  String resolveInitial({AuthUser? fallbackUser}) {
    final resolved = resolveDisplayName(
      fallbackUser: fallbackUser,
      emptyFallback: 'A',
    );
    return resolved.isNotEmpty ? resolved[0].toUpperCase() : 'A';
  }

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

  String? get agencySummaryLabel {
    final parts = <String>[
      if (_hasText(agencyCode)) agencyCode!.trim(),
      if (_hasText(postOfficeBranch)) postOfficeBranch!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  bool get hasMpkby => agencyTypes.contains(AgencyType.mpkby);

  bool get hasSas => agencyTypes.contains(AgencyType.sas);

  bool get hasSharedAgencyDetails =>
      _hasText(agencyCode) || _hasText(postOfficeBranch);

  bool get hasMpkbyLicenseDetails =>
      _hasText(mpkbyLicenseNo) || mpkbyValidUntil != null;

  bool get hasSasLicenseDetails =>
      _hasText(sasLicenseNo) || sasValidUntil != null;

  bool get hasLicenses => hasMpkbyLicenseDetails || hasSasLicenseDetails;

  bool get hasKycOrCommissionDetails =>
      _hasText(panNumber) ||
      _hasText(aadhaarNumber) ||
      _hasText(commissionSbAccount);

  static bool _hasText(String? s) => s != null && s.trim().isNotEmpty;
}
