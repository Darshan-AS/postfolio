import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Payment history tab: transactions grouped by month with projected allocation chips.
class RDTransactionsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final bool isEmbeddedTab;

  const RDTransactionsSection({
    super.key,
    required this.deposit,
    this.isEmbeddedTab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final ledger = t.recurringDeposits.ledger;

    final shape = RoundedRectangleBorder(
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );

    if (isEmbeddedTab) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: shape,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd,
                vertical: AppDimensions.paddingSm,
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedInvoice01,
                    size: AppDimensions.iconMd,
                  ),
                  AppSpacings.gapSm,
                  Expanded(
                    child: Text(
                      ledger.transactionsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppDimensions.minTapTarget),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => showRDLogPaymentSheet(context, rdId: deposit.id),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCoins01,
                      size: AppDimensions.iconXs,
                    ),
                    label: Text(ledger.passbook.collect),
                  ),
                ],
              ),
            ),
            const Divider(height: AppDimensions.dividerHeight),
            _RDTransactionsContent(rdId: deposit.id, isBusy: isBusy),
            const Divider(height: AppDimensions.dividerHeight),
            _RDPoVisitsList(rdId: deposit.id, isBusy: isBusy),
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: shape,
      child: ExpansionTile(
        title: Text(
          ledger.transactionsTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedInvoice01,
          size: AppDimensions.iconMd,
        ),
        onExpansionChanged: (value) => isExpanded.value = value,
        children: [
          if (isExpanded.value) ...[
            _RDTransactionsContent(rdId: deposit.id, isBusy: isBusy),
            const Divider(height: AppDimensions.dividerHeight),
            _RDPoVisitsList(rdId: deposit.id, isBusy: isBusy),
          ],
        ],
      ),
    );
  }
}

class _RDTransactionsContent extends ConsumerWidget {
  final String rdId;
  final bool isBusy;

  const _RDTransactionsContent({required this.rdId, required this.isBusy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(rdTransactionsStreamProvider(rdId));
    final allocationsByTx = ref.watch(
      rdLedgerProjectionProvider(rdId).select(
        (async) => async.value?.allocationsByTransaction ?? const {},
      ),
    );

    return switch (transactionsAsync) {
      AsyncData(:final value) => _TransactionList(
          rdId: rdId,
          transactions: value,
          allocationsByTx: allocationsByTx,
          isBusy: isBusy,
        ),
      AsyncLoading(:final value?) => _TransactionList(
          rdId: rdId,
          transactions: value,
          allocationsByTx: allocationsByTx,
          isBusy: isBusy,
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

  const _TransactionList({
    required this.rdId,
    required this.transactions,
    required this.allocationsByTx,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedInvoice01,
              size: AppDimensions.iconXl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacings.gapMd,
            Text(
              ledger.noPayments,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacings.gapLg,
            FilledButton.icon(
              onPressed: isBusy ? null : () => showRDLogPaymentSheet(context, rdId: rdId),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(ledger.passbook.collect),
            ),
          ],
        ),
      );
    }

    final groups = RDLedgerProjection.groupTransactionsByMonth(transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          _MonthHeader(label: group.month.toMonthYearFormat()),
          for (final tx in group.items)
            RDTransactionTile(
              rdId: rdId,
              transaction: tx,
              allocations: allocationsByTx[tx.id] ?? const [],
              isBusy: isBusy,
            ),
        ],
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;

  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingXs,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class RDTransactionTile extends ConsumerWidget {
  final String rdId;
  final RDTransaction transaction;
  final List<RDAllocationSlice> allocations;
  final bool isBusy;

  const RDTransactionTile({
    super.key,
    required this.rdId,
    required this.transaction,
    required this.isBusy,
    this.allocations = const [],
  });

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final ledger = t.recurringDeposits.ledger;
    final scheme = Theme.of(context).colorScheme;
    final tx = transaction;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: ledger.actions.deletePaymentTitle,
      content: ledger.actions.deletePaymentContent(
        amount: tx.amount.toRupeeFormat(),
        date: tx.paidDate.toAppFormat(),
      ),
      confirmText: t.common.delete,
      confirmBackgroundColor: scheme.errorContainer,
      confirmForegroundColor: scheme.onErrorContainer,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .deletePayment(rdId: rdId, transactionId: tx.id);
    if (!context.mounted) return;
    AppFeedback.showResult(context, result, successMessage: ledger.paymentDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ledger = t.recurringDeposits.ledger;
    final tx = transaction;

    final modeIcon = switch (tx.paymentMode) {
      RDPaymentMode.cash => HugeIcons.strokeRoundedCoins01,
      RDPaymentMode.upi => HugeIcons.strokeRoundedCreditCard,
      RDPaymentMode.cheque => HugeIcons.strokeRoundedTicket01,
      RDPaymentMode.bankTransfer => HugeIcons.strokeRoundedBank,
    };

    final tile = ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSm),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: modeIcon,
          size: AppDimensions.iconSm,
          color: scheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        tx.amount.toRupeeFormat(),
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ledger.installmentDetails.paidOnVia(
              date: tx.paidDate.toAppFormat(),
              mode: tx.paymentMode.displayName,
            ),
          ),
          AppSpacings.gapXs,
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
                    backgroundColor: scheme.surfaceContainerHighest,
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
                  _AllocationChip(
                    label: ledger.allocations.installmentPill(
                      month: slice.installmentNo.toString(),
                      amount: slice.amount.toRupeeFormat(),
                    ),
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
            ],
          ),
        ],
      ),
      trailing: MenuAnchor(
        builder: (context, controller, child) => IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMoreVertical,
            size: AppDimensions.iconMd,
          ),
          tooltip: t.common.moreOptions,
          onPressed: isBusy
              ? null
              : () => controller.isOpen ? controller.close() : controller.open(),
        ),
        menuChildren: [
          MenuItemButton(
            leadingIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: AppDimensions.iconSm,
            ),
            child: Text(ledger.actions.editPayment),
            onPressed: () => showRDEditPaymentSheet(context, rdId: rdId, transaction: tx),
          ),
          MenuItemButton(
            leadingIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: AppDimensions.iconSm,
              color: scheme.error,
            ),
            child: Text(
              ledger.actions.deletePayment,
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.error),
            ),
            onPressed: () => _confirmAndDelete(context, ref),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('rd_tx_${tx.id}'),
      direction: isBusy ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          size: AppDimensions.iconMd,
          color: scheme.onErrorContainer,
        ),
      ),
      // The stream removes the row once the delete lands, so never dismiss optimistically.
      confirmDismiss: (_) async {
        await _confirmAndDelete(context, ref);
        return false;
      },
      child: tile,
    );
  }
}

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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMax),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
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

  Future<void> _undoLatest(
    BuildContext context,
    WidgetRef ref,
    RDPoDeposit latest,
  ) async {
    final passbook = t.recurringDeposits.ledger.passbook;
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: passbook.undoLastDepositTitle,
      content: passbook.undoLastDepositContent(
        count: latest.installmentCount.toString(),
        date: latest.depositedOn.toAppFormat(),
        amount: latest.amount.toRupeeFormat(),
      ),
      confirmText: passbook.undoLastDeposit,
      confirmBackgroundColor: scheme.errorContainer,
      confirmForegroundColor: scheme.onErrorContainer,
    );
    if (confirmed != true || !context.mounted) return;

    final result =
        await ref.read(rDLedgerControllerProvider.notifier).undoLatestPoDeposit(rdId);
    if (!context.mounted) return;
    AppFeedback.showResult(context, result, successMessage: passbook.undoLastDepositSuccess);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passbook = t.recurringDeposits.ledger.passbook;
    final factsAsync = ref.watch(rdLedgerFactsProvider(rdId));

    final visits = switch (factsAsync) {
      AsyncData(:final value) => value.poDepositsInOrder,
      AsyncLoading(:final value?) => value.poDepositsInOrder,
      // Facts errors already surface in the passbook/transactions list; stay quiet here.
      AsyncError() || AsyncLoading() => const <RDPoDeposit>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLg,
            AppDimensions.paddingMd,
            AppDimensions.paddingLg,
            AppDimensions.paddingXs,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              AppSpacings.gapSm,
              Text(
                passbook.poVisitsTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (visits.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingXs,
              AppDimensions.paddingLg,
              AppDimensions.paddingLg,
            ),
            child: Text(
              passbook.noPoVisits,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final (i, visit) in visits.indexed)
            ListTile(
              dense: true,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: AppDimensions.iconSm,
                color: scheme.primary,
              ),
              title: Text(
                passbook.poVisit(
                  date: visit.depositedOn.toAppFormat(),
                  count: visit.installmentCount.toString(),
                  amount: visit.amount.toRupeeFormat(),
                  fee: visit.feePaid.toRupeeFormat(),
                ),
                style: theme.textTheme.bodySmall,
              ),
              trailing: i == visits.length - 1
                  ? TextButton(
                      onPressed: isBusy ? null : () => _undoLatest(context, ref, visit),
                      child: Text(t.recurringDeposits.ledger.actions.undo),
                    )
                  : null,
            ),
      ],
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          for (var i = 0; i < _rows; i++)
            ListTile(
              leading: const CircleAvatar(),
              title: Text(ledger.paymentAmount),
              subtitle: Text(ledger.paymentDate),
            ),
        ],
      ),
    );
  }
}
