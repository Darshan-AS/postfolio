class AppConstants {
  static const String webClientId = String.fromEnvironment(
    'WEB_CLIENT_ID',
    defaultValue:
        '143378829514-84as322oeajpt990vu2fil56lvs4l9b7.apps.googleusercontent.com',
  );

  // Business Rules
  static const double maxPercentage = 100.0;
  static const double maxInterestRate = 100.0;
  static const int maturingSoonThresholdDays = 30;

  // Validation Rules
  static const int minNameLength = 2;
  static const int minCifLength = 9;
  static const int phoneMinLength = 7;
  static const int phoneMaxLength = 15;
  static const int firestoreBatchLimit = 400;
  static const int defaultMigrationBatchSize = 10;
  static const int aadhaarLength = 12;

  // Date Picker
  static const int firstDatePickerYear = 1900;
  static const int lastDatePickerYear = 2100;
  static const int firstStartYear = 2000;

  // Form & Formatting
  static const int addressMaxLines = 3;
  static const int formatPhoneStandardLength = 10;
  static const int formatPhoneWithCountryCodeLength = 12;
  static const String formatPhoneCountryCode = '91';

  // Currency
  static const String defaultLocale = 'en_IN';
}
