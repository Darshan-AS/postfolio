import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

const int _skeletonRowCount = 5;

/// The hub's rows as a sliver, inset by the page margin, in the active sort order.
/// Loading, error, and empty states are rendered in place.
class RDHubList extends ConsumerWidget {
  const RDHubList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentDateProvider);

    const padding = EdgeInsets.fromLTRB(
      AppDimensions.pageMargin,
      0,
      AppDimensions.pageMargin,
      AppDimensions.paddingXl,
    );

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
      AsyncLoading() => const _LoadingSliver(padding: padding),
    };
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
    final isCollectFilter = filters.status == RDMonthlyFilter.toCollect;
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

/// One row: routes every action through `RDMonthlyOperationsActions` / sheets,
/// surfacing each `Result` via [AppFeedback].
class _RDHubRow extends ConsumerWidget {
  final RDMonthlyOperationItem item;
  final DateTime now;
  final AppGroupPosition position;

  const _RDHubRow({
    super.key,
    required this.item,
    required this.now,
    required this.position,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = t.recurringDeposits.monthlyOperations.card;
    final installmentNo = item.installmentNumber.toString();

    final isBusy = ref.watch(
      rDLedgerControllerProvider.select((a) => a.isLoading),
    );
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

    Future<void> onDepositFromPocket() async {
      await showRDDepositSheet(
        context,
        rdId: item.deposit.id,
        initialCount: item.fromPocketInstallmentCount,
      );
    }

    Future<void> onCollect() async {
      final outcome = await showRDLogPaymentSheet(
        context,
        rdId: item.deposit.id,
        initialAmount: item.initialPaymentAmount,
        showDepositFromPocketShortcut: item.canDepositFromPocket && !isBusy,
      );
      if (outcome == RDLogPaymentOutcome.depositFromPocket && context.mounted) {
        await onDepositFromPocket();
      }
    }

    Future<void> onDeposit() async {
      await showRDDepositSheet(
        context,
        rdId: item.deposit.id,
        initialCount: item.readyForPoCount,
      );
    }

    Future<void> onUndoLatestDeposit() async {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: card.undoLatestDepositConfirmTitle,
        content: card.undoLatestDepositConfirmMessage,
        confirmText: t.common.confirm,
        isDestructive: true,
      );
      if (confirmed != true || !context.mounted) return;
      await undoLatest();
    }

    Future<void> onAbsorbFee() async {
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
    final semanticLabel =
        (item.isSettled || status == RDInstallmentDisplayStatus.baseline)
        ? card.semanticsSettled(
            name: customerName,
            serial: serial,
            status: statusLabel,
          )
        : !item.isCustomerPending && item.hasReadyForPo
        ? card.semantics(
            name: customerName,
            serial: serial,
            status: statusLabel,
            amount: item.readyForPoAmount.toRupeeFormat(),
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

    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: RDMonthlyOperationCard(
        item: item,
        evaluationDate: now,
        position: position,
        heroTag: EntityHero.tagFrom(EntityHero.rdHub, item.deposit.id),
        isBusy: isBusy,
        onTap: () => RecurringDepositDetailRoute(
          item.deposit.id,
          tab: RDDetailTab.ledger.queryValue,
          $extra: EntityHero.rdHub,
        ).push(context),
        onCollect: onCollect,
        onDeposit: onDeposit,
        onDepositFromPocket: isBusy ? null : onDepositFromPocket,
        onUndoLatestDeposit: isBusy ? null : onUndoLatestDeposit,
        onAbsorbFee: isBusy ? null : onAbsorbFee,
      ),
    );
  }
}
