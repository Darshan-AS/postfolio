import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_kpi_row.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Scroll-away header of the Monthly Hub: month switcher, KPI pipeline, agent float strip,
/// prior-arrears banner and the "ready for PO" strip. Rebuilds only on month / KPI changes —
/// never on a search keystroke.
class RDHubHeader extends ConsumerWidget {
  const RDHubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(rDHubMonthProvider);
    final now = ref.watch(clockProvider)();
    final monthNotifier = ref.read(rDHubMonthProvider.notifier);
    final filtersNotifier = ref.read(rDHubFiltersProvider.notifier);
    final statusFilter = ref.watch(rDHubFiltersProvider.select((s) => s.status));
    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final floatSummary = ref.watch(globalAgentFloatProvider);
    final isLoading = ref.watch(monthlyOperationItemsProvider.select((a) => a.isLoading));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacings.gapSm,
        RDMonthSwitcher(
          selectedMonth: month,
          isCurrentMonth: month == now.toMonthStart(),
          onPrevious: monthNotifier.previousMonth,
          onNext: monthNotifier.nextMonth,
          onResetToCurrent: monthNotifier.resetToCurrentMonth,
          onPickMonth: monthNotifier.setMonth,
        ),
        AppSpacings.gapSm,
        Skeletonizer(
          enabled: isLoading,
          child: RDMonthlyKpiRow(
            summary: kpis,
            selectedFilter: statusFilter,
            onFilterSelected: filtersNotifier.setStatus,
          ),
        ),
        if (floatSummary.hasFloat) ...[
          AppSpacings.gapSm,
          _AgentFloatStrip(
            summary: floatSummary,
            onFilterSelected: filtersNotifier.setStatus,
          ),
        ],
        if (kpis.priorArrearsAccountsCount > 0) ...[
          AppSpacings.gapSm,
          _PriorArrearsBanner(
            kpis: kpis,
            onReview: () => filtersNotifier.setStatus(RDMonthlyFilter.overdue),
          ),
        ],
        if (statusFilter == RDMonthlyFilter.readyForPo && kpis.readyForPoCount > 0) ...[
          AppSpacings.gapSm,
          const _PoQueueReadyStrip(),
        ],
        AppSpacings.gapSm,
      ],
    );
  }
}

class _PriorArrearsBanner extends StatelessWidget {
  final RDMonthlyKpiSummary kpis;
  final VoidCallback onReview;

  const _PriorArrearsBanner({required this.kpis, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingXs,
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  size: AppDimensions.iconSm,
                  color: theme.colorScheme.error,
                ),
                AppSpacings.gapSm,
                Expanded(
                  child: Text(
                    ops.priorArrearsBanner.message(
                      n: kpis.priorArrearsAccountsCount,
                      count: kpis.priorArrearsAccountsCount,
                      amount: kpis.priorArrearsAmount.toRupeeFormat(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSm,
                    ),
                  ),
                  onPressed: onReview,
                  child: Text(
                    ops.priorArrearsBanner.action,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "N installments ready for PO" strip with a one-tap "Select all ready" action.
class _PoQueueReadyStrip extends ConsumerWidget {
  const _PoQueueReadyStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final banner = t.recurringDeposits.monthlyOperations.poQueueBanner;
    final kpis = ref.watch(monthlyOperationsKpiProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Material(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
            vertical: AppDimensions.paddingXs,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconSm,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              AppSpacings.gapSm,
              Expanded(
                child: Text(
                  banner.readyMessage(
                    count: kpis.readyForPoCount,
                    amount: kpis.readyForPoAmount.toRupeeFormat(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                  ),
                ),
                onPressed: () {
                  final items = ref.read(monthlyOperationItemsProvider).value ?? const [];
                  ref.read(rDHubSelectionProvider.notifier).selectAll([
                    for (final i in items)
                      if (i.isReadyForPo) i.installment.id,
                  ]);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckList,
                  size: AppDimensions.iconXs,
                  color: theme.colorScheme.secondary,
                ),
                label: Text(
                  banner.selectAllReady,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentFloatStrip extends StatelessWidget {
  final RDAgentFloatSummary summary;
  final ValueChanged<RDMonthlyFilter> onFilterSelected;

  const _AgentFloatStrip({required this.summary, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final floatStrings = t.recurringDeposits.monthlyOperations.agentFloat;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          if (summary.undepositedCashCount > 0)
            _FloatChip(
              icon: HugeIcons.strokeRoundedBuilding03,
              label: floatStrings.cashInHand(
                amount: summary.undepositedCashAmount.toRupeeFormat(),
                count: summary.undepositedCashCount,
              ),
              background: theme.colorScheme.secondaryContainer,
              foreground: theme.colorScheme.onSecondaryContainer,
              onTap: () => onFilterSelected(RDMonthlyFilter.readyForPo),
            ),
          if (summary.undepositedCashCount > 0 && summary.pocketAdvancesCount > 0)
            AppSpacings.gapSm,
          if (summary.pocketAdvancesCount > 0)
            _FloatChip(
              icon: HugeIcons.strokeRoundedWallet02,
              label: floatStrings.pocketAdvances(
                amount: summary.pocketAdvancesAmount.toRupeeFormat(),
                count: summary.pocketAdvancesCount,
              ),
              background: theme.colorScheme.tertiaryContainer,
              foreground: theme.colorScheme.onTertiaryContainer,
              onTap: () => onFilterSelected(RDMonthlyFilter.toCollect),
            ),
        ],
      ),
    );
  }
}

class _FloatChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _FloatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
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
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: AppDimensions.iconXs, color: foreground),
            AppSpacings.gapXs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
