import 'package:freezed_annotation/freezed_annotation.dart';

/// Serializes a calendar day (no time-of-day) as `yyyy-MM-dd` for Postgres `DATE` columns.
///
/// Ledger facts are calendar days: a payment is made "on the 15th", never "at 10:32 on the 15th".
/// Keeping the time component out of the model removes an entire class of due-date comparison bugs.
class DateOnlyConverter implements JsonConverter<DateTime, Object?> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is String) {
      final parsed = DateTime.parse(json);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    if (json is int) {
      final parsed = DateTime.fromMillisecondsSinceEpoch(json);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    throw FormatException('Expected ISO date string for DateOnlyConverter, got $json');
  }

  @override
  Object toJson(DateTime date) => date.toDateOnlyString();
}

/// Nullable variant of [DateOnlyConverter].
class NullableDateOnlyConverter implements JsonConverter<DateTime?, Object?> {
  const NullableDateOnlyConverter();

  @override
  DateTime? fromJson(Object? json) =>
      json == null ? null : const DateOnlyConverter().fromJson(json);

  @override
  Object? toJson(DateTime? date) =>
      date == null ? null : const DateOnlyConverter().toJson(date);
}

extension DateOnlyX on DateTime {
  /// Truncates to local midnight so comparisons are calendar-day comparisons.
  DateTime toDateOnly() => DateTime(year, month, day);

  /// `yyyy-MM-dd` without any locale or time component.
  String toDateOnlyString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  /// First day of this calendar month.
  DateTime toMonthStart() => DateTime(year, month);

  /// Calendar-month index usable as a map key (year * 12 + month).
  int get monthKey => year * 12 + month;
}
