import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'dashboard_models.freezed.dart';

@freezed
sealed class DashboardMetrics with _$DashboardMetrics {
  const factory DashboardMetrics({
    required int totalCustomers,
    required int activeCustomers,
    required int totalRds,
    required int activeRds,
    required int totalOtds,
    required int activeOtds,
    required Map<OneTimeSchemeType, int> activeOtdsByScheme,
    required Map<OneTimeSchemeType, int> totalOtdsByScheme,
  }) = _DashboardMetrics;
}

@freezed
sealed class ChartDataPoint with _$ChartDataPoint {
  const factory ChartDataPoint({
    required int id,
    required String label,
    required double amount,
    required int count,
  }) = _ChartDataPoint;
}

/// Pure calculations backing the Dashboard overview metrics and Indian FY charts.
abstract final class DashboardCalculator {
  static DashboardMetrics computeMetrics({
    required List<Customer> customers,
    required List<OneTimeDeposit> otds,
    required List<RecurringDeposit> rds,
  }) {
    final activeOtds = otds
        .where((d) => d.status == DepositStatus.active)
        .toList();
    final activeRds = rds
        .where((d) => d.status == DepositStatus.active)
        .toList();

    final activeCustomerIds = <String>{};
    for (final otd in activeOtds) {
      activeCustomerIds.add(otd.customerId);
    }
    for (final rd in activeRds) {
      activeCustomerIds.add(rd.customerId);
    }

    final activeCustomersCount = customers
        .where((c) => activeCustomerIds.contains(c.id))
        .length;

    final activeOtdsByScheme = <OneTimeSchemeType, int>{};
    final totalOtdsByScheme = <OneTimeSchemeType, int>{};

    for (final type in OneTimeSchemeType.values) {
      activeOtdsByScheme[type] = 0;
      totalOtdsByScheme[type] = 0;
    }

    for (final otd in otds) {
      totalOtdsByScheme[otd.schemeType] =
          (totalOtdsByScheme[otd.schemeType] ?? 0) + 1;
      if (otd.status == DepositStatus.active) {
        activeOtdsByScheme[otd.schemeType] =
            (activeOtdsByScheme[otd.schemeType] ?? 0) + 1;
      }
    }

    return DashboardMetrics(
      totalCustomers: customers.length,
      activeCustomers: activeCustomerIds.length > activeCustomersCount
          ? activeCustomerIds.length
          : activeCustomersCount,
      totalRds: rds.length,
      activeRds: activeRds.length,
      totalOtds: otds.length,
      activeOtds: activeOtds.length,
      activeOtdsByScheme: activeOtdsByScheme,
      totalOtdsByScheme: totalOtdsByScheme,
    );
  }

  static List<ChartDataPoint> computeChartSeries({
    required List<OneTimeDeposit> otds,
    required List<RecurringDeposit> rds,
    required OneTimeSchemeType? filter,
    required bool includeRds,
    required int? selectedYear,
  }) {
    final filteredOtds = filter == null
        ? otds
        : otds.where((d) => d.schemeType == filter).toList();
    final includedRds = (includeRds && filter == null)
        ? rds
        : const <RecurringDeposit>[];

    if (selectedYear == null) {
      final amountByYear = <int, double>{};
      final countByYear = <int, int>{};
      final labelByYear = <int, String>{};

      for (final otd in filteredOtds) {
        final year = otd.startDate.financialYearStart;
        amountByYear[year] = (amountByYear[year] ?? 0) + otd.principalAmount;
        countByYear[year] = (countByYear[year] ?? 0) + 1;
        labelByYear[year] = otd.startDate.financialYearLabel;
      }

      for (final rd in includedRds) {
        final year = rd.startDate.financialYearStart;
        amountByYear[year] =
            (amountByYear[year] ?? 0) + rd.totalScheduledAmount;
        countByYear[year] = (countByYear[year] ?? 0) + 1;
        labelByYear[year] = rd.startDate.financialYearLabel;
      }

      final sortedYears = amountByYear.keys.toList()..sort();
      return [
        for (final year in sortedYears)
          ChartDataPoint(
            id: year,
            label: labelByYear[year]!,
            amount: amountByYear[year]!,
            count: countByYear[year]!,
          ),
      ];
    }

    final formatter = DateFormat('MMM yy', resolvedDateLocale());
    final fyMonths = List.generate(
      12,
      (index) => DateTime(selectedYear, 4 + index),
    );
    final amountByMonthYear = <int, double>{};
    final countByMonthYear = <int, int>{};

    for (final date in fyMonths) {
      final key = date.year * 100 + date.month;
      amountByMonthYear[key] = 0.0;
      countByMonthYear[key] = 0;
    }

    for (final otd in filteredOtds.where(
      (d) => d.startDate.financialYearStart == selectedYear,
    )) {
      final key = otd.startDate.year * 100 + otd.startDate.month;
      amountByMonthYear[key] =
          (amountByMonthYear[key] ?? 0) + otd.principalAmount;
      countByMonthYear[key] = (countByMonthYear[key] ?? 0) + 1;
    }

    for (final rd in includedRds.where(
      (d) => d.startDate.financialYearStart == selectedYear,
    )) {
      final key = rd.startDate.year * 100 + rd.startDate.month;
      amountByMonthYear[key] =
          (amountByMonthYear[key] ?? 0) + rd.totalScheduledAmount;
      countByMonthYear[key] = (countByMonthYear[key] ?? 0) + 1;
    }

    return [
      for (final date in fyMonths)
        ChartDataPoint(
          id: date.year * 100 + date.month,
          label: formatter.format(date),
          amount: amountByMonthYear[date.year * 100 + date.month]!,
          count: countByMonthYear[date.year * 100 + date.month]!,
        ),
    ];
  }
}
