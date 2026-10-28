import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Scroll-away header of the Monthly Hub: the month switcher and one compact 2×2 block of
/// KPI tiles (To collect · In hand · Receivable · Arrears). Three tiles set a list filter;
/// "In hand" opens the Post Office visit planner. Rebuilds only on month / KPI changes —
/// never on a search keystroke.
class RDHubHeader extends ConsumerWidget {
  const RDHubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(rDHubMonthProvider);
    final now = ref.watch(clockProvider)();
    final monthNotifier = ref.read(rDHubMonthProvider.notifier);
    final isLoading = ref.watch(
      monthlyOperationItemsProvider.select((a) => a.isLoading),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacings.gapXs,
        RDMonthSwitcher(
          selectedMonth: month,
          isCurrentMonth: month == now.toMonthStart(),
          onPrevious: monthNotifier.previousMonth,
          onNext: monthNotifier.nextMonth,
          onResetToCurrent: monthNotifier.resetToCurrentMonth,
          onPickMonth: monthNotifier.setMonth,
        ),
        AppSpacings.gapXs,
        Skeletonizer(enabled: isLoading, child: const _KpiGrid()),
        AppSpacings.gapSm,
      ],
    );
  }
}

/// 2×2 grid: every tile's colours come from the matching `RDStatusVisual`, so the header
/// can never contradict the row pills.
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final strings = ops.kpis;

    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final float = ref.watch(globalAgentFloatProvider);
    final statusFilter = ref.watch(
      rDHubFiltersProvider.select((s) => s.status),
    );
    final isBusy = ref.watch(
      rDLedgerControllerProvider.select((a) => a.isLoading),
    );
    final filters = ref.read(rDHubFiltersProvider.notifier);

    void toggle(RDMonthlyFilter filter) => filters.setStatus(
      statusFilter == filter ? RDMonthlyFilter.all : filter,
    );

    void planVisit() {
      ref.read(rDPoVisitPlannerProvider.notifier).start();
      showRDPoVisitPlanner(context);
    }

    final RDStatusVisual neutral = (
      foreground: scheme.onSurfaceVariant,
      background: scheme.surfaceContainerLow,
      outline: null,
      emphasized: false,
      icon: HugeIcons.strokeRoundedCoins01,
      label: '',
    );

    // To collect: red only when something is actually overdue; otherwise the "upcoming"
    // tone, exactly like the rows below.
    final toCollectVisual = kpis.toCollectCount == 0
        ? neutral
        : (kpis.overdueCount > 0
                  ? RDInstallmentDisplayStatus.overdue
                  : RDInstallmentDisplayStatus.upcoming)
              .visual(scheme);
    final inHandVisual = float.cashInHandAccounts > 0
        ? RDInstallmentDisplayStatus.collectedPendingPo.visual(scheme)
        : neutral;
    final receivableVisual = float.receivableAccounts > 0
        ? RDInstallmentDisplayStatus.frontedByAgent.visual(scheme)
        : neutral;
    final arrearsVisual = float.arrearsAccounts > 0
        ? RDInstallmentDisplayStatus.overdue.visual(scheme)
        : neutral;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _KpiTile(
                    label: strings.toCollect,
                    amount: kpis.toCollectAmount.toRupeeFormat(),
                    caption: strings.accountsCount(n: kpis.toCollectCount),
                    icon: HugeIcons.strokeRoundedCoins01,
                    visual: toCollectVisual,
                    isSelected: statusFilter == RDMonthlyFilter.toCollect,
                    onTap: () => toggle(RDMonthlyFilter.toCollect),
                  ),
                ),
                AppSpacings.gapSm,
                Expanded(
                  child: _KpiTile(
                    label: strings.inHand,
                    amount: float.cashInHandTotal.toRupeeFormat(),
                    caption: float.cashInHandAccounts > 0
                        ? strings.accountsReady(n: float.cashInHandAccounts)
                        : strings.nothingToDeposit,
                    detail: float.cashInHandAccounts > 0
                        ? ops.visit.byMode(
                            cash: float.cashInHandCash.toRupeeFormat(),
                            digital: float.cashInHandDigital.toRupeeFormat(),
                          )
                        : null,
                    icon: HugeIcons.strokeRoundedBuilding03,
                    visual: inHandVisual,
                    isSelected: false,
                    onTap: isBusy || float.cashInHandAccounts == 0
                        ? null
                        : planVisit,
                  ),
                ),
              ],
            ),
          ),
          AppSpacings.gapSm,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _KpiTile(
                    label: strings.receivable,
                    amount: float.receivableAmount.toRupeeFormat(),
                    caption: strings.accountsCount(n: float.receivableAccounts),
                    icon: HugeIcons.strokeRoundedWallet02,
                    visual: receivableVisual,
                    isSelected: statusFilter == RDMonthlyFilter.fronted,
                    onTap: () => toggle(RDMonthlyFilter.fronted),
                  ),
                ),
                AppSpacings.gapSm,
                Expanded(
                  child: _KpiTile(
                    label: strings.arrears,
                    amount: strings.accountsCount(n: float.arrearsAccounts),
                    caption: strings.arrearsCaption,
                    icon: HugeIcons.strokeRoundedAlert02,
                    visual: arrearsVisual,
                    isSelected: statusFilter == RDMonthlyFilter.overdue,
                    onTap: () => toggle(RDMonthlyFilter.overdue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable KPI tile. Money is never ellipsised — it shrinks to fit.
class _KpiTile extends StatelessWidget {
  final String label;
  final String amount;
  final String caption;
  final String? detail;
  final List<List<dynamic>> icon;
  final RDStatusVisual visual;
  final bool isSelected;
  final VoidCallback? onTap;

  const _KpiTile({
    required this.label,
    required this.amount,
    required this.caption,
    this.detail,
    required this.icon,
    required this.visual,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = isSelected
        ? scheme.primary
        : (visual.outline ?? scheme.outlineVariant);

    return Material(
      color: visual.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: borderColor,
          width: isSelected ? AppDimensions.borderMd : AppDimensions.borderSm,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
                    color: visual.foreground,
                  ),
                  AppSpacings.gapXs,
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: visual.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacings.gapXs,
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: visual.foreground,
                  ),
                  maxLines: 1,
                ),
              ),
              if (detail != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    detail!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: visual.foreground,
                    ),
                    maxLines: 1,
                  ),
                ),
              Text(
                caption,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: visual.foreground.withValues(
                    alpha: AppDimensions.opacityMuted,
                  ),
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
