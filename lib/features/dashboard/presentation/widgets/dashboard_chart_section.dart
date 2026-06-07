import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';

import 'package:postfolio/i18n/strings.g.dart';

enum ChartAggregation { count, amount }

class DashboardChartSection extends HookConsumerWidget {
  const DashboardChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregationState = useState<ChartAggregation>(
      ChartAggregation.amount,
    );
    final aggregation = aggregationState.value;

    final chartData = ref.watch(dashboardChartSeriesProvider);
    final currentFilter = ref.watch(dashboardChartFilterProvider);
    final selectedYear = ref.watch(dashboardChartSelectedYearProvider);

    String title = t.dashboard.depositsOverTime;
    if (selectedYear != null) {
      final startStr = selectedYear.toString().substring(2);
      final endStr = (selectedYear + 1).toString().substring(2);
      title = t.dashboard.depositsForFY(start: startStr, end: endStr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedYear != null) ...[
                    const SizedBox(width: AppDimensions.paddingSm),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(dashboardChartSelectedYearProvider.notifier).setYear(null);
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(t.dashboard.backToYears),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            SegmentedButton<ChartAggregation>(
              segments: [
                ButtonSegment(
                  value: ChartAggregation.amount,
                  label: Text(t.format.currencySymbol),
                  tooltip: t.dashboard.byAmount,
                ),
                ButtonSegment(
                  value: ChartAggregation.count,
                  label: Text(t.format.countSymbol),
                  tooltip: t.dashboard.byCount,
                ),
              ],
              selected: {aggregation},
              onSelectionChanged: (Set<ChartAggregation> newSelection) {
                aggregationState.value = newSelection.first;
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSm),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scheme Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppDimensions.paddingSm,
                        ),
                        child: ChoiceChip(
                          label: Text(t.dashboard.all),
                          selected: currentFilter == null,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(dashboardChartFilterProvider.notifier)
                                  .setFilter(null);
                            }
                          },
                        ),
                      ),
                      ...OneTimeSchemeType.values.map((scheme) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: AppDimensions.paddingSm,
                          ),
                          child: ChoiceChip(
                            label: Text(scheme.shortName),
                            selected: currentFilter == scheme,
                            onSelected: (selected) {
                              ref
                                  .read(dashboardChartFilterProvider.notifier)
                                  .setFilter(selected ? scheme : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXl),

                // Chart Body
                SizedBox(
                  height: 250,
                  child: chartData.isEmpty
                      ? Center(child: Text(t.dashboard.noDataForFilter))
                      : _buildBarChart(context, ref, chartData, aggregation, selectedYear),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    WidgetRef ref,
    List<ChartDataPoint> data,
    ChartAggregation aggregation,
    int? selectedYear,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    double maxY = 0;
    for (final dp in data) {
      final value = aggregation == ChartAggregation.amount
          ? dp.amount
          : dp.count.toDouble();
      if (value > maxY) maxY = value;
    }

    // Add some padding to top
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 10; // default scale if all 0

    return ClipRect(
      key: ValueKey(aggregation),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (selectedYear == null &&
                  event is FlTapUpEvent &&
                  barTouchResponse?.spot != null) {
                final index = barTouchResponse!.spot!.touchedBarGroupIndex;
                if (index >= 0 && index < data.length) {
                  final yearId = data[index].id;
                  ref.read(dashboardChartSelectedYearProvider.notifier).setYear(yearId);
                }
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => colorScheme.onSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dp = data[groupIndex];
                final valueStr = aggregation == ChartAggregation.amount
                    ? NumberFormat.compactCurrency(
                        locale: AppConstants.defaultLocale,
                        symbol: t.format.currencySymbol,
                      ).format(dp.amount)
                    : t.common.countWithLabel(
                        label: '${dp.count}',
                        count: dp.count,
                      );
                return BarTooltipItem(
                  '${dp.label}\n$valueStr',
                  TextStyle(
                    color: colorScheme.surface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[value.toInt()].label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: AppDimensions.chartYAxisReservedSize,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0 || value == maxY) {
                    return const SizedBox.shrink();
                  }

                  String label;
                  if (aggregation == ChartAggregation.amount) {
                    label = NumberFormat.compactCurrency(
                      locale: AppConstants.defaultLocale,
                      symbol: t.format.currencySymbol,
                      decimalDigits: 0,
                    ).format(value);
                  } else {
                    label = value.toInt().toString();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withAlpha(50),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final dp = data[index];
            final value = aggregation == ChartAggregation.amount
                ? dp.amount
                : dp.count.toDouble();

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: colorScheme.primary,
                  width: AppDimensions.chartBarWidth,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      ),
    );
  }
}
