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
    final kpis = t.recurringDeposits.monthlyOperations.kpis;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
      ),
      child: Row(
        children: [
          _KpiCard(
            title: kpis.toCollect,
            amount: summary.toCollectAmount.toRupeeFormat(),
            countText: kpis.accountsCount(n: summary.toCollectCount),
            icon: HugeIcons.strokeRoundedCoins01,
            color: theme.colorScheme.primary,
            isSelected: selectedFilter == RDMonthlyFilter.toCollect,
            onTap: () => onFilterSelected(
              selectedFilter == RDMonthlyFilter.toCollect
                  ? RDMonthlyFilter.all
                  : RDMonthlyFilter.toCollect,
            ),
          ),
          AppSpacings.gapSm,
          _KpiCard(
            title: kpis.readyForPo,
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
          AppSpacings.gapSm,
          _KpiCard(
            title: kpis.settled,
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
          AppSpacings.gapSm,
          _KpiCard(
            title: kpis.overdue,
            amount: summary.overdueAmount.toRupeeFormat(),
            countText: kpis.accountsCount(n: summary.overdueCount),
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: theme.colorScheme.error,
            isSelected: selectedFilter == RDMonthlyFilter.overdue,
            onTap: () => onFilterSelected(
              selectedFilter == RDMonthlyFilter.overdue
                  ? RDMonthlyFilter.all
                  : RDMonthlyFilter.overdue,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final String countText;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.amount,
    required this.countText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
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
        child: Container(
          width: 145,
          padding: const EdgeInsets.all(AppDimensions.paddingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    size: AppDimensions.iconSm,
                    color: color,
                  ),
                  AppSpacings.gapXs,
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacings.gapXs,
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacings.gapXs,
              Text(
                countText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
