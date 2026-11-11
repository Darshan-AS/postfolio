import 'package:freezed_annotation/freezed_annotation.dart';

/// Zero-cost local calendar date value type (`yyyy-MM-dd`, midnight local, no time-of-day).
///
/// Prevents timezone-offset day shifts (`2026-04-01T02:15:00+05:30` -> `2026-04-01`) and
/// calendar month-end overflows (`2024-02-29 + 12M` -> `2025-02-28`).
extension type const LocalDate._(DateTime _value) {
  factory LocalDate(int year, [int month = 1, int day = 1]) =>
      LocalDate._(DateTime(year, month, day));

  factory LocalDate.fromDateTime(DateTime dt) =>
      LocalDate._(DateTime(dt.year, dt.month, dt.day));

  /// Extracts the calendar date directly from an ISO-8601 `YYYY-MM-DD...` prefix when present
  /// so explicit timezone offsets never shift the calendar day via UTC conversion.
  factory LocalDate.parse(String input) {
    final trimmed = input.trim();
    final match = _isoDatePrefix.firstExpMatch(trimmed);
    if (match != null) {
      return LocalDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    final parsed = DateTime.parse(trimmed);
    return LocalDate(parsed.year, parsed.month, parsed.day);
  }

  int get year => _value.year;
  int get month => _value.month;
  int get day => _value.day;

  DateTime toDateTime() => _value;

  String toIsoDateString() => _value.toDateOnlyString();

  /// Adds [months] calendar months, clamping to the last day of the target month so
  /// `Jan 31 + 1M == Feb 28/29` and `Feb 29 + 12M == Feb 28`.
  LocalDate addMonths(int months) {
    final totalMonths = (year * 12) + (month - 1) + months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;
    final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = day > maxDays ? maxDays : day;
    return LocalDate(targetYear, targetMonth, targetDay);
  }

  LocalDate addYears(int years) => addMonths(years * 12);

  bool isBefore(LocalDate other) => _value.isBefore(other._value);
  bool isAfter(LocalDate other) => _value.isAfter(other._value);

  int compareTo(LocalDate other) => _value.compareTo(other._value);
}

final RegExp _isoDatePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

extension _RegExpFirstMatch on RegExp {
  RegExpMatch? firstExpMatch(String input) => firstMatch(input);
}

/// Serializes a calendar day (no time-of-day) as `yyyy-MM-dd` for Postgres `DATE` columns.
class DateOnlyConverter implements JsonConverter<DateTime, Object?> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is String) {
      return LocalDate.parse(json).toDateTime();
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

  /// Wraps this [DateTime] as a [LocalDate] at local midnight.
  LocalDate toLocalDate() => LocalDate.fromDateTime(this);

  /// `yyyy-MM-dd` without any locale or time component.
  String toDateOnlyString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// First day of this calendar month.
  DateTime toMonthStart() => DateTime(year, month);

  /// Calendar-month index usable as a map key (year * 12 + month).
  int get monthKey => year * 12 + month;
}
