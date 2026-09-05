import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/domain/nominees_detail_section.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/core/widgets/domain/wealth_accumulation_grid.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';

class RecurringDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const RecurringDepositDetailScreen({super.key, required this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositsControllerProvider),
      entityId: depositId,
      idSelector: (d) => d.id,
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
      dummyEntity: RecurringDeposit.dummy,
      builder: (deposit) {
        return EntityDetailScaffold(
          appBarTitle: t.common.depositDetails,
          customActions: [
            if (deposit?.status != null)
              IconButton(
                icon: HugeIcon(
                  icon: deposit!.status == DepositStatus.active
                      ? HugeIcons.strokeRoundedCheckmarkBadge01
                      : HugeIcons.strokeRoundedArrowTurnBackward,
                  size: AppDimensions.iconMd,
                ),
                tooltip: deposit.status == DepositStatus.active
                    ? t.common.close
                    : t.common.reopen,
                onPressed: () async {
                  final isActive = deposit.status == DepositStatus.active;
                  final confirmed = await AppDialogs.confirmAction(
                    context,
                    title: isActive ? t.common.close : t.common.reopen,
                    content: isActive
                        ? t.recurringDeposits.closeDepositConfirmation
                        : t.recurringDeposits.reopenDepositConfirmation,
                    confirmText: isActive ? t.common.close : t.common.reopen,
                  );
                  if (confirmed == true && context.mounted) {
                    final newStatus = isActive
                        ? DepositStatus.closed
                        : DepositStatus.active;
                    final result = await ref
                        .read(recurringDepositsControllerProvider.notifier)
                        .toggleDepositStatus(depositId, newStatus);

                    if (result is Failure && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text((result as Failure).error.toString()),
                        ),
                      );
                    }
                  }
                },
              ),
          ],
          onEdit: () => RecurringDepositEditRoute(depositId).push(context),
          deleteDialogTitle: t.recurringDeposits.deleteDeposit,
          deleteDialogContent: t.recurringDeposits.deleteDepositConfirmation,
          onDelete: () async {
            final result = await ref
                .read(recurringDepositsControllerProvider.notifier)
                .deleteRecurringDeposit(depositId);
            return result is Failure
                ? t.recurringDeposits.failedToDeleteDeposit(
                    error: (result as Failure).error.toString(),
                  )
                : null;
          },
          header: EntityDetailHeader(
            avatarBackgroundColor: Theme.of(
              context,
            ).colorScheme.secondaryContainer,
            avatarForegroundColor: Theme.of(
              context,
            ).colorScheme.onSecondaryContainer,
            avatarChild: const HugeIcon(
              icon: HugeIcons.strokeRoundedTransaction,
              size: AppDimensions.iconLg,
            ),
            title: deposit!.accountNo ?? t.common.notProvided,
            subtitle: Text(
              deposit.schemeType.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            badge: StatusBadge(status: deposit.status.displayName),
          ),
          body: [
            Row(
              children: [
                DetailAmountCard(
                  title: t.recurringDeposits.fields.installmentAmount,
                  amount: deposit.installmentAmount,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                AppSpacings.gapLg,
                DetailStatCard(
                  title: t.recurringDeposits.fields.interestRate,
                  value: '${deposit.interestRate.toStringAsFixed(2)}%',
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            AppSpacings.gapXxl,
            switch (deposit.projection) {
              WealthAccumulation(
                :final totalInvested,
                :final maturityAmount,
                :final totalInterestEarned,
              ) =>
                WealthAccumulationGrid(
                  totalInvested: totalInvested,
                  projectedInterest: totalInterestEarned,
                  maturityAmount: maturityAmount,
                ),
              IncomeGeneration() => const SizedBox.shrink(),
            },
            AppSpacings.gapXxl,
            DetailSection(
              title: t.recurringDeposits.sections.investmentDetails,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.termYears,
                  value:
                      '${deposit.termYears} Years, ${deposit.termMonths} Months',
                ),
                const Divider(height: AppDimensions.dividerHeight),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPercent,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.interestRate,
                  value: '${deposit.interestRate.toStringAsFixed(2)}%',
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.recurringDeposits.sections.timeline,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar02,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.startDate,
                  value: deposit.startDate.toAppFormat(),
                ),
                const Divider(height: AppDimensions.dividerHeight),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.maturityDate,
                  value: deposit.maturityDate.toAppFormat(),
                ),
              ],
            ),
            AppSpacings.gapLg,
            DetailSection(
              title: t.recurringDeposits.sections.accountInformation,
              children: [
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTag01,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.serialNo,
                  value: deposit.serialNo ?? t.common.notProvided,
                ),
                const Divider(height: AppDimensions.dividerHeight),
                DetailItem(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: AppDimensions.iconMd,
                  ),
                  label: t.recurringDeposits.fields.customerId,
                  value:
                      ref
                          .watch(customerByIdProvider(deposit.customerId))
                          .value
                          ?.name ??
                      deposit.customerId,
                  onTap: () =>
                      CustomerDetailRoute(deposit.customerId).push(context),
                ),
              ],
            ),
            AppSpacings.gapLg,
            if (deposit.nominees.isNotEmpty)
              NomineesDetailSection(nominees: deposit.nominees),
            AppSpacings.gapLg,
            _CollapsibleInstallmentsSection(deposit: deposit),
            AppSpacings.gapLg,
            _CollapsibleTransactionsSection(deposit: deposit),
          ],
        );
      },
    );
  }
}

class _CollapsibleInstallmentsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const _CollapsibleInstallmentsSection({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ExpansionTile(
        title: Text(
          'Installments Ledger',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        onExpansionChanged: (val) {
          isExpanded.value = val;
        },
        children: [
          if (isExpanded.value)
            _InstallmentsList(deposit: deposit)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _InstallmentsList extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const _InstallmentsList({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync = ref.watch(rdInstallmentsStreamProvider(deposit.id));
    final isSelectionMode = useState(false);
    final selectedIds = useState<Set<String>>({});
    final theme = Theme.of(context);

    return installmentsAsync.when(
      data: (installments) {
        if (installments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingLg),
            child: Text('No installments found.'),
          );
        }

        final selectedInstallments = installments
            .where((inst) => selectedIds.value.contains(inst.id))
            .toList();
        final unpaidSelected = selectedInstallments
            .where((inst) => inst.poStatus == RDPoStatus.unpaid)
            .toList();
        final paidSelected = selectedInstallments
            .where((inst) => inst.poStatus == RDPoStatus.paid)
            .toList();

        // Calculate summary KPI metrics
        final pendingPoAmount = installments
            .where((inst) =>
                inst.customerStatus == RDInstallmentStatus.fullyPaid &&
                inst.poStatus == RDPoStatus.unpaid)
            .fold<double>(0, (sum, inst) => sum + inst.installmentAmount);

        final advancedPoAmount = installments
            .where((inst) =>
                inst.poStatus == RDPoStatus.paid &&
                inst.customerStatus != RDInstallmentStatus.fullyPaid)
            .fold<double>(
              0,
              (sum, inst) => sum + inst.outstandingAmount,
            );

        return Column(
          children: [
            // Summary KPI Chips
            if (pendingPoAmount > 0 || advancedPoAmount > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMd,
                  vertical: AppDimensions.paddingSm,
                ),
                child: Row(
                  children: [
                    if (pendingPoAmount > 0)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending at PO',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pendingPoAmount.toRupeeFormat(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (pendingPoAmount > 0 && advancedPoAmount > 0)
                      const SizedBox(width: AppDimensions.paddingSm),
                    if (advancedPoAmount > 0)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advanced (Receivable)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                advancedPoAmount.toRupeeFormat(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.purple.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd,
                vertical: AppDimensions.paddingSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isSelectionMode.value
                        ? Text(
                            '${selectedIds.value.length} selected for PO',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (!isSelectionMode.value) ...[
                    FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _LogPaymentBottomSheet(
                            deposit: deposit,
                            currentSchedule: installments,
                          ),
                        );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCoins01,
                        size: AppDimensions.iconSm,
                        color: Colors.white,
                      ),
                      label: const Text('Log Payment'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMd,
                          vertical: AppDimensions.paddingSm,
                        ),
                      ),
                    ),
                    if (installments.isNotEmpty) ...[
                      AppSpacings.gapSm,
                      OutlinedButton.icon(
                        onPressed: () {
                          isSelectionMode.value = true;
                          selectedIds.value = {};
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          size: AppDimensions.iconSm,
                        ),
                        label: const Text('Manage PO'),
                      ),
                    ],
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        isSelectionMode.value = false;
                        selectedIds.value = {};
                      },
                      child: const Text('Cancel'),
                    ),
                    if (unpaidSelected.isNotEmpty) ...[
                      AppSpacings.gapSm,
                      FilledButton(
                        onPressed: () async {
                          final toUpdate = unpaidSelected
                              .map((inst) => inst.copyWith(
                                    poStatus: RDPoStatus.paid,
                                    poPaidDate: DateTime.now(),
                                  ))
                              .toList();

                          final result = await ref
                              .read(rDLedgerControllerProvider.notifier)
                              .recordPoPayments(installments: toUpdate);

                          if (result is Success) {
                            isSelectionMode.value = false;
                            selectedIds.value = {};
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '${toUpdate.length} installment(s) marked as deposited to PO!',
                                  ),
                                ),
                              );
                            }
                          } else if (result is Failure<void, String> && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(result.error),
                              ),
                            );
                          }
                        },
                        child: Text('Deposit (${unpaidSelected.length})'),
                      ),
                    ],
                    if (paidSelected.isNotEmpty) ...[
                      AppSpacings.gapSm,
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: () async {
                          final confirmed = await AppDialogs.confirmAction(
                            context,
                            title: 'Revert PO Deposit',
                            content:
                                'Are you sure you want to revert ${paidSelected.length} installment(s) to unpaid at Post Office?',
                            confirmText: 'Revert',
                          );
                          if (confirmed != true) return;

                          final result = await ref
                              .read(rDLedgerControllerProvider.notifier)
                              .revertPoPayments(installments: paidSelected);

                          if (result is Success) {
                            isSelectionMode.value = false;
                            selectedIds.value = {};
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '${paidSelected.length} installment(s) reverted to unpaid at PO!',
                                  ),
                                ),
                              );
                            }
                          } else if (result is Failure<void, String> && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(result.error),
                              ),
                            );
                          }
                        },
                        child: Text('Revert (${paidSelected.length})'),
                      ),
                    ],
                    if (selectedIds.value.isEmpty) ...[
                      AppSpacings.gapSm,
                      const FilledButton(
                        onPressed: null,
                        child: Text('Select'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inst = installments[index];
                final monthNum = index + 1;
                final isOverdue = inst.isOverdueAt(DateTime.now());
                final isPoPaid = inst.poStatus == RDPoStatus.paid;

                // Determine badge and state mapping across the 3x2 matrix
                Color statusColor;
                List<List<dynamic>> statusIcon;
                String statusText;

                if (inst.customerStatus == RDInstallmentStatus.fullyPaid && isPoPaid) {
                  // State 6: Fully Settled
                  statusColor = Colors.green;
                  statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
                  statusText = 'Settled';
                } else if (inst.customerStatus == RDInstallmentStatus.fullyPaid && !isPoPaid) {
                  // State 3: Collected, Pending PO
                  statusColor = Colors.blue;
                  statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
                  statusText = 'Collected (Pending PO)';
                } else if (isPoPaid) {
                  // State 4 & 5: Advanced by Agent to PO
                  statusColor = Colors.purple;
                  statusIcon = HugeIcons.strokeRoundedAlert01;
                  statusText = inst.customerStatus == RDInstallmentStatus.partiallyPaid
                      ? 'Advance Partially Repaid'
                      : 'Advanced to PO';
                } else if (inst.customerStatus == RDInstallmentStatus.partiallyPaid) {
                  // State 2: Partially Paid, PO Unpaid
                  statusColor = Colors.orange;
                  statusIcon = HugeIcons.strokeRoundedAlert01;
                  statusText = 'Partially Paid';
                } else {
                  // State 1: Unpaid, PO Unpaid
                  statusColor = isOverdue ? Colors.red : Colors.grey;
                  statusIcon = isOverdue
                      ? HugeIcons.strokeRoundedAlert01
                      : HugeIcons.strokeRoundedTimer02;
                  statusText = isOverdue ? 'Overdue' : 'Unpaid';
                }

                final titleRow = Row(
                  children: [
                    Text(
                      'Month $monthNum',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(icon: statusIcon, size: 10, color: statusColor),
                          const SizedBox(width: 2),
                          Text(
                            statusText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inst.lateFee > 0) ...[
                      const SizedBox(width: AppDimensions.paddingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Late Fee: ${inst.lateFee.toRupeeFormat()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );

                // Principal-first allocation model:
                // 1. Paid breakdown: Principal fills first, any excess covers late fee.
                final principalPaid = inst.customerPaidAmount.clamp(0.0, inst.installmentAmount);
                final lateFeePaid = (inst.customerPaidAmount - inst.installmentAmount).clamp(0.0, inst.lateFee);

                // 2. Owed breakdown: Remaining principal balance + remaining unpaid late fee.
                final principalOwed = (inst.installmentAmount - principalPaid).clamp(0.0, inst.installmentAmount);
                final lateFeeOwed = (inst.lateFee - lateFeePaid).clamp(0.0, inst.lateFee);
                final totalOwed = inst.outstandingAmount;

                // Build granular breakdown string for Paid
                final String paidBreakdown;
                if (lateFeePaid > 0) {
                  paidBreakdown =
                      'Paid by Customer: ${inst.customerPaidAmount.toRupeeFormat()} (Principal: ${principalPaid.toRupeeFormat()} + Default Fee: ${lateFeePaid.toRupeeFormat()})';
                } else {
                  paidBreakdown = 'Paid by Customer: ${inst.customerPaidAmount.toRupeeFormat()}';
                }

                // Build granular breakdown string for Owed
                final String owedBreakdown;
                if (principalOwed > 0 && lateFeeOwed > 0) {
                  owedBreakdown =
                      'Customer owes: ${totalOwed.toRupeeFormat()} (Balance: ${principalOwed.toRupeeFormat()} + Default Fee: ${lateFeeOwed.toRupeeFormat()})';
                } else if (principalOwed == 0 && lateFeeOwed > 0) {
                  owedBreakdown =
                      'Customer owes: ${totalOwed.toRupeeFormat()} (Default Fee: ${lateFeeOwed.toRupeeFormat()})';
                } else {
                  owedBreakdown = 'Customer owes: ${totalOwed.toRupeeFormat()}';
                }

                final isOpeningBaseline = index < deposit.initialPaidInstallments;

                final subtitleColumn = Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due: ${inst.dueDate.toAppFormat()} | Installment: ${inst.installmentAmount.toRupeeFormat()}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (isOpeningBaseline) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Opening Baseline (Settled prior to onboarding)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        if (inst.customerPaidAmount > 0)
                          Text(
                            paidBreakdown,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (isPoPaid && inst.customerStatus != RDInstallmentStatus.fullyPaid)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              owedBreakdown,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isPoPaid)
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Deposited to PO on ${inst.poPaidDate?.toAppFormat()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else if (inst.customerStatus == RDInstallmentStatus.fullyPaid)
                          Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedAlert01,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Paid but pending PO deposit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                );

                if (isSelectionMode.value) {
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    value: selectedIds.value.contains(inst.id),
                    onChanged: (checked) {
                      final current = Set<String>.from(selectedIds.value);
                      if (checked == true) {
                        current.add(inst.id);
                      } else {
                        current.remove(inst.id);
                      }
                      selectedIds.value = current;
                    },
                    title: titleRow,
                    subtitle: subtitleColumn,
                  );
                }

                return ListTile(
                  title: titleRow,
                  subtitle: subtitleColumn,
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _LogPaymentBottomSheet extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final List<RDInstallment> currentSchedule;

  const _LogPaymentBottomSheet({
    required this.deposit,
    required this.currentSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController();
    final paidDate = useState(DateTime.now());
    final paymentMode = useState(RDPaymentMode.cash);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final theme = Theme.of(context);

    final amountText = useListenable(amountController);
    final double amountValue = double.tryParse(amountText.text.trim()) ?? 0.0;

    final previewResult = useMemoized(() {
      if (amountValue <= 0.0) return null;
      return RDLedgerService.allocateCustomerPayment(
        currentSchedule: currentSchedule,
        paymentAmount: amountValue,
        paidDate: paidDate.value,
        paymentMode: paymentMode.value,
        rdId: deposit.id,
      );
    }, [amountValue, paidDate.value, paymentMode.value, currentSchedule]);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Customer Payment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AppSpacings.gapLg,
                AppTextField(
                  controller: amountController,
                  labelText: 'Payment Amount',
                  isRequired: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixText: t.format.currencySymbol,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                AppSpacings.gapLg,
                Text(
                  'Payment Mode',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<RDPaymentMode>(
                  selected: {paymentMode.value},
                  onSelectionChanged: (selected) {
                    paymentMode.value = selected.first;
                  },
                  segments: RDPaymentMode.values.map((mode) {
                    List<List<dynamic>> icon;
                    switch (mode) {
                      case RDPaymentMode.cash:
                        icon = HugeIcons.strokeRoundedCoins01;
                        break;
                      case RDPaymentMode.upi:
                        icon = HugeIcons.strokeRoundedCreditCard;
                        break;
                      case RDPaymentMode.cheque:
                        icon = HugeIcons.strokeRoundedTicket01;
                        break;
                      case RDPaymentMode.bankTransfer:
                        icon = HugeIcons.strokeRoundedBank;
                        break;
                    }
                    return ButtonSegment<RDPaymentMode>(
                      value: mode,
                      label: Text(mode.displayName),
                      icon: HugeIcon(icon: icon, size: 16),
                    );
                  }).toList(),
                ),
                AppSpacings.gapLg,
                AppTextField(
                  readOnly: true,
                  labelText: 'Payment Date',
                  controller: TextEditingController(
                    text: paidDate.value.toAppFormat(),
                  ),
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: paidDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      paidDate.value = selected;
                    }
                  },
                ),
                AppSpacings.gapXl,
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedActivity01,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Allocation Preview (Pure Brain)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (previewResult == null)
                        Text(
                          'Enter a payment amount to see how the ledger cascade distributes funds chronologically.',
                          style: theme.textTheme.bodySmall,
                        )
                      else ...[
                        Text(
                          'This payment will cover:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...previewResult.updatedInstallments.map((inst) {
                          final monthIdx = currentSchedule.indexWhere((s) => s.id == inst.id);
                          final monthNum = monthIdx != -1 ? monthIdx + 1 : '?';

                          String allocationDesc;
                          if (inst.customerStatus == RDInstallmentStatus.fullyPaid) {
                            allocationDesc = 'Fully Paid (covered ${inst.installmentAmount.toRupeeFormat()})';
                          } else {
                            allocationDesc = 'Partially Paid (allocated ${inst.customerPaidAmount.toRupeeFormat()})';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Month $monthNum: $allocationDesc',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (inst.lateFee > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(includes ${inst.lateFee.toRupeeFormat()} Late Fee)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        if (previewResult.leftoverAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Advance Credit (Leftover): ${previewResult.leftoverAmount.toRupeeFormat()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                AppSpacings.gapXl,
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    if (previewResult == null) return;

                    final Result<void, String> result = await ref
                        .read(rDLedgerControllerProvider.notifier)
                        .recordCustomerPayment(
                          rdId: deposit.id,
                          paymentAmount: amountValue,
                          paidDate: paidDate.value,
                          paymentMode: paymentMode.value,
                          currentSchedule: currentSchedule,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (result is Success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Payment recorded successfully!'),
                          ),
                        );
                      } else if (result is Failure<void, String>) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(result.error),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Record Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsibleTransactionsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const _CollapsibleTransactionsSection({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ExpansionTile(
        title: Text(
          'Payment History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        onExpansionChanged: (val) {
          isExpanded.value = val;
        },
        children: [
          if (isExpanded.value)
            _TransactionsList(deposit: deposit)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  final RecurringDeposit deposit;

  const _TransactionsList({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(rdTransactionsStreamProvider(deposit.id));
    final installments = ref.watch(rdInstallmentsStreamProvider(deposit.id)).value ?? const [];
    final theme = Theme.of(context);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingLg),
            child: Center(
              child: Text('No payments recorded yet.'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            List<List<dynamic>> modeIcon;
            switch (tx.paymentMode) {
              case RDPaymentMode.cash:
                modeIcon = HugeIcons.strokeRoundedCoins01;
                break;
              case RDPaymentMode.upi:
                modeIcon = HugeIcons.strokeRoundedCreditCard;
                break;
              case RDPaymentMode.cheque:
                modeIcon = HugeIcons.strokeRoundedTicket01;
                break;
              case RDPaymentMode.bankTransfer:
                modeIcon = HugeIcons.strokeRoundedBank;
                break;
            }

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: modeIcon,
                  size: AppDimensions.iconSm,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                tx.amount.toRupeeFormat(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Paid on ${tx.paidDate.toAppFormat()} via ${tx.paymentMode.displayName}',
              ),
              trailing: MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMoreVertical,
                      size: AppDimensions.iconMd,
                    ),
                    tooltip: t.common.moreOptions,
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit02,
                      size: AppDimensions.iconSm,
                    ),
                    child: const Text('Edit Payment'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => _EditPaymentBottomSheet(
                          deposit: deposit,
                          transaction: tx,
                          allTransactions: transactions,
                          currentSchedule: installments,
                        ),
                      );
                    },
                  ),
                  MenuItemButton(
                    leadingIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: AppDimensions.iconSm,
                      color: theme.colorScheme.error,
                    ),
                    child: Text(
                      'Delete Payment',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onPressed: () async {
                      final confirmed = await AppDialogs.confirmAction(
                        context,
                        title: 'Delete Payment',
                        content:
                            'Are you sure you want to delete this payment of ${tx.amount.toRupeeFormat()} made on ${tx.paidDate.toAppFormat()}? Installment allocations will be recalculated.',
                        confirmText: 'Delete',
                      );

                      if (confirmed == true && context.mounted) {
                        final result = await ref
                            .read(rDLedgerControllerProvider.notifier)
                            .deleteCustomerPayment(
                              transactionId: tx.id,
                              deposit: deposit,
                              currentSchedule: installments,
                              currentTransactions: transactions,
                            );

                        if (context.mounted) {
                          if (result is Success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Payment deleted and ledger recalculated.'),
                              ),
                            );
                          } else if (result is Failure<void, String>) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(result.error),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _EditPaymentBottomSheet extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final RDTransaction transaction;
  final List<RDTransaction> allTransactions;
  final List<RDInstallment> currentSchedule;

  const _EditPaymentBottomSheet({
    required this.deposit,
    required this.transaction,
    required this.allTransactions,
    required this.currentSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController(
      text: transaction.amount.toStringAsFixed(
        transaction.amount.truncateToDouble() == transaction.amount ? 0 : 2,
      ),
    );
    final paidDate = useState(transaction.paidDate);
    final paymentMode = useState(transaction.paymentMode);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final theme = Theme.of(context);

    final amountText = useListenable(amountController);
    final double amountValue = double.tryParse(amountText.text.trim()) ?? 0.0;

    final previewSchedule = useMemoized(() {
      if (amountValue <= 0.0) return null;
      final updatedTx = transaction.copyWith(
        amount: amountValue,
        paidDate: paidDate.value,
        paymentMode: paymentMode.value,
      );
      final updatedTxs = allTransactions
          .map((t) => t.id == transaction.id ? updatedTx : t)
          .toList();
      return RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: currentSchedule,
        transactions: updatedTxs,
        initialPaidInstallments: deposit.initialPaidInstallments,
      );
    }, [amountValue, paidDate.value, paymentMode.value, currentSchedule, allTransactions]);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Customer Payment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AppSpacings.gapLg,
                AppTextField(
                  controller: amountController,
                  labelText: 'Payment Amount',
                  isRequired: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixText: t.format.currencySymbol,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                AppSpacings.gapLg,
                Text(
                  'Payment Mode',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<RDPaymentMode>(
                  selected: {paymentMode.value},
                  onSelectionChanged: (selected) {
                    paymentMode.value = selected.first;
                  },
                  segments: RDPaymentMode.values.map((mode) {
                    List<List<dynamic>> icon;
                    switch (mode) {
                      case RDPaymentMode.cash:
                        icon = HugeIcons.strokeRoundedCoins01;
                        break;
                      case RDPaymentMode.upi:
                        icon = HugeIcons.strokeRoundedCreditCard;
                        break;
                      case RDPaymentMode.cheque:
                        icon = HugeIcons.strokeRoundedTicket01;
                        break;
                      case RDPaymentMode.bankTransfer:
                        icon = HugeIcons.strokeRoundedBank;
                        break;
                    }
                    return ButtonSegment<RDPaymentMode>(
                      value: mode,
                      label: Text(mode.displayName),
                      icon: HugeIcon(icon: icon, size: 16),
                    );
                  }).toList(),
                ),
                AppSpacings.gapLg,
                AppTextField(
                  readOnly: true,
                  labelText: 'Payment Date',
                  controller: TextEditingController(
                    text: paidDate.value.toAppFormat(),
                  ),
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: paidDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      paidDate.value = selected;
                    }
                  },
                ),
                AppSpacings.gapXl,
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedActivity01,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recalculated Allocation Preview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (previewSchedule == null)
                        Text(
                          'Enter a payment amount to preview recalculated schedule.',
                          style: theme.textTheme.bodySmall,
                        )
                      else ...[
                        Text(
                          'Updated Installment Allocations:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...previewSchedule
                            .where((inst) => inst.customerPaidAmount > 0)
                            .map((inst) {
                          final monthIdx =
                              currentSchedule.indexWhere((s) => s.id == inst.id);
                          final monthNum = monthIdx != -1 ? monthIdx + 1 : '?';

                          String allocationDesc;
                          if (inst.customerStatus ==
                              RDInstallmentStatus.fullyPaid) {
                            allocationDesc =
                                'Fully Paid (${inst.customerPaidAmount.toRupeeFormat()})';
                          } else {
                            allocationDesc =
                                'Partially Paid (${inst.customerPaidAmount.toRupeeFormat()})';
                          }

                          return Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.subdirectory_arrow_right,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Month $monthNum: $allocationDesc',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (inst.lateFee > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(includes ${inst.lateFee.toRupeeFormat()} Late Fee)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                AppSpacings.gapXl,
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    if (previewSchedule == null) return;

                    final updatedTx = transaction.copyWith(
                      amount: amountValue,
                      paidDate: paidDate.value,
                      paymentMode: paymentMode.value,
                      updatedAt: DateTime.now(),
                    );

                    final Result<void, String> result = await ref
                        .read(rDLedgerControllerProvider.notifier)
                        .updateCustomerPayment(
                          updatedTransaction: updatedTx,
                          deposit: deposit,
                          currentSchedule: currentSchedule,
                          currentTransactions: allTransactions,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (result is Success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Payment updated successfully!'),
                          ),
                        );
                      } else if (result is Failure<void, String>) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(result.error),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
