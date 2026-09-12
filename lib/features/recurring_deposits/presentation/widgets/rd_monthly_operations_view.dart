import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
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
    final asyncItems = ref.watch(filteredMonthlyOperationsProvider);
    final ops = t.recurringDeposits.monthlyOperations;

    return Stack(
      children: [
        Column(
          children: [
            AppSpacings.gapSm,

            // Month Switcher
            RDMonthSwitcher(
              selectedMonth: opsState.selectedMonth,
              onPrevious: controller.previousMonth,
              onNext: controller.nextMonth,
              onResetToCurrent: controller.resetToCurrentMonth,
            ),

            AppSpacings.gapMd,

            // KPI Summary Row
            RDMonthlyKpiRow(
              summary: kpis,
              selectedFilter: opsState.selectedFilter,
              onFilterSelected: controller.setFilter,
            ),

            if (kpis.priorArrearsAccountsCount > 0) ...[
              AppSpacings.gapSm,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: Material(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: InkWell(
                    onTap: () => controller.setFilter(RDMonthlyFilter.overdue),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMd,
                        vertical: AppDimensions.paddingSm,
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
              ),
            ],

            AppSpacings.gapMd,

            // Search Bar
            AppSearchBar(
              hintText: ops.searchHint,
              onChanged: controller.setSearchQuery,
            ),

            AppSpacings.gapSm,

            // Operational Filter Chips
            _buildFilterChips(context, ref, opsState, kpis, controller),

            AppSpacings.gapSm,

            // Items List
            Expanded(
              child: switch (asyncItems) {
                AsyncData(:final value) => _buildDataList(
                  context,
                  ref,
                  value,
                  opsState,
                  controller,
                ),
                AsyncError(:final error) => ErrorStateView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(rawMonthlyOperationsStreamProvider),
                ),
                _ => _buildLoadingList(),
              },
            ),
          ],
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

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    RDMonthlyOperationsState state,
    RDMonthlyKpiSummary kpis,
    RDMonthlyOperationsController controller,
  ) {
    final ops = t.recurringDeposits.monthlyOperations;
    final filters = ops.filters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          FilterChip(
            label: Text(filters.all(count: kpis.totalCount)),
            selected: state.selectedFilter == RDMonthlyFilter.all,
            onSelected: (_) => controller.setFilter(RDMonthlyFilter.all),
          ),
          AppSpacings.gapXs,
          FilterChip(
            label: Text(filters.toCollect(count: kpis.toCollectCount)),
            selected: state.selectedFilter == RDMonthlyFilter.toCollect,
            onSelected: (_) => controller.setFilter(RDMonthlyFilter.toCollect),
          ),
          AppSpacings.gapXs,
          FilterChip(
            label: Text(filters.readyForPo(count: kpis.readyForPoCount)),
            selected: state.selectedFilter == RDMonthlyFilter.readyForPo,
            onSelected: (_) => controller.setFilter(RDMonthlyFilter.readyForPo),
          ),
          AppSpacings.gapXs,
          FilterChip(
            label: Text(filters.settled(count: kpis.settledCount)),
            selected: state.selectedFilter == RDMonthlyFilter.settled,
            onSelected: (_) => controller.setFilter(RDMonthlyFilter.settled),
          ),
          AppSpacings.gapXs,
          FilterChip(
            label: Text(filters.overdue(count: kpis.overdueCount)),
            selected: state.selectedFilter == RDMonthlyFilter.overdue,
            onSelected: (_) => controller.setFilter(RDMonthlyFilter.overdue),
          ),
          AppSpacings.gapXs,
          ActionChip(
            avatar: HugeIcon(
              icon: state.isSelectionMode
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedCheckList,
              size: AppDimensions.iconXs,
              color: state.isSelectionMode
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              state.isSelectionMode
                  ? ops.card.doneSelectMode
                  : ops.card.selectMode,
            ),
            backgroundColor: state.isSelectionMode
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            onPressed: () => controller.toggleSelectionMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList(
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
          state.searchQuery.isNotEmpty;

      return Center(
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
      );
    }

    const bottomPadding = AppDimensions.listBottomPaddingFAB;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rawMonthlyOperationsStreamProvider);
      },
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final item = items[index];
          final installment = item.installment;
          final isSelected = state.selectedInstallmentIds.contains(
            installment.id,
          );

          return RDMonthlyOperationCard(
            item: item,
            isSelected: isSelected,
            isSelectionMode: state.isSelectionMode,
            onSelect: (val) => controller.toggleSelection(installment.id),
            onTap: () {
              RecurringDepositDetailRoute(item.deposit.id).push(context);
            },
            onLogPayment: () async {
              final repository = ref.read(recurringDepositRepositoryProvider);
              final scheduleResult = await repository.getRDInstallments(
                item.deposit.id,
              );
              if (!context.mounted) return;

              final schedule = switch (scheduleResult) {
                Success(value: final list) => list,
                Failure() => <RDInstallment>[],
              };

              if (schedule.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      scheduleResult is Failure<List<RDInstallment>, String>
                          ? scheduleResult.error
                          : t.recurringDeposits.depositNotFound,
                    ),
                  ),
                );
                return;
              }

              final now = DateTime.now();
              final isFeeOnly = item.isFeePending;
              final amount = isFeeOnly
                  ? item.totalDefaultFee(now)
                  : item.totalOutstandingPayable(now);
              final splitMode = isFeeOnly
                  ? PaymentSplitMode.feesOnly
                  : (item.hasOverdueDebt(now) && item.totalDefaultFee(now) > 0
                        ? PaymentSplitMode.includeFees
                        : null);

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => RDLogPaymentSheet(
                  deposit: item.deposit,
                  currentSchedule: schedule,
                  initialAmount: amount,
                  initialSplitMode: splitMode,
                ),
              );
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
                poPaidDate: DateTime.now(),
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
              final confirmed = await showAdaptiveDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(ops.card.advanceToPoConfirmTitle),
                  content: Text(
                    ops.card.advanceToPoConfirmMessage(
                      installment: item.installmentNumber.toString(),
                      amount: installment.installmentAmount.toRupeeFormat(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(t.common.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(t.common.confirm),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                final ledger = ref.read(rDLedgerControllerProvider.notifier);
                final updated = installment.copyWith(
                  poStatus: RDPoStatus.paid,
                  poPaidDate: DateTime.now(),
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
              final confirmed = await showAdaptiveDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(ops.card.revertPoConfirmTitle),
                  content: Text(
                    ops.card.revertPoConfirmMessage(
                      installment: item.installmentNumber.toString(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(t.common.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(t.common.confirm),
                    ),
                  ],
                ),
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
              final feeAmount = item.totalDefaultFee(DateTime.now());
              final confirmed = await showAdaptiveDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(ops.card.forgiveFeeConfirmTitle),
                  content: Text(
                    ops.card.forgiveFeeConfirmMessage(
                      installment: item.installmentNumber.toString(),
                      amount: feeAmount.toRupeeFormat(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(t.common.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(ops.card.forgiveFee),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                final ledger = ref.read(rDLedgerControllerProvider.notifier);
                final res = await ledger.toggleLateFeeWaiver(
                  installmentId: installment.id,
                  isWaived: true,
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
        },
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
                  final confirmed = await showAdaptiveDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(ops.revertConfirmTitle),
                      content: Text(
                        ops.revertConfirmMessage(count: canRevertList.length),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(t.common.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(ops.revertButton),
                        ),
                      ],
                    ),
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

                  final confirmed = await showAdaptiveDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(ops.confirmTitle),
                      content: Text(message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(t.common.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(ops.confirmButton),
                        ),
                      ],
                    ),
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

  Widget _buildLoadingList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          return RDMonthlyOperationCard.skeleton();
        },
      ),
    );
  }
}
