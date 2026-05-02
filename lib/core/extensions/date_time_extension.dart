import 'package:intl/intl.dart';
import 'package:postfolio/i18n/strings.g.dart';

extension DateTimeFormatting on DateTime {
  /// Returns date formatted according to slang's `format.date` key
  String toAppFormat() {
    final locale = LocaleSettings.currentLocale.languageTag;
    return DateFormat(t.format.date, locale).format(this);
  }

  /// Returns date formatted according to slang's `format.dateCompact` key
  String toCompactFormat() {
    final locale = LocaleSettings.currentLocale.languageTag;
    return DateFormat(t.format.dateCompact, locale).format(this);
  }

  /// Returns date formatted according to slang's `format.dateTime` key
  String toDateTimeFormat() {
    final locale = LocaleSettings.currentLocale.languageTag;
    return DateFormat(t.format.dateTime, locale).format(this);
  }
}
