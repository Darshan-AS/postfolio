import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';

import 'package:postfolio/i18n/strings.g.dart';

enum ChartAggregation { count, amount }

/// "Deposits over time": one raised card holding the title, the amount / count switch, the
/// series filters and the bar chart.
///
/// The chart shows financial years; tapping a bar drills into that year's months, and the
/// "back to years" button under the title returns.
class DashboardChartSection extends HookConsumerWidget {
  const DashboardChartSection({super.key});

  static const EdgeInsets _cardInsets = EdgeInsets.symmetric(
    horizontal: AppDimensions.paddingLg,
  );

  /// Axis labels stop growing at this text scale. The plot has a fixed size, so larger tick
  /// labels would collide with each other; the bar tooltip carries the exact figures.
  static const double _maxAxisTextScale = AppDimensions.largeTextScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregationState = useState<ChartAggregation>(
      ChartAggregation.amount,
    );
    final aggregation = aggregationState.value;

    final chartData = ref.watch(dashboardChartSeriesProvider);
    final currentFilter = ref.watch(dashboardChartFilterProvider);
    final includeRds = ref.watch(dashboardChartIncludeRdsProvider);
    final selectedYear = ref.watch(dashboardChartSelectedYearProvider);

    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isCompact =
        MediaQuery.sizeOf(context).width < AppDimensions.breakpointTablet;

    String title = t.dashboard.depositsOverTime;
    if (selectedYear != null) {
      final startStr = selectedYear.toString().substring(2);
      final endStr = (selectedYear + 1).toString().substring(2);
      title = t.dashboard.depositsForFY(start: startStr, end: endStr);
    }

    // Drill-up. It takes a row of its own so its label is never cut short.
    final Widget drillUp = selectedYear == null
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: _cardInsets.copyWith(top: AppDimensions.paddingXs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton.tonal(
                label: t.dashboard.backToYears,
                icon: HugeIcons.strokeRoundedArrowLeft01,
                onPressed: () {
                  ref
                      .read(dashboardChartSelectedYearProvider.notifier)
                      .setYear(null);
                },
              ),
            ),
          );

    return Material(
      color: theme.colorScheme.raised,
      shape: AppShapes.rounded(AppShapes.extraLarge),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: _cardInsets,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.emphasizedOf(context).titleMedium,
                    ),
                  ),
                  AppSpacings.gapSm,
                  // Icon-only: the group then announces each segment by its tooltip
                  // ("By Amount"), where a "₹" label would be read out as the symbol alone.
                  AppButtonGroup<ChartAggregation>(
                    expand: false,
                    segments: [
                      AppSegment(
                        value: ChartAggregation.amount,
                        icon: HugeIcons.strokeRoundedRupee,
                        tooltip: t.dashboard.byAmount,
                      ),
                      AppSegment(
                        value: ChartAggregation.count,
                        icon: HugeIcons.strokeRoundedHashtag,
                        tooltip: t.dashboard.byCount,
                      ),
                    ],
                    selected: aggregation,
                    onChanged: (value) => aggregationState.value = value,
                  ),
                ],
              ),
            ),

            // The row opens and closes with the drill-down instead of jumping. `AnimatedSize`
            // cannot run with a zero duration, so reduced motion gets the plain row.
            if (disableAnimations)
              drillUp
            else
              AnimatedSize(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
                alignment: AlignmentDirectional.topStart,
                child: drillUp,
              ),

            // Each control is a 40dp pill in a 48dp touch target, so 4dp here is 12dp between
            // one pill and the next. The rows of controls were 16dp and then 8dp apart.
            AppSpacings.gapXs,

            // Which deposits the chart counts: all of them or one scheme. Tapping the chosen
            // scheme again goes back to All, so the group reports every tap. All five fit a
            // phone's width; on a wide window the group hugs its labels instead of
            // stretching across the card.
            Padding(
              padding: _cardInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButtonGroup<OneTimeSchemeType?>.multi(
                      expand: isCompact,
                      segments: [
                        AppSegment(value: null, label: t.dashboard.all),
                        for (final scheme in OneTimeSchemeType.values)
                          AppSegment(value: scheme, label: scheme.shortName),
                      ],
                      selected: {currentFilter},
                      onToggled: (scheme) => ref
                          .read(dashboardChartFilterProvider.notifier)
                          .setFilter(scheme == currentFilter ? null : scheme),
                    ),
                  ),
                  AppSpacings.gapXs,
                  // Recurring deposits can only be added to the view of everything.
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton.toggle(
                      label: t.dashboard.includeRecurringDeposits,
                      selected: includeRds && currentFilter == null,
                      onPressed: currentFilter == null
                          ? () => ref
                                .read(dashboardChartIncludeRdsProvider.notifier)
                                .toggle()
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // The chart keeps a band above its tallest bar for that bar's tooltip, so the
            // controls need no more than this before it.
            AppSpacings.gapXs,

            // Chart Body
            Padding(
              padding: _cardInsets,
              child: SizedBox(
                height: AppDimensions.chartHeight,
                child: chartData.isEmpty
                    ? Center(
                        child: Text(
                          t.dashboard.noDataForFilter,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildBarChart(
                        context,
                        ref,
                        chartData,
                        aggregation,
                        selectedYear,
                        animate: !disableAnimations,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    WidgetRef ref,
    List<ChartDataPoint> data,
    ChartAggregation aggregation,
    int? selectedYear, {
    required bool animate,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // The axis labels grow with the text size up to the cap applied to the chart. The
    // column that holds the amounts has to grow with them, or "₹10L" is cut to "₹10".
    final axisTextScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, _maxAxisTextScale);

    double maxY = 0;
    for (final dp in data) {
      final value = aggregation == ChartAggregation.amount
          ? dp.amount
          : dp.count.toDouble();
      if (value > maxY) maxY = value;
    }

    if (maxY == 0) maxY = 10; // default scale if all 0

    final chart = BarChart(
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
                ref
                    .read(dashboardChartSelectedYearProvider.notifier)
                    .setYear(yearId);
              }
            }
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(AppShapes.small),
            getTooltipColor: (group) => colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dp = data[groupIndex];
              final valueStr = aggregation == ChartAggregation.amount
                  ? dp.amount.toRupeeFormat()
                  : t.common.countWithLabel(
                      label: '${dp.count}',
                      count: dp.count,
                    );
              return BarTooltipItem(
                '${dp.label}\n$valueStr',
                AppTypography.emphasizedOf(
                  context,
                ).labelLarge!.copyWith(color: colorScheme.onInverseSurface),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize:
                  AppDimensions.chartXAxisReservedSize +
                  AppDimensions.chartXAxisSlantedExtraSpace,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return SideTitleWidget(
                    meta: meta,
                    // Far enough below the axis that a slanted label's raised end stays
                    // clear of the bars.
                    space: AppDimensions.paddingLg,
                    angle: -math.pi / 4,
                    child: Text(
                      data[value.toInt()].label,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: AppDimensions.fontXs,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
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
              reservedSize:
                  AppDimensions.chartYAxisReservedSize * axisTextScale,
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
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppDimensions.chartTooltipReservedHeight,
              getTitlesWidget: (double value, TitleMeta meta) {
                return const SizedBox.shrink();
              },
            ),
          ),
          // No titles on the right; the strip gives the last slanted label room to end.
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppDimensions.paddingMd,
              getTitlesWidget: (double value, TitleMeta meta) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: AppDimensions.borderSm,
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
                // Rounded tops; the foot stays square on the baseline.
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppShapes.small),
                ),
              ),
            ],
          );
        }),
      ),
      duration: animate ? AppAnimations.medium : Duration.zero,
      // Bars grow on the effects curve: it never overshoots the axis maximum.
      curve: AppAnimations.defaultCurve,
    );

    return ClipRect(
      key: ValueKey(aggregation),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxAxisTextScale,
        child: chart,
      ),
    );
  }
}
