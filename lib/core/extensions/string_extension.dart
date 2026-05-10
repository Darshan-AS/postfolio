extension StringFormatExtension on String {
  /// Formats Aadhaar number by adding a space every 4 digits: "XXXX XXXX XXXX"
  String toAadhaarFormat() {
    final clean = replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 12) return this;
    return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
  }

  /// Formats phone number into "+91 XXXXX XXXXX"
  String toPhoneFormat() {
    final clean = replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('+91') && clean.length == 13) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 8)} ${clean.substring(8)}';
    }
    return this;
  }

  /// Formats PAN number by converting to uppercase
  String toPanFormat() {
    return toUpperCase();
  }
}
