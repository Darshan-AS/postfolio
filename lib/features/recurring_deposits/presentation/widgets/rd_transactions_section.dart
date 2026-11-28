import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/expressive/app_menu.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Sub-tabs inside [RDTransactionsSection]: customer receipts or Post Office visits.
enum RDTransactionsTab { payments, poDeposits }

/// Payment history tab: segmented between customer receipts grouped by year (with
/// projected allocation chips) and Post Office deposit visits grouped by year.
class RDTransactionsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final bool isEmbeddedTab;

  const RDTransactionsSection({
    super.key,
    required this.deposit,
    this.isEmbeddedTab = false,
  });

  /// Half a turn: the chevron points up while the section is open.
  static const double _openChevronTurns = 0.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final activeSubTab = useState(RDTransactionsTab.payments);
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final projection = ref.watch(rdLedgerProjectionProvider(deposit.id)).value;
    final txCount = ref.watch(
      rdTransactionsStreamProvider(
        deposit.id,
      ).select((async) => async.value?.length ?? 0),
    );
    final visitCount = ref.watch(
      rdLedgerFactsProvider(
        deposit.id,
      ).select((async) => async.value?.poDeposits.length ?? 0),
    );
    final ledger = t.recurringDeposits.ledger;
    final passbook = ledger.passbook;

    Future<void> handleCollect() async {
      final outcome = await showRDLogPaymentSheet(
        context,
        rdId: deposit.id,
        initialAmount: projection?.collectPrefillAmount,
        showDepositFromPocketShortcut:
            (projection?.canDepositFromPocket ?? false) && !isBusy,
      );
      if (outcome == RDLogPaymentOutcome.depositFromPocket && context.mounted) {
        await showRDDepositSheet(
          context,
          rdId: deposit.id,
          initialCount: (projection?.poReadiness.readyCount ?? 0) + 1,
        );
      }
    }

    Widget history() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButtonGroup<RDTransactionsTab>(
          segments: [
            AppSegment(
              value: RDTransactionsTab.payments,
              label: passbook.paymentsSegment(count: txCount.toString()),
            ),
            AppSegment(
              value: RDTransactionsTab.poDeposits,
              label: passbook.poDepositsSegment(count: visitCount.toString()),
            ),
          ],
          selected: activeSubTab.value,
          onChanged: (next) => activeSubTab.value = next,
        ),
        AppSpacings.gapSm,
        switch (activeSubTab.value) {
          RDTransactionsTab.payments => _RDTransactionsContent(
            rdId: deposit.id,
            isBusy: isBusy,
            onCollect: handleCollect,
          ),
          RDTransactionsTab.poDeposits => _RDPoVisitsList(
            rdId: deposit.id,
            isBusy: isBusy,
          ),
        },
      ],
    );

    if (isEmbeddedTab) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Lines the title up with the text inside the tiles below it.
            padding: const EdgeInsetsDirectional.only(
              start: AppDimensions.paddingLg,
            ),
            // Title and action share a line when they fit; the button drops below otherwise.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingSm,
              children: [
                Text(ledger.transactionsTitle, style: emphasized.titleLarge),
                AppButton(
                  label: passbook.collect,
                  onPressed: isBusy ? null : handleCollect,
                ),
              ],
            ),
          ),
          AppSpacings.gapSm,
          history(),
        ],
      );
    }

    // Stand-alone: a header row that unfolds the history. The history sits on the page
    // below the header rather than inside it, so its tiles are not nested in a card.
    final isOpen = isExpanded.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGroupTile(
          onTap: () => isExpanded.value = !isOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedInvoice01,
                  size: AppDimensions.iconMd,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: Text(
                    ledger.transactionsTitle,
                    style: emphasized.titleMedium,
                  ),
                ),
                AppSpacings.gapSm,
                AnimatedRotation(
                  turns: isOpen ? _openChevronTurns : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.spatialFastDuration,
                  curve: AppMotion.spatialFastCurve,
                  child: AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: AppDimensions.iconMd,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[AppSpacings.gapSm, history()],
      ],
    );
  }
}

class _RDTransactionsContent extends ConsumerWidget {
  final String rdId;
  final bool isBusy;
  final VoidCallback onCollect;

  const _RDTransactionsContent({
    required this.rdId,
    required this.isBusy,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(rdTransactionsStreamProvider(rdId));
    final allocationsByTx = ref.watch(
      rdLedgerProjectionProvider(
        rdId,
      ).select((async) => async.value?.allocationsByTransaction ?? const {}),
    );

    return switch (transactionsAsync) {
      AsyncData(:final value) => _TransactionList(
        rdId: rdId,
        transactions: value,
        allocationsByTx: allocationsByTx,
        isBusy: isBusy,
        onCollect: onCollect,
      ),
      AsyncLoading(:final value?) => _TransactionList(
        rdId: rdId,
        transactions: value,
        allocationsByTx: allocationsByTx,
        isBusy: isBusy,
        onCollect: onCollect,
      ),
      AsyncError(:final error) => ErrorStateView(
        message: error.toString(),
        onRetry: () => ref.invalidate(rdTransactionsStreamProvider(rdId)),
      ),
      AsyncLoading() => const _TransactionsSkeleton(),
    };
  }
}

class _TransactionList extends StatelessWidget {
  final String rdId;
  final List<RDTransaction> transactions;
  final Map<String, List<RDAllocationSlice>> allocationsByTx;
  final bool isBusy;
  final VoidCallback onCollect;

  const _TransactionList({
    required this.rdId,
    required this.transactions,
    required this.allocationsByTx,
    required this.isBusy,
    required this.onCollect,
  });

  /// Twice the avatar of a list row: the badge is the only thing in the empty list.
  static const double _emptyBadgeSize = AppDimensions.avatarMd * 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ledger = t.recurringDeposits.ledger;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          children: [
            AppShapeAvatar(
              size: _emptyBadgeSize,
              shape: AppAvatarShape.cookie12,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              child: const AppIcon(
                HugeIcons.strokeRoundedInvoice01,
                size: AppDimensions.iconXl - AppDimensions.paddingSm,
              ),
            ),
            AppSpacings.gapLg,
            Text(
              ledger.noPayments,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacings.gapLg,
            AppButton(
              label: ledger.passbook.collect,
              onPressed: isBusy ? null : onCollect,
            ),
          ],
        ),
      );
    }

    // Newest first, a run of grouped tiles per year. A header per month is, for a payment
    // made every month, a header per receipt, above a receipt that already says its date.
    final groups = <({int year, List<RDTransaction> items})>[];
    for (final month in RDLedgerProjection.groupTransactionsByMonth(
      transactions,
    )) {
      if (groups.isEmpty || groups.last.year != month.month.year) {
        groups.add((year: month.month.year, items: <RDTransaction>[]));
      }
      groups.last.items.addAll(month.items);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (g, group) in groups.indexed) ...[
          if (g > 0) AppSpacings.gapSm,
          DetailSectionTitle(group.year.toString()),
          for (final (i, tx) in group.items.indexed) ...[
            if (i > 0) const SizedBox(height: AppShapes.groupGap),
            RDTransactionTile(
              rdId: rdId,
              transaction: tx,
              allocations: allocationsByTx[tx.id] ?? const [],
              isBusy: isBusy,
              position: AppGroupPosition.at(i, group.items.length),
            ),
          ],
        ],
      ],
    );
  }
}

/// One receipt: the amount collected, when and how it was paid, and the months it was
/// applied to. Swiping it away or its overflow menu deletes the payment after confirmation.
///
/// The receipt is a grouped tile: pass its [position] among the receipts of its month.
class RDTransactionTile extends ConsumerWidget {
  final String rdId;
  final RDTransaction transaction;
  final List<RDAllocationSlice> allocations;
  final bool isBusy;

  /// Where this receipt sits among the rows of its group.
  final AppGroupPosition position;

  const RDTransactionTile({
    super.key,
    required this.rdId,
    required this.transaction,
    required this.isBusy,
    this.allocations = const [],
    this.position = AppGroupPosition.single,
  });

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final ledger = t.recurringDeposits.ledger;
    final tx = transaction;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: ledger.actions.deletePaymentTitle,
      content: ledger.actions.deletePaymentContent(
        amount: tx.amount.toRupeeFormat(),
        date: tx.paidDate.toAppFormat(),
      ),
      confirmText: t.common.delete,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .deletePayment(rdId: rdId, transactionId: tx.id);
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: ledger.paymentDeleted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ledger = t.recurringDeposits.ledger;
    final tx = transaction;

    final tile = AppGroupTile(
      position: position,
      child: Padding(
        // The overflow button ends the row, so the tile adds no trailing inset of its own.
        padding: const EdgeInsetsDirectional.only(
          start: AppDimensions.paddingLg,
          top: AppDimensions.paddingMd,
          bottom: AppDimensions.paddingMd,
        ),
        child: Row(
          children: [
            AppShapeAvatar(
              size: AppDimensions.avatarMd,
              // The mode is the icon. It also had a shape of its own, two of them the
              // shapes of deposit schemes.
              shape: AppAvatarShape.neutral,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              child: AppIcon(tx.paymentMode.icon, size: AppDimensions.iconMd),
            ),
            AppSpacings.gapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The amount shrinks rather than wraps when width is tight.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      tx.amount.toRupeeFormat(),
                      maxLines: 1,
                      style: AppTypography.emphasizedOf(context).titleMedium,
                    ),
                  ),
                  AppSpacings.gapXxs,
                  Text(
                    ledger.installmentDetails.paidOnVia(
                      date: tx.paidDate.toAppFormat(),
                      mode: tx.paymentMode.displayName,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (allocations.isNotEmpty) ...[
                    AppSpacings.gapSm,
                    Wrap(
                      spacing: AppDimensions.paddingXs,
                      runSpacing: AppDimensions.paddingXs,
                      children: [
                        for (final slice in allocations)
                          if (slice.isCredit)
                            _AllocationChip(
                              label: ledger.allocations.creditPill(
                                amount: slice.amount.toRupeeFormat(),
                              ),
                              backgroundColor: scheme.inset,
                              foregroundColor: scheme.onSurfaceVariant,
                            )
                          else if (slice.isOpeningReceivable)
                            _AllocationChip(
                              label: ledger.allocations.openingDuesPill(
                                amount: slice.amount.toRupeeFormat(),
                              ),
                              backgroundColor: scheme.secondaryContainer,
                              foregroundColor: scheme.onSecondaryContainer,
                            )
                          else
                            // Neutral: it is a label. In the primary tone it looked like
                            // something to tap.
                            _AllocationChip(
                              label: ledger.allocations.installmentPill(
                                month: slice.installmentNo.toString(),
                                amount: slice.amount.toRupeeFormat(),
                              ),
                              backgroundColor: scheme.inset,
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppMenu(
              entries: [
                AppMenuEntry(
                  label: ledger.actions.editPayment,
                  icon: const AppIcon(
                    HugeIcons.strokeRoundedEdit02,
                    size: AppDimensions.iconSm,
                  ),
                  onPressed: () => showRDEditPaymentSheet(
                    context,
                    rdId: rdId,
                    transaction: tx,
                  ),
                ),
                AppMenuEntry(
                  label: ledger.actions.deletePayment,
                  icon: const AppIcon(
                    HugeIcons.strokeRoundedDelete02,
                    size: AppDimensions.iconSm,
                  ),
                  isDestructive: true,
                  onPressed: () => _confirmAndDelete(context, ref),
                ),
              ],
              anchorBuilder: (context, open) => IconButton(
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(
                    AppDimensions.minTapTarget,
                    AppDimensions.minTapTarget,
                  ),
                  maximumSize: const Size(
                    AppDimensions.minTapTarget,
                    AppDimensions.minTapTarget,
                  ),
                  padding: EdgeInsets.zero,
                ),
                icon: const AppIcon(
                  HugeIcons.strokeRoundedMoreVertical,
                  size: AppDimensions.iconMd,
                ),
                tooltip: t.common.moreOptions,
                onPressed: isBusy ? null : open,
              ),
            ),
          ],
        ),
      ),
    );

    // Clipped to the tile's slot, so a swiped receipt slides out of its own row and never
    // across the page margin.
    return ClipRRect(
      borderRadius: AppShapes.groupRadius(position),
      child: Dismissible(
        key: ValueKey('rd_tx_${tx.id}'),
        direction: isBusy ? DismissDirection.none : DismissDirection.endToStart,
        background: ColoredBox(
          color: scheme.errorContainer,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
              ),
              child: AppIcon(
                HugeIcons.strokeRoundedDelete02,
                size: AppDimensions.iconMd,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ),
        // The stream removes the row once the delete lands, so never dismiss optimistically.
        confirmDismiss: (_) async {
          await _confirmAndDelete(context, ref);
          return false;
        },
        child: tile,
      ),
    );
  }
}

/// Where part of a payment went: a month, the opening dues, or credit carried forward.
class _AllocationChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _AllocationChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // The chip carries an amount: in a narrow tile it shrinks rather than wraps.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Material(
        color: backgroundColor,
        shape: AppShapes.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm,
            vertical: AppDimensions.paddingXs,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.emphasizedOf(
              context,
            ).labelSmall?.copyWith(color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

/// Post Office visits for this account in the order the PO applied them. Only the last
/// one can be undone because the PO ledger is sequential.
class _RDPoVisitsList extends ConsumerWidget {
  final String rdId;
  final bool isBusy;

  const _RDPoVisitsList({required this.rdId, required this.isBusy});

  /// Above this text scale a visit and its Undo button no longer fit side by side.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  Future<void> _undoLatest(
    BuildContext context,
    WidgetRef ref,
    RDPoDeposit latest,
  ) async {
    final passbook = t.recurringDeposits.ledger.passbook;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: passbook.undoLastDepositTitle,
      content: passbook.undoLastDepositContent(
        count: latest.installmentCount.toString(),
        date: latest.depositedOn.toAppFormat(),
        amount: latest.amount.toRupeeFormat(),
      ),
      confirmText: passbook.undoLastDeposit,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .undoLatestPoDeposit(rdId);
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: passbook.undoLastDepositSuccess,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final financial = AppFinancialColors.of(context);
    final passbook = t.recurringDeposits.ledger.passbook;
    final factsAsync = ref.watch(rdLedgerFactsProvider(rdId));
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(rdId));

    final entries = switch ((factsAsync, projectionAsync)) {
      (AsyncData(value: final facts), AsyncData(value: final projection)) =>
        projection.poVisitEntries(facts.poDeposits),
      (AsyncLoading(value: final facts?), AsyncData(value: final projection)) ||
      (AsyncData(value: final facts), AsyncLoading(value: final projection?)) ||
      (
        AsyncLoading(value: final facts?),
        AsyncLoading(value: final projection?),
      ) => projection.poVisitEntries(facts.poDeposits),
      // Facts errors already surface in the passbook/transactions list; stay quiet here.
      _ => const <RDPoVisitEntry>[],
    };

    // Only the latest visit can be undone. At large text sizes its button moves under the
    // text, which then keeps the full width of the row.
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    Widget undo(RDPoDeposit visit) => AppButton.text(
      label: t.recurringDeposits.ledger.actions.undo,
      onPressed: isBusy ? null : () => _undoLatest(context, ref, visit),
    );

    if (entries.isEmpty) {
      return AppGroupTile(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Text(
            passbook.noPoVisits,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final groups = <({int year, List<RDPoVisitEntry> items})>[];
    for (final entry in entries) {
      final year = entry.deposit.depositedOn.year;
      if (groups.isEmpty || groups.last.year != year) {
        groups.add((year: year, items: <RDPoVisitEntry>[]));
      }
      groups.last.items.add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (g, group) in groups.indexed) ...[
          if (g > 0) AppSpacings.gapSm,
          DetailSectionTitle(group.year.toString()),
          for (final (i, entry) in group.items.indexed) ...[
            if (i > 0) const SizedBox(height: AppShapes.groupGap),
            Builder(
              builder: (context) {
                final visit = entry.deposit;
                final hasFromPocket = entry.unpaidFromPocketCount > 0;
                final monthsLabel =
                    entry.startInstallmentNo == entry.endInstallmentNo
                    ? passbook.poDepositInstSingle(
                        month: entry.startInstallmentNo.toString(),
                      )
                    : passbook.poDepositInstRange(
                        start: entry.startInstallmentNo.toString(),
                        end: entry.endInstallmentNo.toString(),
                      );
                final meta = visit.feePaid > 0
                    ? passbook.poDepositMetaWithFee(
                        date: visit.depositedOn.toAppFormat(),
                        months: monthsLabel,
                        fee: visit.feePaid.toRupeeFormat(),
                      )
                    : passbook.poDepositMeta(
                        date: visit.depositedOn.toAppFormat(),
                        months: monthsLabel,
                      );
                final badgeColors = hasFromPocket
                    ? financial.receivable
                    : financial.settled;

                return AppGroupTile(
                  position: AppGroupPosition.at(i, group.items.length),
                  child: Padding(
                    // The undo button brings its own trailing inset.
                    padding: EdgeInsetsDirectional.only(
                      start: AppDimensions.paddingLg,
                      end: entry.isLatest && !stacked
                          ? AppDimensions.paddingSm
                          : AppDimensions.paddingLg,
                      top: AppDimensions.paddingMd,
                      bottom: AppDimensions.paddingMd,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppShapeAvatar(
                          size: AppDimensions.avatarMd,
                          shape: AppAvatarShape.neutral,
                          backgroundColor: badgeColors.container,
                          foregroundColor: badgeColors.onContainer,
                          child: const AppIcon(
                            HugeIcons.strokeRoundedBuilding03,
                            size: AppDimensions.iconMd,
                          ),
                        ),
                        AppSpacings.gapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                passbook.poDepositTitle(
                                  amount: visit.amount.toRupeeFormat(),
                                ),
                                style: emphasized.titleMedium,
                              ),
                              AppSpacings.gapXxs,
                              Text(
                                meta,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              if (hasFromPocket) ...[
                                AppSpacings.gapSm,
                                Wrap(
                                  spacing: AppDimensions.paddingXs,
                                  runSpacing: AppDimensions.paddingXs,
                                  children: [
                                    _AllocationChip(
                                      label: entry.unpaidFromPocketCount == 1
                                          ? passbook.poDepositFromPocketSingle
                                          : passbook.poDepositFromPocketCount(
                                              count: entry.unpaidFromPocketCount
                                                  .toString(),
                                            ),
                                      backgroundColor:
                                          financial.receivable.container,
                                      foregroundColor:
                                          financial.receivable.onContainer,
                                    ),
                                  ],
                                ),
                              ],
                              if (entry.isLatest && stacked) ...[
                                AppSpacings.gapXs,
                                undo(visit),
                              ],
                            ],
                          ),
                        ),
                        if (entry.isLatest && !stacked) ...[
                          AppSpacings.gapSm,
                          undo(visit),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    return Skeletonizer(
      enabled: true,
      child: AppGroup(
        children: [
          for (var i = 0; i < _rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingMd,
              ),
              child: Row(
                children: [
                  const AppShapeAvatar(
                    size: AppDimensions.avatarMd,
                    child: SizedBox.shrink(),
                  ),
                  AppSpacings.gapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ledger.paymentAmount,
                          style: theme.textTheme.titleMedium,
                        ),
                        AppSpacings.gapXxs,
                        Text(ledger.paymentDate),
                      ],
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
