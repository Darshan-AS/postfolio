import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/dashboard/domain/dashboard_models.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:postfolio/features/dashboard/domain/dashboard_models.dart'
    show ChartDataPoint, DashboardMetrics;

part 'dashboard_controller.g.dart';

@riverpod
DashboardMetrics dashboardMetricsData(Ref ref) {
  final customers =
      ref.watch(customersControllerProvider).value ?? <Customer>[];
  final otds =
      ref.watch(oneTimeDepositsControllerProvider).value ?? <OneTimeDeposit>[];
  final rds =
      ref.watch(recurringDepositsControllerProvider).value ??
      <RecurringDeposit>[];

  return DashboardCalculator.computeMetrics(
    customers: customers,
    otds: otds,
    rds: rds,
  );
}

@riverpod
class DashboardChartSelectedYear extends _$DashboardChartSelectedYear {
  @override
  int? build() => null;

  void setYear(int? year) => state = year;
}

@riverpod
class DashboardChartFilter extends _$DashboardChartFilter {
  @override
  OneTimeSchemeType? build() => null;

  void setFilter(OneTimeSchemeType? type) => state = type;
}

@riverpod
class DashboardChartIncludeRds extends _$DashboardChartIncludeRds {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@riverpod
List<ChartDataPoint> dashboardChartSeries(Ref ref) {
  final otds =
      ref.watch(oneTimeDepositsControllerProvider).value ?? <OneTimeDeposit>[];
  final rds =
      ref.watch(recurringDepositsControllerProvider).value ??
      <RecurringDeposit>[];
  final filter = ref.watch(dashboardChartFilterProvider);
  final includeRds = ref.watch(dashboardChartIncludeRdsProvider);
  final selectedYear = ref.watch(dashboardChartSelectedYearProvider);

  return DashboardCalculator.computeChartSeries(
    otds: otds,
    rds: rds,
    filter: filter,
    includeRds: includeRds,
    selectedYear: selectedYear,
  );
}
