import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
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

    Future<void> undoLatest() async {
      final result = await actions.undoLatestDeposit(item);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.undoLatestDepositSuccess,
      );
    }

    Future<void> onCollect() async {
      await showRDLogPaymentSheet(
        context,
        rdId: item.deposit.id,
        initialAmount: item.initialPaymentAmount,
      );
    }

    Future<void> onDeposit() async {
      await showRDDepositSheet(
        context,
        rdId: item.deposit.id,
        initialCount: item.readyForPoCount,
      );
    }

    /// Front from pocket: open the deposit sheet pre-set to carry the PO ledger through this
    /// row's month (the quote shows exactly how much comes from the agent's pocket).
    Future<void> onDepositFromPocket() async {
      final through = item.summary.depositedThroughNo;
      final target = item.installment.installmentNo;
      await showRDDepositSheet(
        context,
        rdId: item.deposit.id,
        initialCount: through < target ? target - through : 1,
      );
    }

    Future<void> onUndoLatestDeposit() async {
      final scheme = Theme.of(context).colorScheme;
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.undoLatestDepositConfirmTitle,
        content: card.undoLatestDepositConfirmMessage,
        confirmText: t.common.confirm,
        confirmBackgroundColor: scheme.error,
        confirmForegroundColor: scheme.onError,
      );
      if (confirmed != true || !context.mounted) return;
      await undoLatest();
    }

    Future<void> onAbsorbFee() async {
      // The one absorb rule: exactly `absorbableFee`, offered only when it closes the month.
      final fee = item.installment.absorbableFee.toRupeeFormat();
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.absorbFeeConfirmTitle,
        content: card.absorbFeeConfirmMessage(installment: installmentNo, amount: fee),
        confirmText: t.common.confirm,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.absorbRemainingFee(item);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.absorbFeeSuccess(installment: installmentNo, amount: fee),
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
      onCollect: onCollect,
      onDeposit: onDeposit,
      onDepositFromPocket: isBusy ? null : onDepositFromPocket,
      onUndoLatestDeposit: isBusy ? null : onUndoLatestDeposit,
      onAbsorbFee: isBusy ? null : onAbsorbFee,
    );
  }
}
