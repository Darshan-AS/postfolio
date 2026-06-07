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

  /// The financial year starts in April. 
  /// Returns the start year of the financial year for this date.
  int get financialYearStart {
    return month >= 4 ? year : year - 1;
  }

  /// Returns the financial year label in the format "FY 23-24"
  String get financialYearLabel {
    final start = financialYearStart;
    final end = start + 1;
    final startStr = start.toString().substring(2);
    final endStr = end.toString().substring(2);
    return 'FY $startStr-$endStr';
  }
}
