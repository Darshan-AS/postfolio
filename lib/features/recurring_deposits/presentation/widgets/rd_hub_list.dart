import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

const int _skeletonRowCount = 5;

/// The hub's row list as a sliver. Flat when ungrouped; one header + list per household when
/// "group by customer" is on. Loading / error / empty states are rendered in place.
class RDHubList extends ConsumerWidget {
  const RDHubList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupByCustomer = ref.watch(rDHubFiltersProvider.select((s) => s.groupByCustomer));
    final now = ref.watch(clockProvider)();

    if (groupByCustomer) {
      return switch (ref.watch(groupedMonthlyOperationsProvider)) {
        AsyncData(:final value) => value.isEmpty
            ? const _EmptySliver()
            : SliverPadding(
                padding: const EdgeInsets.only(bottom: AppDimensions.listBottomPaddingFAB),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    for (final group in value) ...[
                      SliverToBoxAdapter(
                        key: ValueKey('group-${group.customerId}'),
                        child: _CustomerGroupHeader(group: group),
                      ),
                      _ItemsSliver(items: group.items, now: now),
                    ],
                  ],
                ),
              ),
        AsyncError(:final error) => _ErrorSliver(error: error),
        AsyncLoading() => const _LoadingSliver(),
      };
    }

    return switch (ref.watch(filteredMonthlyOperationsProvider)) {
      AsyncData(:final value) => value.isEmpty
          ? const _EmptySliver()
          : SliverPadding(
              padding: const EdgeInsets.only(bottom: AppDimensions.listBottomPaddingFAB),
              sliver: _ItemsSliver(items: value, now: now),
            ),
      AsyncError(:final error) => _ErrorSliver(error: error),
      AsyncLoading() => const _LoadingSliver(),
    };
  }
}

class _ItemsSliver extends StatelessWidget {
  final List<RDMonthlyOperationItem> items;
  final DateTime now;

  const _ItemsSliver({required this.items, required this.now});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: AppDimensions.dividerHeight),
      itemBuilder: (context, index) {
        final item = items[index];
        return _RDHubRow(key: ValueKey(item.installment.id), item: item, now: now);
      },
    );
  }
}

class _ErrorSliver extends ConsumerWidget {
  final Object error;

  const _ErrorSliver({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorStateView(
        message: error.toString(),
        onRetry: () => ref.invalidate(monthlyOperationItemsProvider),
      ),
    );
  }
}

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppDimensions.listBottomPaddingFAB),
      sliver: SliverList.separated(
        itemCount: _skeletonRowCount,
        separatorBuilder: (context, index) => const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) => Skeletonizer(
          enabled: true,
          child: RDMonthlyOperationCard.skeleton(),
        ),
      ),
    );
  }
}

class _EmptySliver extends ConsumerWidget {
  const _EmptySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final hasFilters = ref.watch(rDHubFiltersProvider.select((s) => s.hasActiveFilters));

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hasFilters ? ops.noFilterResults : ops.noInstallments,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasFilters) ...[
                AppSpacings.gapMd,
                TextButton.icon(
                  onPressed: ref.read(rDHubFiltersProvider.notifier).clear,
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
    );
  }
}

class _CustomerGroupHeader extends ConsumerWidget {
  final RDCustomerGroup group;

  const _CustomerGroupHeader({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupStrings = t.recurringDeposits.monthlyOperations.customerGroup;

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
              '${group.customerName}${t.format.bulletSeparator}${groupStrings.accountsSummary(count: group.items.length, amount: group.monthlyTotal.toRupeeFormat())}',
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSm),
            ),
            onPressed: () => ref
                .read(rDHubSelectionProvider.notifier)
                .selectAll([for (final i in group.items) i.installment.id]),
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
}

/// One row: owns the per-row selection subscription and routes every action through
/// `RDMonthlyOperationsActions`, surfacing each `Result` via [AppFeedback].
class _RDHubRow extends ConsumerWidget {
  final RDMonthlyOperationItem item;
  final DateTime now;

  const _RDHubRow({super.key, required this.item, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = item.installment.id;
    final card = t.recurringDeposits.monthlyOperations.card;
    final installmentNo = item.installmentNumber.toString();

    final isSelectionMode = ref.watch(rDHubSelectionProvider.select((s) => s.isSelectionMode));
    final isSelected = ref.watch(rDHubSelectionProvider.select((s) => s.contains(id)));
    final isBusy = ref.watch(rDLedgerControllerProvider.select((a) => a.isLoading));
    final selection = ref.read(rDHubSelectionProvider.notifier);
    final actions = ref.read(rDMonthlyOperationsActionsProvider.notifier);

    Future<void> revert() async {
      final result = await actions.revertPo([item]);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.revertSuccess(installment: installmentNo),
      );
    }

    Future<void> onLogPayment() async {
      final prepared = await actions.prepareLogPayment(item);
      if (!context.mounted) return;
      switch (prepared) {
        case Success(:final value):
          await showRDLogPaymentSheet(
            context,
            rdId: item.deposit.id,
            initialAmount: value.initialAmount,
            initialSplitMode: value.splitMode,
          );
        case Failure(:final error):
          AppFeedback.showError(context, error);
      }
    }

    Future<void> onDepositToPo() async {
      final result = await actions.depositToPo([item]);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.depositSuccess(installment: installmentNo),
        undoLabel: t.recurringDeposits.monthlyOperations.undo,
        onUndo: revert,
      );
    }

    Future<void> onDepositFromPocket() async {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.advanceToPoConfirmTitle,
        content: card.advanceToPoConfirmMessage(
          installment: installmentNo,
          amount: item.installment.outstandingPrincipal.toRupeeFormat(),
        ),
        confirmText: t.common.confirm,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.depositToPo([item]);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.advanceSuccess(installment: installmentNo),
        undoLabel: t.recurringDeposits.monthlyOperations.undo,
        onUndo: revert,
      );
    }

    Future<void> onRevertPo() async {
      final scheme = Theme.of(context).colorScheme;
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.revertPoConfirmTitle,
        content: card.revertPoConfirmMessage(installment: installmentNo),
        confirmText: t.common.confirm,
        confirmBackgroundColor: scheme.error,
        confirmForegroundColor: scheme.onError,
      );
      if (confirmed != true || !context.mounted) return;
      await revert();
    }

    Future<void> onForgiveFee() async {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.forgiveFeeConfirmTitle,
        content: card.forgiveFeeConfirmMessage(
          installment: installmentNo,
          amount: item.totalDefaultFee(now).toRupeeFormat(),
        ),
        confirmText: card.forgiveFee,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.forgiveFee(item);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.forgiveFeeSuccess(installment: installmentNo),
      );
    }

    return RDMonthlyOperationCard(
      item: item,
      evaluationDate: now,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      isBusy: isBusy,
      onSelect: (_) => selection.toggle(id),
      onTap: () => RecurringDepositDetailRoute(item.deposit.id).push(context),
      onLongPress: () {
        if (!isSelectionMode) selection.toggle(id);
      },
      onLogPayment: onLogPayment,
      onDepositToPo: onDepositToPo,
      onDepositFromPocket: isBusy ? null : onDepositFromPocket,
      onRevertPo: isBusy ? null : onRevertPo,
      onForgiveFee: isBusy ? null : onForgiveFee,
    );
  }
}
