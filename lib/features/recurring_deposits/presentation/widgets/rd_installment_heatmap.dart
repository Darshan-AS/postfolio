import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum HeatmapStatus {
  settled,
  collected,
  advanced,
  overdue,
  upcoming,
}

class RDInstallmentHeatmap extends StatelessWidget {
  final RecurringDeposit deposit;
  final List<RDInstallment> installments;
  final int selectedMonthIndex;
  final int nextDueIndex;
  final ValueChanged<int> onSelectMonth;

  const RDInstallmentHeatmap({
    super.key,
    required this.deposit,
    required this.installments,
    required this.selectedMonthIndex,
    this.nextDueIndex = -1,
    required this.onSelectMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heatmapI18n = t.recurringDeposits.ledger.heatmap;
    final now = DateTime.now();

    if (installments.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMonths = deposit.totalMonths;
    final numYears = (totalMonths / 12).ceil();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Title & Active Month indicator + Reset Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedGrid,
                        size: AppDimensions.iconSm,
                      ),
                      AppSpacings.gapXs,
                      Flexible(
                        child: Text(
                          heatmapI18n.title(months: totalMonths.toString()),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacings.gapSm,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.recurringDeposits.ledger.installmentDetails.month(
                        month: (selectedMonthIndex + 1).toString(),
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (nextDueIndex != -1 &&
                        selectedMonthIndex != nextDueIndex) ...[
                      AppSpacings.gapSm,
                      InkWell(
                        onTap: () => onSelectMonth(nextDueIndex),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedRefresh,
                                size: AppDimensions.iconXs - 1,
                                color: theme.colorScheme.primary,
                              ),
                              AppSpacings.gapXs,
                              Text(
                                heatmapI18n.resetToNextDue(
                                  month: (nextDueIndex + 1).toString(),
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            AppSpacings.gapSm,

            // 5 Year Rows (Months 1 to 60)
            for (int y = 0; y < numYears; y++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        'Y${y + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    for (int m = 0; m < 12; m++) ...[
                      Expanded(
                        child: _buildMonthCell(
                          context: context,
                          yearIndex: y,
                          monthIndexInYear: m,
                          now: now,
                        ),
                      ),
                      if (m < 11) const SizedBox(width: 2),
                    ],
                  ],
                ),
              ),
            ],

            AppSpacings.gapMd,
            const Divider(height: AppDimensions.dividerHeight),
            AppSpacings.gapSm,

            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCell({
    required BuildContext context,
    required int yearIndex,
    required int monthIndexInYear,
    required DateTime now,
  }) {
    final theme = Theme.of(context);
    final overallIndex = (yearIndex * 12) + monthIndexInYear;

    if (overallIndex >= deposit.totalMonths ||
        overallIndex >= installments.length) {
      return const SizedBox(height: 24);
    }

    final inst = installments[overallIndex];
    final isSelected = overallIndex == selectedMonthIndex;
    final isPoPaid = inst.poStatus == RDPoStatus.paid;
    final isOverdue = inst.isOverdueAt(now);

    final HeatmapStatus status;
    final Color bgColor;
    final Color fgColor;
    final String statusLabel;

    if (inst.isFullySettled && isPoPaid) {
      status = HeatmapStatus.settled;
      bgColor = theme.colorScheme.primary;
      fgColor = theme.colorScheme.onPrimary;
      statusLabel = t.recurringDeposits.ledger.heatmap.legend.settled;
    } else if (inst.isInstallmentPaid && !isPoPaid) {
      if (!inst.isLateFeeResolved) {
        status = HeatmapStatus.overdue;
        bgColor = theme.colorScheme.error;
        fgColor = theme.colorScheme.onError;
        statusLabel = t.recurringDeposits.ledger.heatmap.legend.overdue;
      } else {
        status = HeatmapStatus.collected;
        bgColor = theme.colorScheme.secondary;
        fgColor = theme.colorScheme.onSecondary;
        statusLabel = t.recurringDeposits.ledger.heatmap.legend.collected;
      }
    } else if (isPoPaid) {
      status = HeatmapStatus.advanced;
      bgColor = theme.colorScheme.tertiary;
      fgColor = theme.colorScheme.onTertiary;
      statusLabel = t.recurringDeposits.ledger.heatmap.legend.advanced;
    } else if (isOverdue) {
      status = HeatmapStatus.overdue;
      bgColor = theme.colorScheme.error;
      fgColor = theme.colorScheme.onError;
      statusLabel = t.recurringDeposits.ledger.heatmap.legend.overdue;
    } else if (inst.customerPaidAmount > 0) {
      status = HeatmapStatus.collected;
      bgColor = theme.colorScheme.secondary;
      fgColor = theme.colorScheme.onSecondary;
      statusLabel = t.recurringDeposits.ledger.statuses.partiallyPaid;
    } else {
      status = HeatmapStatus.upcoming;
      bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      fgColor = theme.colorScheme.onSurfaceVariant;
      statusLabel = t.recurringDeposits.ledger.heatmap.legend.upcoming;
    }

    final tooltipText = t.recurringDeposits.ledger.heatmap.tooltip(
      month: (overallIndex + 1).toString(),
      date: inst.dueDate.toAppFormat(),
      status: statusLabel,
    );

    return Tooltip(
      message: tooltipText,
      child: InkWell(
        onTap: () => onSelectMonth(overallIndex),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.onSurface,
                    width: 2.0,
                  )
                : (status == HeatmapStatus.upcoming
                    ? Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1.0,
                      )
                    : null),
          ),
          child: Center(
            child: Text(
              '${overallIndex + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final legend = t.recurringDeposits.ledger.heatmap.legend;

    final items = [
      (theme.colorScheme.primary, legend.settled),
      (theme.colorScheme.secondary, legend.collected),
      (theme.colorScheme.tertiary, legend.advanced),
      (theme.colorScheme.error, legend.overdue),
      (theme.colorScheme.surfaceContainerHighest, legend.upcoming),
    ];

    return Wrap(
      spacing: AppDimensions.paddingSm,
      runSpacing: AppDimensions.paddingXs,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.$1,
                borderRadius: BorderRadius.circular(2),
                border: item.$2 == legend.upcoming
                    ? Border.all(color: theme.colorScheme.outlineVariant)
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.$2,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

