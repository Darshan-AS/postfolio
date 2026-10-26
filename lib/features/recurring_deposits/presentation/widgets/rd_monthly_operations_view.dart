import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_kpi_row.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RDMonthlyOperationsView extends HookConsumerWidget {
  const RDMonthlyOperationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final opsState = ref.watch(rDMonthlyOperationsControllerProvider);
    final controller = ref.read(rDMonthlyOperationsControllerProvider.notifier);
    final kpis = ref.watch(monthlyOperationsKpiProvider);
    final floatSummary = ref.watch(globalAgentFloatProvider);
    final asyncItems = ref.watch(filteredMonthlyOperationsProvider);
    final ops = t.recurringDeposits.monthlyOperations;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(rdAllSparseInstallmentsStreamProvider);
            ref.invalidate(rawMonthlyOperationsStreamProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Zone 1: Collapsible Sliver Header (scrolls away when browsing list)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacings.gapSm,
                    RDMonthSwitcher(
                      selectedMonth: opsState.selectedMonth,
                      onPrevious: controller.previousMonth,
                      onNext: controller.nextMonth,
                      onResetToCurrent: controller.resetToCurrentMonth,
                    ),
                    AppSpacings.gapSm,
                    RDMonthlyKpiRow(
                      summary: kpis,
                      selectedFilter: opsState.selectedFilter,
                      onFilterSelected: controller.setFilter,
                    ),
                    if (floatSummary.hasFloat) ...[
                      AppSpacings.gapSm,
                      _buildAgentFloatStrip(context, floatSummary, controller),
                    ],
                    if (kpis.priorArrearsAccountsCount > 0) ...[
                      AppSpacings.gapSm,
                      _buildPriorArrearsBanner(context, kpis, controller),
                    ],
                    if (opsState.selectedFilter == RDMonthlyFilter.readyForPo &&
                        kpis.readyForPoCount > 0) ...[
                      AppSpacings.gapSm,
                      _buildPoQueueReadyStrip(
                        context,
                        kpis,
                        asyncItems.value ?? const [],
                        controller,
                      ),
                    ],
                    AppSpacings.gapSm,
                  ],
                ),
              ),

              // Zone 2: Pinned Sticky Toolbar (Search + Deadline Window + Customer Group + Select)
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingXs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSearchBar(
                          hintText: ops.searchHint,
                          onChanged: controller.setSearchQuery,
                        ),
                        AppSpacings.gapXs,
                        _buildCompactToolbar(
                          context,
                          opsState,
                          kpis,
                          controller,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Zone 3: High-Density Account Sliver List
              ...switch (asyncItems) {
                AsyncValue(:final value?) => _buildDataSlivers(
                  context,
                  ref,
                  value,
                  opsState,
                  controller,
                ),
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorStateView(
                      message: error.toString(),
                      onRetry: () {
                        ref.invalidate(rdAllSparseInstallmentsStreamProvider);
                        ref.invalidate(rawMonthlyOperationsStreamProvider);
                      },
                    ),
                  ),
                ],
                _ => [_buildLoadingSliver()],
              },
            ],
          ),
        ),

        // Batch PO Action Bar at the bottom
        if (opsState.isSelectionMode &&
            opsState.selectedInstallmentIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBatchActionBar(context, ref, opsState, controller),
          ),
      ],
    );
  }

  Widget _buildPriorArrearsBanner(
    BuildContext context,
    RDMonthlyKpiSummary kpis,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: () => controller.setFilter(RDMonthlyFilter.overdue),
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
                  onPressed: () =>
                      controller.setFilter(RDMonthlyFilter.overdue),
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

  Widget _buildPoQueueReadyStrip(
    BuildContext context,
    RDMonthlyKpiSummary kpis,
    List<RDMonthlyOperationItem> items,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final banner = t.recurringDeposits.monthlyOperations.poQueueBanner;

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
                  final readyIds = items
                      .where((i) => i.isReadyForPo)
                      .map((i) => i.installment.id)
                      .toList();
                  controller.selectAll(readyIds);
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

  Widget _buildCompactToolbar(
    BuildContext context,
    RDMonthlyOperationsState state,
    RDMonthlyKpiSummary kpis,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final toolbar = ops.toolbar;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          FilterChip(
            visualDensity: VisualDensity.compact,
            label: Text(toolbar.windowAll),
            selected: state.dueWindowFilter == RDDueWindowFilter.all,
            onSelected: (_) =>
                controller.setDueWindowFilter(RDDueWindowFilter.all),
          ),
          AppSpacings.gapXs,
          FilterChip(
            visualDensity: VisualDensity.compact,
            label: Text(toolbar.window15th(count: kpis.firstHalfCount)),
            selected: state.dueWindowFilter == RDDueWindowFilter.firstHalf,
            onSelected: (_) =>
                controller.setDueWindowFilter(RDDueWindowFilter.firstHalf),
          ),
          AppSpacings.gapXs,
          FilterChip(
            visualDensity: VisualDensity.compact,
            label: Text(toolbar.windowEom(count: kpis.secondHalfCount)),
            selected: state.dueWindowFilter == RDDueWindowFilter.secondHalf,
            onSelected: (_) =>
                controller.setDueWindowFilter(RDDueWindowFilter.secondHalf),
          ),
          AppSpacings.gapXs,
          FilterChip(
            visualDensity: VisualDensity.compact,
            avatar: HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              size: AppDimensions.iconXs,
              color: state.groupByCustomer
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(ops.filters.byCustomer),
            selected: state.groupByCustomer,
            onSelected: (_) => controller.toggleGroupByCustomer(),
          ),
          AppSpacings.gapXs,
          ActionChip(
            visualDensity: VisualDensity.compact,
            avatar: HugeIcon(
              icon: state.isSelectionMode
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedCheckList,
              size: AppDimensions.iconXs,
              color: state.isSelectionMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(
              state.isSelectionMode
                  ? ops.card.doneSelectMode
                  : ops.card.selectMode,
            ),
            backgroundColor: state.isSelectionMode
                ? theme.colorScheme.primaryContainer
                : null,
            onPressed: () => controller.toggleSelectionMode(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataSlivers(
    BuildContext context,
    WidgetRef ref,
    List<RDMonthlyOperationItem> items,
    RDMonthlyOperationsState state,
    RDMonthlyOperationsController controller,
  ) {
    final ops = t.recurringDeposits.monthlyOperations;

    if (items.isEmpty) {
      final hasFilters =
          state.selectedFilter != RDMonthlyFilter.all ||
          state.dueWindowFilter != RDDueWindowFilter.all ||
          state.searchQuery.isNotEmpty;

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasFilters ? ops.noFilterResults : ops.noInstallments,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasFilters) ...[
                    AppSpacings.gapMd,
                    TextButton.icon(
                      onPressed: () {
                        controller.setFilter(RDMonthlyFilter.all);
                        controller.setDueWindowFilter(RDDueWindowFilter.all);
                        controller.setSearchQuery('');
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterRemove,
                        size: AppDimensions.iconSm,
                      ),
                      label: Text(t.common.clearFilters),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }

    const bottomPadding = AppDimensions.listBottomPaddingFAB;
    final evaluationDate = ref.watch(clockProvider)();

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: bottomPadding),
        sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final item = items[index];
          final installment = item.installment;
          final isSelected = state.selectedInstallmentIds.contains(
            installment.id,
          );
          final showCustomerHeader =
              state.groupByCustomer &&
              (index == 0 ||
                  items[index - 1].deposit.customerId !=
                      item.deposit.customerId);

          final cardWidget = RDMonthlyOperationCard(
            item: item,
            evaluationDate: evaluationDate,
            isSelected: isSelected,
            isSelectionMode: state.isSelectionMode,
            onSelect: (val) => controller.toggleSelection(installment.id),
            onTap: () {
              RecurringDepositDetailRoute(item.deposit.id).push(context);
            },
            onLogPayment: () async {
              final prepared = await controller.prepareLogPayment(item);
              if (!context.mounted) return;

              switch (prepared) {
                case Failure(error: final err):
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(err),
                    ),
                  );
                case Success(:final value):
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => RDLogPaymentSheet(
                      deposit: item.deposit,
                      currentSchedule: value.schedule,
                      initialAmount: value.initialAmount,
                      initialSplitMode: value.splitMode,
                    ),
                  );
              }
            },
            onLongPress: () {
              if (!state.isSelectionMode) {
                controller.toggleSelection(installment.id);
              }
            },
            onDepositToPo: () async {
              final ledger = ref.read(rDLedgerControllerProvider.notifier);
              final updated = installment.copyWith(
                poStatus: RDPoStatus.paid,
                poPaidDate: ref.read(clockProvider)(),
              );
              final res = await ledger.recordPoPayments(
                installments: [updated],
              );
              if (context.mounted && res is Success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ops.batchPo.success(count: 1)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onAdvanceToPo: () async {
              final confirmed = await AppDialogs.confirmAction(
                context,
                title: ops.card.advanceToPoConfirmTitle,
                content: ops.card.advanceToPoConfirmMessage(
                  installment: item.installmentNumber.toString(),
                  amount: installment.installmentAmount.toRupeeFormat(),
                ),
                confirmText: t.common.confirm,
              );

              if (confirmed == true && context.mounted) {
                final ledger = ref.read(rDLedgerControllerProvider.notifier);
                final updated = installment.copyWith(
                  poStatus: RDPoStatus.paid,
                  poPaidDate: ref.read(clockProvider)(),
                );
                final res = await ledger.recordPoPayments(
                  installments: [updated],
                );
                if (context.mounted && res is Success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ops.card.advanceSuccess(
                          installment: item.installmentNumber.toString(),
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            onRevertPo: () async {
              final theme = Theme.of(context);
              final confirmed = await AppDialogs.confirmAction(
                context,
                title: ops.card.revertPoConfirmTitle,
                content: ops.card.revertPoConfirmMessage(
                  installment: item.installmentNumber.toString(),
                ),
                confirmText: t.common.confirm,
                confirmBackgroundColor: theme.colorScheme.error,
                confirmForegroundColor: theme.colorScheme.onError,
              );

              if (confirmed == true && context.mounted) {
                final ledger = ref.read(rDLedgerControllerProvider.notifier);
                final res = await ledger.revertPoPayments(
                  installments: [installment],
                );
                if (context.mounted && res is Success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ops.card.revertSuccess(
                          installment: item.installmentNumber.toString(),
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            onToggleLateFeeWaiver: () async {
              final feeAmount = item.totalDefaultFee(ref.read(clockProvider)());
              final confirmed = await AppDialogs.confirmAction(
                context,
                title: ops.card.forgiveFeeConfirmTitle,
                content: ops.card.forgiveFeeConfirmMessage(
                  installment: item.installmentNumber.toString(),
                  amount: feeAmount.toRupeeFormat(),
                ),
                confirmText: ops.card.forgiveFee,
              );

              if (confirmed == true && context.mounted) {
                final ledger = ref.read(rDLedgerControllerProvider.notifier);
                final res = await ledger.toggleLateFeeWaiver(
                  installmentId: installment.id,
                  isWaived: true,
                  installment: installment,
                );
                if (context.mounted && res is Success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ops.card.forgiveFeeSuccess(
                          installment: item.installmentNumber.toString(),
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          );

          if (!showCustomerHeader) return cardWidget;

          final customerItems = items
              .where((i) => i.deposit.customerId == item.deposit.customerId)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerGroupHeader(
                context,
                item.deposit.customerName ??
                    t.recurringDeposits.depositNotFound,
                customerItems,
                controller,
              ),
              cardWidget,
            ],
          );
        },
        ),
      ),
    ];
  }

  Widget _buildAgentFloatStrip(
    BuildContext context,
    RDAgentFloatSummary floatSummary,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final floatStrings = t.recurringDeposits.monthlyOperations.agentFloat;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          if (floatSummary.undepositedCashCount > 0)
            InkWell(
              onTap: () => controller.setFilter(RDMonthlyFilter.readyForPo),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedBuilding03,
                      size: AppDimensions.iconXs,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    AppSpacings.gapXs,
                    Text(
                      floatStrings.cashInHand(
                        amount: floatSummary.undepositedCashAmount
                            .toRupeeFormat(),
                        count: floatSummary.undepositedCashCount,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (floatSummary.undepositedCashCount > 0 &&
              floatSummary.pocketAdvancesCount > 0)
            AppSpacings.gapSm,
          if (floatSummary.pocketAdvancesCount > 0)
            InkWell(
              onTap: () => controller.setFilter(RDMonthlyFilter.toCollect),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedFlash,
                      size: AppDimensions.iconXs,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    AppSpacings.gapXs,
                    Text(
                      floatStrings.pocketAdvances(
                        amount: floatSummary.pocketAdvancesAmount
                            .toRupeeFormat(),
                        count: floatSummary.pocketAdvancesCount,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerGroupHeader(
    BuildContext context,
    String customerName,
    List<RDMonthlyOperationItem> customerItems,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final groupStrings = t.recurringDeposits.monthlyOperations.customerGroup;
    final totalMonthly = customerItems.fold<double>(
      0.0,
      (sum, i) => sum + i.deposit.installmentAmount,
    );

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingXs,
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUser,
            size: AppDimensions.iconSm,
            color: theme.colorScheme.primary,
          ),
          AppSpacings.gapXs,
          Expanded(
            child: Text(
              '$customerName • ${groupStrings.accountsSummary(count: customerItems.length, amount: totalMonthly.toRupeeFormat())}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSm,
              ),
            ),
            onPressed: () {
              final ids = customerItems.map((i) => i.installment.id).toList();
              controller.selectAll(ids);
            },
            child: Text(
              groupStrings.selectGroup,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionBar(
    BuildContext context,
    WidgetRef ref,
    RDMonthlyOperationsState state,
    RDMonthlyOperationsController controller,
  ) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations.batchPo;

    final asyncItems = ref.watch(rawMonthlyOperationsStreamProvider);
    final items = asyncItems.value ?? [];
    final selectedItems = items
        .where(
          (item) => state.selectedInstallmentIds.contains(item.installment.id),
        )
        .toList();

    final canDepositList = selectedItems
        .where((i) => i.canDepositToPo)
        .toList();
    final canRevertList = selectedItems.where((i) => i.canRevertPo).toList();
    final count = state.selectedInstallmentIds.length;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(AppDimensions.paddingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingSm,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: AppDimensions.iconSm,
              ),
              tooltip: ops.deselectAll,
              onPressed: controller.clearSelection,
            ),
            AppSpacings.gapXs,
            Expanded(
              child: Text(
                ops.selectedSummary(count: count, amount: ''),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (canRevertList.isNotEmpty) ...[
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final confirmed = await AppDialogs.confirmAction(
                    context,
                    title: ops.revertConfirmTitle,
                    content: ops.revertConfirmMessage(
                      count: canRevertList.length,
                    ),
                    confirmText: ops.revertButton,
                    confirmBackgroundColor: theme.colorScheme.error,
                    confirmForegroundColor: theme.colorScheme.onError,
                  );

                  if (confirmed == true && context.mounted) {
                    final installments = canRevertList
                        .map((item) => item.installment)
                        .toList();

                    final result = await controller.revertSelectedPo(
                      installments,
                    );
                    if (context.mounted && result is Success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ops.revertSuccess(count: canRevertList.length),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowTurnBackward,
                  size: AppDimensions.iconXs,
                  color: theme.colorScheme.onErrorContainer,
                ),
                label: Text(ops.revertAction(count: canRevertList.length)),
              ),
              if (canDepositList.isNotEmpty) AppSpacings.gapXs,
            ],
            if (canDepositList.isNotEmpty)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final totalDepositAmount = canDepositList.fold<double>(
                    0.0,
                    (sum, i) => sum + i.installment.installmentAmount,
                  );
                  final collectedItems = canDepositList
                      .where((i) => i.installment.isInstallmentPaid)
                      .toList();
                  final advanceItems = canDepositList
                      .where((i) => !i.installment.isInstallmentPaid)
                      .toList();

                  final message =
                      (advanceItems.isNotEmpty && collectedItems.isNotEmpty)
                      ? '${ops.confirmMessage(count: canDepositList.length, amount: totalDepositAmount.toRupeeFormat())}\n\n${ops.confirmBreakdown(collectedCount: collectedItems.length.toString(), advanceCount: advanceItems.length.toString())}'
                      : ops.confirmMessage(
                          count: canDepositList.length,
                          amount: totalDepositAmount.toRupeeFormat(),
                        );

                  final confirmed = await AppDialogs.confirmAction(
                    context,
                    title: ops.confirmTitle,
                    content: message,
                    confirmText: ops.confirmButton,
                  );

                  if (confirmed == true && context.mounted) {
                    final installments = canDepositList
                        .map((item) => item.installment)
                        .toList();

                    final result = await controller.depositSelectedToPo(
                      installments,
                    );
                    if (context.mounted && result is Success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ops.success(count: canDepositList.length),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedBuilding03,
                  size: AppDimensions.iconSm,
                  color: theme.colorScheme.onPrimary,
                ),
                label: Text(ops.confirmButton),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.listBottomPaddingFAB,
      ),
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          return Skeletonizer(
            enabled: true,
            child: RDMonthlyOperationCard.skeleton(),
          );
        },
      ),
    );
  }
}
