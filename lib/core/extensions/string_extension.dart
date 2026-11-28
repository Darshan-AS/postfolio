import 'package:postfolio/core/constants/app_constants.dart';

extension StringFormatExtension on String {
  /// Formats Aadhaar number by adding a space every 4 digits: "XXXX XXXX XXXX"
  String toAadhaarFormat() {
    final clean = replaceAll(RegExp(r'\s+'), '');
    if (clean.length != AppConstants.aadhaarLength) return this;
    const chunk = AppConstants.maskedIdVisibleTrailingCount;
    return '${clean.substring(0, chunk)} ${clean.substring(chunk, chunk * 2)} ${clean.substring(chunk * 2, chunk * 3)}';
  }

  /// Masks Aadhaar number keeping only the last 4 digits visible: "XXXX XXXX 1234"
  String toMaskedAadhaarFormat() {
    final clean = replaceAll(RegExp(r'\s+'), '');
    const trailing = AppConstants.maskedIdVisibleTrailingCount;
    if (clean.length == AppConstants.aadhaarLength) {
      return '${AppConstants.aadhaarMaskedPrefix}${clean.substring(clean.length - trailing)}';
    }
    if (clean.length > trailing) {
      return '${AppConstants.maskCharacter * (clean.length - trailing)}${clean.substring(clean.length - trailing)}';
    }
    return this;
  }

  /// Formats phone number consistently into "+91 XXXXX XXXXX"
  /// Handles inputs with/without '+', with/without '91', and arbitrary spaces.
  String toPhoneFormat() {
    // Extract only digits
    final digits = replaceAll(RegExp(r'\D'), '');

    String coreNumber;

    if (digits.length == AppConstants.formatPhoneStandardLength) {
      // User entered 10 digits without country code
      coreNumber = digits;
    } else if (digits.length == AppConstants.formatPhoneWithCountryCodeLength &&
        digits.startsWith(AppConstants.formatPhoneCountryCode)) {
      // User entered 12 digits with country code (e.g., 919876543210)
      coreNumber = digits.substring(AppConstants.formatPhoneCountryCode.length);
    } else {
      // Not a standard 10-digit Indian number, return original
      return this;
    }

    return '+${AppConstants.formatPhoneCountryCode} ${coreNumber.substring(0, 5)} ${coreNumber.substring(5, 10)}';
  }

  /// Formats PAN number by converting to uppercase
  String toPanFormat() {
    return toUpperCase();
  }

  /// Masks PAN number keeping only the last 4 characters visible: "XXXXXX123F"
  String toMaskedPanFormat() {
    final clean = trim().toUpperCase();
    const trailing = AppConstants.maskedIdVisibleTrailingCount;
    if (clean.length > trailing) {
      return '${AppConstants.maskCharacter * (clean.length - trailing)}${clean.substring(clean.length - trailing)}';
    }
    return clean;
  }
}
