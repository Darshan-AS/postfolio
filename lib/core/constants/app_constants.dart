class AppConstants {
  // Business Rules
  static const double maxPercentage = 100.0;
  static const double maxInterestRate = 100.0;
  static const int maturingSoonThresholdDays = 30;

  // Validation Rules
  static const int minNameLength = 2;
  static const int minCifLength = 9;
  static const int phoneMinLength = 7;
  static const int phoneMaxLength = 15;
  static const int aadhaarLength = 12;

  // Date Picker
  static const int firstDatePickerYear = 1900;
  static const int lastDatePickerYear = 2100;
  static const int firstStartYear = 2000;

  // Form & Formatting
  static const int addressMaxLines = 3;
  static const int notesMinLines = 2;
  static const int notesMaxLines = 4;
  static const int maskedIdVisibleTrailingCount = 4;
  static const String maskCharacter = 'X';
  static const String aadhaarMaskedPrefix = 'XXXX XXXX ';
  static const int formatPhoneStandardLength = 10;
  static const int formatPhoneWithCountryCodeLength = 12;
  static const String formatPhoneCountryCode = '91';

  // Assets & Routing
  static const String appLogoMarkAsset = 'assets/branding/app_logo_mark.png';
  static const String selfHeroId = 'self';

  // Currency
  static const String defaultLocale = 'en_IN';
}
