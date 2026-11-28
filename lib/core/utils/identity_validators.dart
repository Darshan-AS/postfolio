import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Shared validation and normalization helpers for Indian identity & contact fields.
abstract final class IdentityValidators {
  static final RegExp _phoneRegex = RegExp(
    '^\\+?[0-9]{${AppConstants.phoneMinLength},${AppConstants.phoneMaxLength}}\$',
  );
  static final RegExp _aadhaarRegex = RegExp(
    '^\\d{${AppConstants.aadhaarLength}}\$',
  );
  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  static String? validateRequiredName(
    String? value, {
    required String fieldLabel,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return t.errors.requiredField(field: fieldLabel);
    }
    if (trimmed.length < AppConstants.minNameLength) {
      return t.errors.minLength(
        field: fieldLabel,
        count: AppConstants.minNameLength,
      );
    }
    return null;
  }

  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_phoneRegex.hasMatch(normalized)) return t.errors.invalidPhone;
    return null;
  }

  static String? validateOptionalAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.replaceAll(RegExp(r'\s+'), '');
    if (!_aadhaarRegex.hasMatch(clean)) return t.errors.invalidAadhaar;
    return null;
  }

  static String? validateOptionalPan(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.trim().toUpperCase();
    if (!_panRegex.hasMatch(clean)) return t.errors.invalidPan;
    return null;
  }

  static String? normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String? normalizePan(String? value) =>
      normalizeOptionalText(value)?.toUpperCase();

  static String? normalizeAadhaar(String? value) =>
      normalizeOptionalText(value)?.replaceAll(RegExp(r'\s+'), '');

  static DateTime? normalizeDateOnly(DateTime? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);
}
