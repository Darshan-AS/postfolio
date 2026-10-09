import 'dart:math';

import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/postal_scheme_terms.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'postal_rate_service.g.dart';

typedef _CircularRatePeriod = ({
  DateTime effectiveFrom,
  DateTime? effectiveTo,
  double? rdRate,
  double? td1YearRate,
  double? td2YearRate,
  double? td3YearRate,
  double? td5YearRate,
  double? misRate,
  double? nscRate,
  double kvpRate,
  int kvpTermYears,
  int kvpTermMonths,
});

/// Official Department of Posts (India Post) / Ministry of Finance historical
/// interest rate and tenure service across all supported schemes.
class PostalRateService {
  const PostalRateService();

  static const int _monthsInYear = 12;
  static const double _percentageDivisor = 100.0;
  static const double _rateMatchEpsilon = 0.001;

  /// Official Ministry of Finance notified KVP doubling tenures (in months)
  /// mapped by notified annual interest rate (%).
  ///
  /// Because published KVP rates are rounded to 1 decimal place (e.g., 7.6%
  /// instead of 7.6385% for 113 months), pure logarithmic calculation
  /// `12 * ln(2) / ln(1 + r)` can drift by +1 month on boundary rates.
  static const List<({double rate, int months})> _officialKvpRateToMonths = [
    (rate: 11.25, months: 78), // 6 Years 6 Months
    (rate: 10.25, months: 87), // 7 Years 3 Months
    (rate: 9.5, months: 92), // 7 Years 8 Months
    (rate: 8.7, months: 100), // 8 Years 4 Months
    (rate: 8.4, months: 103), // 8 Years 7 Months
    (rate: 7.8, months: 110), // 9 Years 2 Months
    (rate: 7.7, months: 112), // 9 Years 4 Months
    (rate: 7.6, months: 113), // 9 Years 5 Months
    (rate: 7.5, months: 115), // 9 Years 7 Months
    (rate: 7.3, months: 118), // 9 Years 10 Months
    (rate: 7.2, months: 120), // 10 Years 0 Months
    (rate: 7.0, months: 123), // 10 Years 3 Months
    (rate: 6.9, months: 124), // 10 Years 4 Months
  ];

  static final List<_CircularRatePeriod> _periods = [
    (
      effectiveFrom: DateTime(2024, 1, 1),
      effectiveTo: null,
      rdRate: 6.7,
      td1YearRate: 6.9,
      td2YearRate: 7.0,
      td3YearRate: 7.1,
      td5YearRate: 7.5,
      misRate: 7.4,
      nscRate: 7.7,
      kvpRate: 7.5,
      kvpTermYears: 9,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2023, 10, 1),
      effectiveTo: DateTime(2023, 12, 31),
      rdRate: 6.7,
      td1YearRate: 6.9,
      td2YearRate: 7.0,
      td3YearRate: 7.0,
      td5YearRate: 7.5,
      misRate: 7.4,
      nscRate: 7.7,
      kvpRate: 7.5,
      kvpTermYears: 9,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2023, 7, 1),
      effectiveTo: DateTime(2023, 9, 30),
      rdRate: 6.5,
      td1YearRate: 6.9,
      td2YearRate: 7.0,
      td3YearRate: 7.0,
      td5YearRate: 7.5,
      misRate: 7.4,
      nscRate: 7.7,
      kvpRate: 7.5,
      kvpTermYears: 9,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2023, 4, 1),
      effectiveTo: DateTime(2023, 6, 30),
      rdRate: 6.2,
      td1YearRate: 6.8,
      td2YearRate: 6.9,
      td3YearRate: 7.0,
      td5YearRate: 7.5,
      misRate: 7.4,
      nscRate: 7.7,
      kvpRate: 7.5,
      kvpTermYears: 9,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2023, 1, 1),
      effectiveTo: DateTime(2023, 3, 31),
      rdRate: 5.8,
      td1YearRate: 6.6,
      td2YearRate: 6.8,
      td3YearRate: 6.9,
      td5YearRate: 7.0,
      misRate: 7.1,
      nscRate: 7.0,
      kvpRate: 7.2,
      kvpTermYears: 10,
      kvpTermMonths: 0,
    ),
    (
      effectiveFrom: DateTime(2022, 10, 1),
      effectiveTo: DateTime(2022, 12, 31),
      rdRate: 5.8,
      td1YearRate: 5.5,
      td2YearRate: 5.7,
      td3YearRate: 5.8,
      td5YearRate: 6.7,
      misRate: 6.7,
      nscRate: 6.8,
      kvpRate: 7.0,
      kvpTermYears: 10,
      kvpTermMonths: 3,
    ),
    (
      effectiveFrom: DateTime(2020, 4, 1),
      effectiveTo: DateTime(2022, 9, 30),
      rdRate: 5.8,
      td1YearRate: 5.5,
      td2YearRate: 5.5,
      td3YearRate: 5.5,
      td5YearRate: 6.7,
      misRate: 6.6,
      nscRate: 6.8,
      kvpRate: 6.9,
      kvpTermYears: 10,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2019, 7, 1),
      effectiveTo: DateTime(2020, 3, 31),
      rdRate: 7.2,
      td1YearRate: 6.9,
      td2YearRate: 6.9,
      td3YearRate: 6.9,
      td5YearRate: 7.7,
      misRate: 7.6,
      nscRate: 7.9,
      kvpRate: 7.6,
      kvpTermYears: 9,
      kvpTermMonths: 5,
    ),
    (
      effectiveFrom: DateTime(2019, 1, 1),
      effectiveTo: DateTime(2019, 6, 30),
      rdRate: 7.3,
      td1YearRate: 7.0,
      td2YearRate: 7.0,
      td3YearRate: 7.0,
      td5YearRate: 7.8,
      misRate: 7.7,
      nscRate: 8.0,
      kvpRate: 7.7,
      kvpTermYears: 9,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2018, 10, 1),
      effectiveTo: DateTime(2018, 12, 31),
      rdRate: 7.3,
      td1YearRate: 6.9,
      td2YearRate: 7.0,
      td3YearRate: 7.2,
      td5YearRate: 7.8,
      misRate: 7.7,
      nscRate: 8.0,
      kvpRate: 7.7,
      kvpTermYears: 9,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2018, 1, 1),
      effectiveTo: DateTime(2018, 9, 30),
      rdRate: 6.9,
      td1YearRate: 6.6,
      td2YearRate: 6.7,
      td3YearRate: 6.9,
      td5YearRate: 7.4,
      misRate: 7.3,
      nscRate: 7.6,
      kvpRate: 7.3,
      kvpTermYears: 9,
      kvpTermMonths: 10,
    ),
    (
      effectiveFrom: DateTime(2017, 7, 1),
      effectiveTo: DateTime(2017, 12, 31),
      rdRate: 7.1,
      td1YearRate: 6.8,
      td2YearRate: 6.9,
      td3YearRate: 7.1,
      td5YearRate: 7.6,
      misRate: 7.5,
      nscRate: 7.8,
      kvpRate: 7.5,
      kvpTermYears: 9,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2017, 4, 1),
      effectiveTo: DateTime(2017, 6, 30),
      rdRate: 7.2,
      td1YearRate: 6.9,
      td2YearRate: 7.0,
      td3YearRate: 7.2,
      td5YearRate: 7.7,
      misRate: 7.6,
      nscRate: 7.9,
      kvpRate: 7.6,
      kvpTermYears: 9,
      kvpTermMonths: 5,
    ),
    (
      effectiveFrom: DateTime(2016, 10, 1),
      effectiveTo: DateTime(2017, 3, 31),
      rdRate: 7.3,
      td1YearRate: 7.0,
      td2YearRate: 7.1,
      td3YearRate: 7.3,
      td5YearRate: 7.8,
      misRate: 7.7,
      nscRate: 8.0,
      kvpRate: 7.7,
      kvpTermYears: 9,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2016, 4, 1),
      effectiveTo: DateTime(2016, 9, 30),
      rdRate: 7.4,
      td1YearRate: 7.1,
      td2YearRate: 7.2,
      td3YearRate: 7.4,
      td5YearRate: 7.9,
      misRate: 7.8,
      nscRate: 8.1,
      kvpRate: 7.8,
      kvpTermYears: 9,
      kvpTermMonths: 2,
    ),
    (
      effectiveFrom: DateTime(2014, 4, 1),
      effectiveTo: DateTime(2016, 3, 31),
      rdRate: 8.4,
      td1YearRate: 8.4,
      td2YearRate: 8.4,
      td3YearRate: 8.4,
      td5YearRate: 8.5,
      misRate: 8.4,
      nscRate: 8.5,
      kvpRate: 8.7,
      kvpTermYears: 8,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2013, 4, 1),
      effectiveTo: DateTime(2014, 3, 31),
      rdRate: 8.3,
      td1YearRate: 8.2,
      td2YearRate: 8.2,
      td3YearRate: 8.3,
      td5YearRate: 8.4,
      misRate: 8.4,
      nscRate: 8.5,
      kvpRate: 8.7,
      kvpTermYears: 8,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2012, 4, 1),
      effectiveTo: DateTime(2013, 3, 31),
      rdRate: 8.3,
      td1YearRate: 8.2,
      td2YearRate: 8.3,
      td3YearRate: 8.4,
      td5YearRate: 8.5,
      misRate: 8.5,
      nscRate: 8.6,
      kvpRate: 8.7,
      kvpTermYears: 8,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2011, 12, 1),
      effectiveTo: DateTime(2012, 3, 31),
      rdRate: 8.0,
      td1YearRate: 7.7,
      td2YearRate: 7.8,
      td3YearRate: 8.0,
      td5YearRate: 8.3,
      misRate: 8.2,
      nscRate: 8.4,
      kvpRate: 8.7,
      kvpTermYears: 8,
      kvpTermMonths: 4,
    ),
    (
      effectiveFrom: DateTime(2003, 3, 1),
      effectiveTo: DateTime(2011, 11, 30),
      rdRate: 7.5,
      td1YearRate: 6.25,
      td2YearRate: 6.5,
      td3YearRate: 7.25,
      td5YearRate: 7.5,
      misRate: 8.0,
      nscRate: 8.0,
      kvpRate: 8.4,
      kvpTermYears: 8,
      kvpTermMonths: 7,
    ),
    (
      effectiveFrom: DateTime(2002, 3, 1),
      effectiveTo: DateTime(2003, 2, 28),
      rdRate: 7.5,
      td1YearRate: 6.25,
      td2YearRate: 6.5,
      td3YearRate: 7.25,
      td5YearRate: 7.5,
      misRate: 8.0,
      nscRate: 8.0,
      kvpRate: 9.5,
      kvpTermYears: 7,
      kvpTermMonths: 8,
    ),
    (
      effectiveFrom: DateTime(2001, 3, 1),
      effectiveTo: DateTime(2002, 2, 28),
      rdRate: 7.5,
      td1YearRate: 6.25,
      td2YearRate: 6.5,
      td3YearRate: 7.25,
      td5YearRate: 7.5,
      misRate: 8.0,
      nscRate: 8.0,
      kvpRate: 10.25,
      kvpTermYears: 7,
      kvpTermMonths: 3,
    ),
    (
      effectiveFrom: DateTime(2000, 1, 1),
      effectiveTo: DateTime(2001, 2, 28),
      rdRate: 7.5,
      td1YearRate: 6.25,
      td2YearRate: 6.5,
      td3YearRate: 7.25,
      td5YearRate: 7.5,
      misRate: 8.0,
      nscRate: 8.0,
      kvpRate: 11.25,
      kvpTermYears: 6,
      kvpTermMonths: 6,
    ),
  ];

  static bool _containsDate(_CircularRatePeriod period, DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final afterStart = !normalized.isBefore(period.effectiveFrom);
    final beforeEnd =
        period.effectiveTo == null || !normalized.isAfter(period.effectiveTo!);
    return afterStart && beforeEnd;
  }

  static _CircularRatePeriod _resolvePeriod(DateTime startDate) {
    for (final period in _periods) {
      if (_containsDate(period, startDate)) {
        return period;
      }
    }
    final normalized = DateTime(startDate.year, startDate.month, startDate.day);
    if (normalized.isBefore(_periods.last.effectiveFrom)) {
      return _periods.last;
    }
    return _periods.first;
  }

  /// Resolves the official interest rate and tenure for a One-Time Deposit
  /// scheme on [startDate].
  PostalSchemeTerms resolveOneTimeSchemeTerms({
    required OneTimeSchemeType schemeType,
    required DateTime startDate,
    int? tdTenureYears,
  }) {
    final period = _resolvePeriod(startDate);

    return switch (schemeType) {
      OneTimeSchemeType.timeDeposit => _resolveTimeDeposit(
        period,
        tdTenureYears ?? OneTimeSchemeType.timeDeposit.defaultTenureYears,
      ),
      OneTimeSchemeType.monthlyIncomeScheme => PostalSchemeTerms(
        interestRate: period.misRate ?? _periods.first.misRate!,
        termYears: OneTimeSchemeType.monthlyIncomeScheme.defaultTenureYears,
      ),
      OneTimeSchemeType.nationalSavingsCertificate => PostalSchemeTerms(
        interestRate: period.nscRate ?? _periods.first.nscRate!,
        termYears:
            OneTimeSchemeType.nationalSavingsCertificate.defaultTenureYears,
      ),
      OneTimeSchemeType.kisanVikasPatra => PostalSchemeTerms(
        interestRate: period.kvpRate,
        termYears: period.kvpTermYears,
        termMonths: period.kvpTermMonths,
      ),
    };
  }

  static PostalSchemeTerms _resolveTimeDeposit(
    _CircularRatePeriod period,
    int tenureYears,
  ) {
    final normalizedYears =
        OneTimeSchemeType.timeDeposit.allowedTenuresInYears.contains(
          tenureYears,
        )
        ? tenureYears
        : OneTimeSchemeType.timeDeposit.defaultTenureYears;

    final rate = switch (normalizedYears) {
      1 => period.td1YearRate ?? _periods.first.td1YearRate!,
      2 => period.td2YearRate ?? _periods.first.td2YearRate!,
      3 => period.td3YearRate ?? _periods.first.td3YearRate!,
      5 => period.td5YearRate ?? _periods.first.td5YearRate!,
      _ => period.td5YearRate ?? _periods.first.td5YearRate!,
    };
    return PostalSchemeTerms(interestRate: rate, termYears: normalizedYears);
  }

  /// Resolves the official interest rate and tenure for a Recurring Deposit
  /// scheme on [startDate].
  PostalSchemeTerms resolveRecurringSchemeTerms({
    required RecurringSchemeType schemeType,
    required DateTime startDate,
  }) {
    final period = _resolvePeriod(startDate);

    return switch (schemeType) {
      RecurringSchemeType.recurringDeposit => PostalSchemeTerms(
        interestRate: period.rdRate ?? _periods.first.rdRate!,
        termYears: RecurringSchemeType.recurringDeposit.defaultTenureYears,
      ),
    };
  }

  /// Resolves the official KVP doubling duration in months for [interestRate].
  ///
  /// 1. If [startDate] is provided and its circular period's KVP rate matches
  ///    [interestRate], returns the circular's exact notified tenure.
  /// 2. Otherwise checks the official Post Office rate-to-months lookup table.
  /// 3. Falls back to the compound interest doubling formula for custom rates.
  int calculateKvpTermMonths(
    double interestRate, {
    DateTime? startDate,
  }) {
    if (interestRate <= 0) {
      if (startDate != null) {
        final period = _resolvePeriod(startDate);
        return (period.kvpTermYears * _monthsInYear) + period.kvpTermMonths;
      }
      return 0;
    }

    if (startDate != null) {
      final period = _resolvePeriod(startDate);
      if ((period.kvpRate - interestRate).abs() < _rateMatchEpsilon) {
        return (period.kvpTermYears * _monthsInYear) + period.kvpTermMonths;
      }
    }

    for (final entry in _officialKvpRateToMonths) {
      if ((entry.rate - interestRate).abs() < _rateMatchEpsilon) {
        return entry.months;
      }
    }

    final decimalInterestRate = interestRate / _percentageDivisor;
    final timeInYears = log(2) / log(1 + decimalInterestRate);
    return (timeInYears * _monthsInYear).round();
  }
}

@riverpod
PostalRateService postalRateService(Ref ref) {
  return const PostalRateService();
}
