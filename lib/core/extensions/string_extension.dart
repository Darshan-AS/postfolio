import 'package:postfolio/core/constants/app_constants.dart';

extension StringFormatExtension on String {
  /// Formats Aadhaar number by adding a space every 4 digits: "XXXX XXXX XXXX"
  String toAadhaarFormat() {
    final clean = replaceAll(RegExp(r'\s+'), '');
    if (clean.length != AppConstants.aadhaarLength) return this;
    return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
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
}
