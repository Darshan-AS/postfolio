class AppConstants {
  static const String webClientId = String.fromEnvironment(
    'WEB_CLIENT_ID',
    defaultValue:
        '143378829514-84as322oeajpt990vu2fil56lvs4l9b7.apps.googleusercontent.com',
  );

  // Date Picker
  static const int firstDatePickerYear = 1900;
  static const int lastDatePickerYear = 2100;
  static const int firstStartYear = 2000;

  // Form
  static const int addressMaxLines = 3;

  // Currency
  static const String defaultLocale = 'en_IN';
}
