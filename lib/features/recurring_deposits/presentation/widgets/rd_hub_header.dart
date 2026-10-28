import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_kpi_row.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Scroll-away header of the Monthly Hub: month switcher, KPI pipeline, agent float strip,
/// prior-arrears banner and the "ready to deposit" strip. Rebuilds only on month / KPI
/// changes — never on a search keystroke.
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
        if (floatSummary.hasFloat ||
            floatSummary.arrearsAccounts > 0 ||
            kpis.toCollectCount > 0) ...[
          AppSpacings.gapSm,
          _AgentFloatStrip(
            summary: floatSummary,
            kpis: kpis,
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
        if (kpis.readyForPoCount > 0) ...[
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

/// "N ready to deposit (₹X)" strip with a deposit-date picker and a one-tap
/// "Deposit all" that records one PO event per ready account.
class _PoQueueReadyStrip extends HookConsumerWidget {
  const _PoQueueReadyStrip();

  /// How far back the batch deposit date may be set (a backdated PO visit).
  static const int _depositDateLookbackYears = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final banner = ops.poQueueBanner;
    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final today = ref.watch(clockProvider)().toDateOnly();
    final isBusy = ref.watch(rDLedgerControllerProvider.select((a) => a.isLoading));
    final depositedOn = useState<DateTime>(today);

    final accountsText = ops.kpis.accountsCount(n: kpis.readyForPoCount);

    Future<void> pickDate() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: depositedOn.value,
        firstDate: DateTime(today.year - _depositDateLookbackYears, today.month),
        lastDate: today,
      );
      if (selected == null || !context.mounted) return;
      depositedOn.value = selected.toDateOnly();
    }

    Future<void> depositAll() async {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: banner.confirmTitle,
        content: '${banner.confirmMessage(count: accountsText, amount: kpis.readyForPoAmount.toRupeeFormat())}'
            '\n\n${banner.depositDate(date: depositedOn.value.toAppFormat())}',
        confirmText: t.common.confirm,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await ref
          .read(rDMonthlyOperationsActionsProvider.notifier)
          .depositAllReady(depositedOn: depositedOn.value);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: banner.success(count: accountsText),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: AppDimensions.opacityMuted),
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
                color: scheme.onSecondaryContainer,
              ),
              AppSpacings.gapSm,
              Expanded(
                child: Text(
                  banner.readyMessage(
                    count: accountsText,
                    amount: kpis.readyForPoAmount.toRupeeFormat(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: banner.depositDate(date: depositedOn.value.toAppFormat()),
                visualDensity: VisualDensity.compact,
                onPressed: isBusy ? null : pickDate,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  size: AppDimensions.iconSm,
                  color: scheme.secondary,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSm),
                ),
                onPressed: isBusy ? null : depositAll,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckList,
                  size: AppDimensions.iconXs,
                  color: scheme.secondary,
                ),
                label: Text(
                  banner.depositAll,
                  style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The agent's four at-a-glance numbers: still to collect in this month, cash in hand
/// (cash vs digital), receivable (fronted from pocket) and accounts in arrears.
class _AgentFloatStrip extends StatelessWidget {
  final RDAgentFloatSummary summary;
  final RDMonthlyKpiSummary kpis;
  final ValueChanged<RDMonthlyFilter> onFilterSelected;

  const _AgentFloatStrip({
    required this.summary,
    required this.kpis,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final floatStrings = ops.agentFloat;

    final chips = <Widget>[
      if (kpis.toCollectCount > 0)
        _FloatChip(
          icon: HugeIcons.strokeRoundedCoins01,
          label: floatStrings.toCollect(
            amount: kpis.toCollectAmount.toRupeeFormat(),
            count: ops.kpis.accountsCount(n: kpis.toCollectCount),
          ),
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          onTap: () => onFilterSelected(RDMonthlyFilter.toCollect),
        ),
      if (summary.cashInHandAccounts > 0)
        _FloatChip(
          icon: HugeIcons.strokeRoundedBuilding03,
          label: floatStrings.cashInHand(
            total: summary.cashInHandTotal.toRupeeFormat(),
            cash: summary.cashInHandCash.toRupeeFormat(),
            digital: summary.cashInHandDigital.toRupeeFormat(),
          ),
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          onTap: () => onFilterSelected(RDMonthlyFilter.readyForPo),
        ),
      if (summary.receivableAccounts > 0)
        _FloatChip(
          icon: HugeIcons.strokeRoundedWallet02,
          label: floatStrings.receivable(
            amount: summary.receivableAmount.toRupeeFormat(),
            count: ops.kpis.accountsCount(n: summary.receivableAccounts),
          ),
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          onTap: () => onFilterSelected(RDMonthlyFilter.toCollect),
        ),
      if (summary.arrearsAccounts > 0)
        _FloatChip(
          icon: HugeIcons.strokeRoundedAlert02,
          label: floatStrings.arrears(
            count: ops.kpis.accountsCount(n: summary.arrearsAccounts),
          ),
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          onTap: () => onFilterSelected(RDMonthlyFilter.overdue),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) AppSpacings.gapSm,
            chips[i],
          ],
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
