import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.freezed.dart';
part 'dashboard_provider.g.dart';

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

@riverpod
DashboardMetrics dashboardMetricsData(Ref ref) {
  final customers =
      ref.watch(customersControllerProvider).value ?? <Customer>[];
  final otds =
      ref.watch(oneTimeDepositsControllerProvider).value ?? <OneTimeDeposit>[];
  final rds =
      ref.watch(recurringDepositsControllerProvider).value ??
      <RecurringDeposit>[];

  // Active OTDs and RDs
  final activeOtds = otds
      .where((d) => d.status == DepositStatus.active)
      .toList();
  final activeRds = rds.where((d) => d.status == DepositStatus.active).toList();

  // Active Customers
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

  // OTDs by Scheme
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
        : activeCustomersCount, // Fallback if customer is deleted
    totalRds: rds.length,
    activeRds: activeRds.length,
    totalOtds: otds.length,
    activeOtds: activeOtds.length,
    activeOtdsByScheme: activeOtdsByScheme,
    totalOtdsByScheme: totalOtdsByScheme,
  );
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

@riverpod
class DashboardChartSelectedYear extends _$DashboardChartSelectedYear {
  @override
  int? build() => null;

  void setYear(int? year) {
    state = year;
  }
}

@riverpod
class DashboardChartFilter extends _$DashboardChartFilter {
  @override
  OneTimeSchemeType? build() => null;

  void setFilter(OneTimeSchemeType? type) {
    state = type;
  }
}

@riverpod
List<ChartDataPoint> dashboardChartSeries(Ref ref) {
  final otds =
      ref.watch(oneTimeDepositsControllerProvider).value ?? <OneTimeDeposit>[];
  final filter = ref.watch(dashboardChartFilterProvider);
  final selectedYear = ref.watch(dashboardChartSelectedYearProvider);

  final filteredOtds = filter == null
      ? otds
      : otds.where((d) => d.schemeType == filter).toList();

  if (selectedYear == null) {
    final Map<int, double> amountByYear = {};
    final Map<int, int> countByYear = {};
    final Map<int, String> labelByYear = {};

    for (final otd in filteredOtds) {
      final year = otd.startDate.financialYearStart;
      amountByYear[year] = (amountByYear[year] ?? 0) + otd.principalAmount;
      countByYear[year] = (countByYear[year] ?? 0) + 1;
      labelByYear[year] = otd.startDate.financialYearLabel;
    }

    final List<ChartDataPoint> data = [];
    final sortedYears = amountByYear.keys.toList()..sort();
    for (final year in sortedYears) {
      data.add(
        ChartDataPoint(
          id: year,
          label: labelByYear[year]!,
          amount: amountByYear[year]!,
          count: countByYear[year]!,
        ),
      );
    }

    return data;
  } else {
    final List<ChartDataPoint> data = [];
    final locale = LocaleSettings.currentLocale.languageTag;
    final formatter = DateFormat('MMM yy', locale);

    // Generate the 12 months for the selected financial year starting from April
    final List<DateTime> fyMonths = List.generate(
      12,
      (index) => DateTime(selectedYear, 4 + index),
    );

    final Map<int, double> amountByMonthYear = {};
    final Map<int, int> countByMonthYear = {};

    for (final date in fyMonths) {
      final key = date.year * 100 + date.month;
      amountByMonthYear[key] = 0.0;
      countByMonthYear[key] = 0;
    }

    final yearOtds = filteredOtds.where(
      (d) => d.startDate.financialYearStart == selectedYear,
    );

    for (final otd in yearOtds) {
      final key = otd.startDate.year * 100 + otd.startDate.month;
      amountByMonthYear[key] =
          (amountByMonthYear[key] ?? 0) + otd.principalAmount;
      countByMonthYear[key] = (countByMonthYear[key] ?? 0) + 1;
    }

    for (final date in fyMonths) {
      final key = date.year * 100 + date.month;
      data.add(
        ChartDataPoint(
          id: key,
          label: formatter.format(date),
          amount: amountByMonthYear[key]!,
          count: countByMonthYear[key]!,
        ),
      );
    }

    return data;
  }
}
