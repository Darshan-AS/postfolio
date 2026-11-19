import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

const int _skeletonRowCount = 5;

/// The hub's rows as a sliver, inset by the page margin. Every run of rows is a group of
/// tiles: the whole list when ungrouped; one group per customer, under that customer's
/// header, when "group by customer" is on. Loading / error / empty states are rendered in
/// place.
class RDHubList extends ConsumerWidget {
  const RDHubList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupByCustomer = ref.watch(
      rDHubFiltersProvider.select((s) => s.groupByCustomer),
    );
    final now = ref.watch(clockProvider)();

    // The room under the last row clears the floating batch bar, which grows with the text.
    final padding = EdgeInsets.fromLTRB(
      AppDimensions.pageMargin,
      0,
      AppDimensions.pageMargin,
      MediaQuery.textScalerOf(
        context,
      ).scale(AppDimensions.listBottomPaddingFAB),
    );

    if (groupByCustomer) {
      return switch (ref.watch(groupedMonthlyOperationsProvider)) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const _EmptySliver()
              : SliverPadding(
                  padding: padding,
                  sliver: SliverList.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final group = value[index];
                      return _CustomerGroup(
                        key: ValueKey('group-${group.customerId}'),
                        group: group,
                        now: now,
                        isFirst: index == 0,
                      );
                    },
                  ),
                ),
        AsyncError(:final error) => _ErrorSliver(error: error),
        AsyncLoading() => _LoadingSliver(padding: padding),
      };
    }

    return switch (ref.watch(filteredMonthlyOperationsProvider)) {
      AsyncData(:final value) =>
        value.isEmpty
            ? const _EmptySliver()
            : SliverPadding(
                padding: padding,
                sliver: SliverList.separated(
                  itemCount: value.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppShapes.groupGap),
                  itemBuilder: (context, index) {
                    final item = value[index];
                    return _RDHubRow(
                      key: ValueKey(item.installment.id),
                      item: item,
                      now: now,
                      position: AppGroupPosition.at(index, value.length),
                    );
                  },
                ),
              ),
      AsyncError(:final error) => _ErrorSliver(error: error),
      AsyncLoading() => _LoadingSliver(padding: padding),
    };
  }
}

/// One customer's block. A customer with several accounts gets a header and the accounts
/// under it as one group of tiles, titled by serial and account. A customer with one
/// account is just that row: a header would repeat the name the row already carries.
/// Built lazily, one block per list item, so a long list only builds the customers on screen.
class _CustomerGroup extends StatelessWidget {
  final RDCustomerGroup group;
  final DateTime now;

  /// The first block needs no gap above it.
  final bool isFirst;

  const _CustomerGroup({
    super.key,
    required this.group,
    required this.now,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final items = group.items;
    final hasHeader = items.length > 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isFirst) AppSpacings.gapSm,
        if (hasHeader) _CustomerGroupHeader(group: group),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppShapes.groupGap),
          _RDHubRow(
            key: ValueKey(items[i].installment.id),
            item: items[i],
            now: now,
            position: AppGroupPosition.at(i, items.length),
            titleByAccount: hasHeader,
          ),
        ],
      ],
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
  final EdgeInsets padding;

  const _LoadingSliver({required this.padding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: _skeletonRowCount,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppShapes.groupGap),
        itemBuilder: (context, index) => Skeletonizer(
          enabled: true,
          child: RDMonthlyOperationCard.skeleton(
            position: AppGroupPosition.at(index, _skeletonRowCount),
          ),
        ),
      ),
    );
  }
}

/// Three empty states, told apart so the agent knows whether to relax or re-filter:
/// * no rows at all in the month → "No installments due in `Month`"
/// * a status filter hides every row but nothing is left to collect → "All settled for `Month`"
/// * anything else with active filters → "No accounts match" + clear filters
class _EmptySliver extends ConsumerWidget {
  const _EmptySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = t.recurringDeposits.monthlyOperations;
    final filters = ref.watch(rDHubFiltersProvider);
    final month = ref.watch(rDHubMonthProvider);
    final totalCount = ref.watch(
      monthlyOperationsKpiProvider.select((k) => k.totalCount),
    );
    final toCollectCount = ref.watch(
      monthlyOperationsKpiProvider.select((k) => k.toCollectCount),
    );
    final monthLabel = DateFormat.yMMM(resolvedDateLocale()).format(month);

    final hasFilters = filters.hasActiveFilters;
    final isCollectFilter =
        filters.status == RDMonthlyFilter.toCollect ||
        filters.status == RDMonthlyFilter.overdue;
    final onlyStatusFilter =
        filters.searchQuery.isEmpty &&
        filters.dueWindow == RDDueWindowFilter.all;
    final allSettled =
        totalCount > 0 &&
        toCollectCount == 0 &&
        isCollectFilter &&
        onlyStatusFilter;

    final (message, icon) = totalCount == 0
        ? (
            ops.noInstallmentsIn(month: monthLabel),
            HugeIcons.strokeRoundedInbox,
          )
        : allSettled
        ? (
            ops.allSettledFor(month: monthLabel),
            HugeIcons.strokeRoundedCheckmarkBadge01,
          )
        : (ops.noFilterResults, HugeIcons.strokeRoundedSearchRemove);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateView(
        message: message,
        icon: icon,
        actionLabel: t.common.clearFilters,
        actionIcon: HugeIcons.strokeRoundedFilterRemove,
        onAction: hasFilters
            ? ref.read(rDHubFiltersProvider.notifier).clear
            : null,
      ),
    );
  }
}

/// The line above a customer's group: who, how many accounts, how much a month, and a
/// way to select them all. The text wraps rather than cutting the amount; at large text
/// sizes the button drops under it so the text keeps the full width.
class _CustomerGroupHeader extends ConsumerWidget {
  final RDCustomerGroup group;

  const _CustomerGroupHeader({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final groupStrings = t.recurringDeposits.monthlyOperations.customerGroup;

    final title = Row(
      children: [
        AppIcon(
          HugeIcons.strokeRoundedUser,
          size: AppDimensions.iconSm,
          color: scheme.primary,
        ),
        AppSpacings.gapSm,
        Expanded(
          child: Text(
            groupStrings.header(
              name: group.customerName,
              n: group.items.length,
              amount: group.monthlyTotal.toRupeeFormat(),
            ),
            style: AppTypography.emphasizedOf(
              context,
            ).labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    final selectAll = Tooltip(
      message: groupStrings.selectGroupFor(name: group.customerName),
      child: AppButton.text(
        label: groupStrings.selectGroup,
        onPressed: () => ref.read(rDHubSelectionProvider.notifier).selectAll([
          for (final i in group.items) i.installment.id,
        ]),
      ),
    );

    return Padding(
      // Lines the text up with the content of the tiles below.
      padding: const EdgeInsets.only(left: AppDimensions.paddingLg),
      child: RDHubLayout.isLargeText(context)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [title, selectAll],
            )
          : Row(
              children: [
                Expanded(child: title),
                selectAll,
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

  /// Where the row sits in its group of tiles.
  final AppGroupPosition position;

  /// The row sits under its customer's header, so it is titled by serial and account.
  final bool titleByAccount;

  const _RDHubRow({
    super.key,
    required this.item,
    required this.now,
    required this.position,
    this.titleByAccount = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = item.installment.id;
    final card = t.recurringDeposits.monthlyOperations.card;
    final installmentNo = item.installmentNumber.toString();

    final isSelectionMode = ref.watch(
      rDHubSelectionProvider.select((s) => s.isSelectionMode),
    );
    final isSelected = ref.watch(
      rDHubSelectionProvider.select((s) => s.contains(id)),
    );
    final isBusy = ref.watch(
      rDLedgerControllerProvider.select((a) => a.isLoading),
    );
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
        content: card.absorbFeeConfirmMessage(
          installment: installmentNo,
          amount: fee,
        ),
        confirmText: t.common.confirm,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.absorbRemainingFee(item);
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: card.absorbFeeSuccess(
          installment: installmentNo,
          amount: fee,
        ),
      );
    }

    final status = item.displayStatus(now);
    final statusLabel = status.visualOf(context).label;
    final customerName =
        item.deposit.customerName ?? t.recurringDeposits.unnamedCustomer;
    final serial = item.deposit.serialNo ?? t.common.notProvided;
    final overdueDays = item.installment.overdueDaysAt(now);
    // One sentence per row for screen readers: who, which account, where it stands.
    final semanticLabel = !item.isCustomerPending
        ? card.semanticsSettled(
            name: customerName,
            serial: serial,
            status: statusLabel,
          )
        : item.isOverdue(now) && overdueDays > 0
        ? card.semanticsOverdue(
            name: customerName,
            serial: serial,
            status: statusLabel,
            amount: item.totalOutstanding.toRupeeFormat(),
            days: overdueDays.toString(),
          )
        : card.semantics(
            name: customerName,
            serial: serial,
            status: statusLabel,
            amount: item.totalOutstanding.toRupeeFormat(),
          );

    // `container` (not `MergeSemantics`): the row gets its own labelled node while the
    // Collect / Deposit buttons and the overflow menu stay individually reachable.
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: RDMonthlyOperationCard(
        item: item,
        evaluationDate: now,
        position: position,
        titleByAccount: titleByAccount,
        isSelected: isSelected,
        isSelectionMode: isSelectionMode,
        isBusy: isBusy,
        selectSemanticLabel: card.selectRow(name: customerName),
        onSelect: (_) => selection.toggle(id),
        onTap: () => RecurringDepositDetailRoute(
          item.deposit.id,
          tab: 'schedule',
        ).push(context),
        onLongPress: () {
          if (isSelectionMode) return;
          // The platform's feedback for a long press: it has started something.
          Feedback.forLongPress(context);
          selection.toggle(id);
        },
        onCollect: onCollect,
        onDeposit: onDeposit,
        onDepositFromPocket: isBusy ? null : onDepositFromPocket,
        onUndoLatestDeposit: isBusy ? null : onUndoLatestDeposit,
        onAbsorbFee: isBusy ? null : onAbsorbFee,
      ),
    );
  }
}
