import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RDMonthlyKpiRow extends StatelessWidget {
  final RDMonthlyKpiSummary summary;
  final RDMonthlyFilter selectedFilter;
  final ValueChanged<RDMonthlyFilter> onFilterSelected;

  const RDMonthlyKpiRow({
    super.key,
    required this.summary,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final kpis = ops.kpis;
    final pipeline = ops.pipeline;

    final isCollectActive =
        selectedFilter == RDMonthlyFilter.toCollect ||
        selectedFilter == RDMonthlyFilter.overdue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PipelineStageCard(
              stepLabel: pipeline.step1Collect,
              amount: summary.toCollectAmount.toRupeeFormat(),
              countText: kpis.accountsCount(n: summary.toCollectCount),
              icon: HugeIcons.strokeRoundedCoins01,
              color: selectedFilter == RDMonthlyFilter.overdue
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              isSelected: isCollectActive,
              onTap: () => onFilterSelected(
                selectedFilter == RDMonthlyFilter.toCollect
                    ? RDMonthlyFilter.all
                    : RDMonthlyFilter.toCollect,
              ),
              badge: summary.overdueCount > 0
                  ? _OverdueInlineChip(
                      label: pipeline.overdueTag(count: summary.overdueCount),
                      isSelected: selectedFilter == RDMonthlyFilter.overdue,
                      onTap: () => onFilterSelected(
                        selectedFilter == RDMonthlyFilter.overdue
                            ? RDMonthlyFilter.all
                            : RDMonthlyFilter.overdue,
                      ),
                    )
                  : null,
            ),
          ),
          AppSpacings.gapXs,
          Expanded(
            child: _PipelineStageCard(
              stepLabel: pipeline.step2PoQueue,
              amount: summary.readyForPoAmount.toRupeeFormat(),
              countText: kpis.accountsCount(n: summary.readyForPoCount),
              icon: HugeIcons.strokeRoundedBuilding03,
              color: theme.colorScheme.secondary,
              isSelected: selectedFilter == RDMonthlyFilter.readyForPo,
              onTap: () => onFilterSelected(
                selectedFilter == RDMonthlyFilter.readyForPo
                    ? RDMonthlyFilter.all
                    : RDMonthlyFilter.readyForPo,
              ),
            ),
          ),
          AppSpacings.gapXs,
          Expanded(
            child: _PipelineStageCard(
              stepLabel: pipeline.step3Settled,
              amount: summary.settledAmount.toRupeeFormat(),
              countText: kpis.accountsCount(n: summary.settledCount),
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: theme.colorScheme.primary,
              isSelected: selectedFilter == RDMonthlyFilter.settled,
              onTap: () => onFilterSelected(
                selectedFilter == RDMonthlyFilter.settled
                    ? RDMonthlyFilter.all
                    : RDMonthlyFilter.settled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineStageCard extends StatelessWidget {
  final String stepLabel;
  final String amount;
  final String countText;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? badge;

  const _PipelineStageCard({
    required this.stepLabel,
    required this.amount,
    required this.countText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isSelected ? color : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    size: AppDimensions.iconXs,
                    color: color,
                  ),
                  AppSpacings.gapXs,
                  Expanded(
                    child: Text(
                      stepLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacings.gapXs,
              // Money is never ellipsised: shrink to fit instead.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
              AppSpacings.gapXxs,
              Text(
                countText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badge != null) ...[
                AppSpacings.gapXs,
                badge!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueInlineChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OverdueInlineChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingXs,
          vertical: AppDimensions.paddingXxs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.error
              : theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: AppDimensions.iconXs,
              color: isSelected
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onErrorContainer,
            ),
            AppSpacings.gapXxs,
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onErrorContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
