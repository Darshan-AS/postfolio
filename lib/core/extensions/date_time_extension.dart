import 'package:intl/intl.dart';
import 'package:postfolio/i18n/strings.g.dart';

String resolvedDateLocale() {
  final locale = LocaleSettings.currentLocale.languageTag;
  try {
    return DateFormat.localeExists(locale) ? locale : 'en_US';
  } catch (_) {
    return 'en_US';
  }
}

extension DateTimeFormatting on DateTime {
  /// Returns date formatted according to slang's `format.date` key
  String toAppFormat() {
    return DateFormat(t.format.date, resolvedDateLocale()).format(this);
  }

  /// Returns date formatted according to slang's `format.dateCompact` key
  String toCompactFormat() {
    return DateFormat(t.format.dateCompact, resolvedDateLocale()).format(this);
  }

  /// Returns date formatted according to slang's `format.dateTime` key
  String toDateTimeFormat() {
    return DateFormat(t.format.dateTime, resolvedDateLocale()).format(this);
  }

  /// Returns month and year formatted e.g. "September 2026"
  String toMonthYearFormat() {
    return DateFormat.yMMMM(resolvedDateLocale()).format(this);
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
