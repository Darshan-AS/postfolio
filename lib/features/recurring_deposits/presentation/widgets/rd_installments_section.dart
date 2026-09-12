import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RDInstallmentsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const RDInstallmentsSection({super.key, required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(true);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          t.recurringDeposits.ledger.installmentsTitle,
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
            _RDInstallmentsContent(deposit: deposit)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RDInstallmentsContent extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const _RDInstallmentsContent({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync =
        ref.watch(rdInstallmentsStreamProvider(deposit.id));
    final isSelectionMode = useState(false);
    final selectedIds = useState<Set<String>>({});
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return installmentsAsync.when(
      data: (installments) {
        if (installments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Text(ledger.noInstallments),
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
            if (pendingPoAmount > 0 || advancedPoAmount > 0) ...[
              RDInstallmentKpiRow(
                pendingPoAmount: pendingPoAmount,
                advancedPoAmount: advancedPoAmount,
              ),
              const Divider(height: AppDimensions.dividerHeight),
            ],
            RDInstallmentActionBar(
              deposit: deposit,
              installments: installments,
              isSelectionMode: isSelectionMode.value,
              selectedCount: selectedIds.value.length,
              unpaidSelected: unpaidSelected,
              paidSelected: paidSelected,
              onToggleSelectionMode: (mode) {
                isSelectionMode.value = mode;
                if (!mode) {
                  selectedIds.value = {};
                }
              },
              onClearSelection: () {
                selectedIds.value = {};
              },
            ),
            const Divider(height: AppDimensions.dividerHeight),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installments.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: AppDimensions.dividerHeight),
              itemBuilder: (context, index) {
                final inst = installments[index];
                final monthNum = index + 1;
                final isOpeningBaseline =
                    index < deposit.initialPaidInstallments;

                return RDInstallmentTile(
                  deposit: deposit,
                  installment: inst,
                  monthNum: monthNum,
                  isOpeningBaseline: isOpeningBaseline,
                  isSelectionMode: isSelectionMode.value,
                  isSelected: selectedIds.value.contains(inst.id),
                  onSelectionChanged: (checked) {
                    final current = Set<String>.from(selectedIds.value);
                    if (checked == true) {
                      current.add(inst.id);
                    } else {
                      current.remove(inst.id);
                    }
                    selectedIds.value = current;
                  },
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
            '${t.common.error}: $err',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class RDInstallmentKpiRow extends StatelessWidget {
  final double pendingPoAmount;
  final double advancedPoAmount;

  const RDInstallmentKpiRow({
    super.key,
    required this.pendingPoAmount,
    required this.advancedPoAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kpis = t.recurringDeposits.ledger.kpis;

    return Padding(
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
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kpis.pendingAtPo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacings.gapXs,
                    Text(
                      pendingPoAmount.toRupeeFormat(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (pendingPoAmount > 0 && advancedPoAmount > 0)
            AppSpacings.gapSm,
          if (advancedPoAmount > 0)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kpis.advancedPo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacings.gapXs,
                    Text(
                      advancedPoAmount.toRupeeFormat(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
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
}

class RDInstallmentActionBar extends ConsumerWidget {
  final RecurringDeposit deposit;
  final List<RDInstallment> installments;
  final bool isSelectionMode;
  final int selectedCount;
  final List<RDInstallment> unpaidSelected;
  final List<RDInstallment> paidSelected;
  final ValueChanged<bool> onToggleSelectionMode;
  final VoidCallback onClearSelection;

  const RDInstallmentActionBar({
    super.key,
    required this.deposit,
    required this.installments,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.unpaidSelected,
    required this.paidSelected,
    required this.onToggleSelectionMode,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: isSelectionMode
                ? Text(
                    ledger.kpis.selectedForPo(count: selectedCount.toString()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (!isSelectionMode) ...[
            FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => RDLogPaymentSheet(
                    deposit: deposit,
                    currentSchedule: installments,
                  ),
                );
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(ledger.logPayment),
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
                onPressed: () => onToggleSelectionMode(true),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  size: AppDimensions.iconSm,
                ),
                label: Text(ledger.managePo),
              ),
            ],
          ] else ...[
            TextButton(
              onPressed: () => onToggleSelectionMode(false),
              child: Text(t.common.cancel),
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
                    onToggleSelectionMode(false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            ledger.actions.depositSuccess(
                              count: toUpdate.length.toString(),
                            ),
                          ),
                        ),
                      );
                    }
                  } else if (result is Failure<void, String> &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(result.error),
                      ),
                    );
                  }
                },
                child: Text(
                  ledger.actions.deposit(
                    count: unpaidSelected.length.toString(),
                  ),
                ),
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
                    title: ledger.actions.revertConfirmTitle,
                    content: ledger.actions.revertConfirmContent(
                      count: paidSelected.length.toString(),
                    ),
                    confirmText: ledger.actions.revert(
                      count: paidSelected.length.toString(),
                    ),
                  );
                  if (confirmed != true) return;

                  final result = await ref
                      .read(rDLedgerControllerProvider.notifier)
                      .revertPoPayments(installments: paidSelected);

                  if (result is Success) {
                    onToggleSelectionMode(false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            ledger.actions.revertSuccess(
                              count: paidSelected.length.toString(),
                            ),
                          ),
                        ),
                      );
                    }
                  } else if (result is Failure<void, String> &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(result.error),
                      ),
                    );
                  }
                },
                child: Text(
                  ledger.actions.revert(
                    count: paidSelected.length.toString(),
                  ),
                ),
              ),
            ],
            if (selectedCount == 0) ...[
              AppSpacings.gapSm,
              FilledButton(
                onPressed: null,
                child: Text(ledger.actions.select),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class RDInstallmentTile extends ConsumerWidget {
  final RecurringDeposit deposit;
  final RDInstallment installment;
  final int monthNum;
  final bool isOpeningBaseline;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const RDInstallmentTile({
    super.key,
    required this.deposit,
    required this.installment,
    required this.monthNum,
    required this.isOpeningBaseline,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final inst = installment;
    final now = DateTime.now();
    final isOverdue = inst.isOverdueAt(now);
    final isPoPaid = inst.poStatus == RDPoStatus.paid;
    final displayedLateFee =
        isOpeningBaseline ? 0.0 : inst.dynamicLateFeeAt(now);

    Color statusColor;
    List<List<dynamic>> statusIcon;
    String statusText;

    if (inst.isFullySettled && isPoPaid) {
      statusColor = theme.colorScheme.primary;
      statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
      statusText = ledger.statuses.settled;
    } else if (inst.isInstallmentPaid && !isPoPaid) {
      if (!inst.isLateFeeResolved) {
        statusColor = theme.colorScheme.error;
        statusIcon = HugeIcons.strokeRoundedAlert01;
        statusText = ledger.statuses.collectedFeePending;
      } else {
        statusColor = theme.colorScheme.secondary;
        statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
        statusText = ledger.statuses.collectedPendingPo;
      }
    } else if (isPoPaid) {
      statusColor = theme.colorScheme.tertiary;
      statusIcon = HugeIcons.strokeRoundedAlert01;
      statusText = inst.customerPaidAmount > 0
          ? ledger.statuses.advancePartiallyRepaid
          : ledger.statuses.advancedToPo;
    } else if (inst.customerPaidAmount > 0) {
      statusColor = theme.colorScheme.secondary;
      statusIcon = HugeIcons.strokeRoundedAlert01;
      statusText = ledger.statuses.partiallyPaid;
    } else {
      statusColor = isOverdue ? theme.colorScheme.error : theme.colorScheme.outline;
      statusIcon = isOverdue
          ? HugeIcons.strokeRoundedAlert01
          : HugeIcons.strokeRoundedTimer02;
      statusText = isOverdue ? ledger.statuses.overdue : ledger.statuses.unpaid;
    }

    final titleRow = Row(
      children: [
        Text(
          ledger.installmentDetails.month(month: monthNum.toString()),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacings.gapSm,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXs + 2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: statusIcon,
                size: AppDimensions.iconXs - 2,
                color: statusColor,
              ),
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
        if (displayedLateFee > 0) ...[
          AppSpacings.gapSm,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: (inst.isLateFeeWaived
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: (inst.isLateFeeWaived
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.error)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              inst.isLateFeeWaived
                  ? ledger.installmentDetails.lateFeeWaived(
                      amount: displayedLateFee.toRupeeFormat(),
                    )
                  : (inst.paidLateFee >= displayedLateFee
                      ? ledger.installmentDetails.lateFeePaid(
                          amount: displayedLateFee.toRupeeFormat(),
                        )
                      : (inst.paidLateFee > 0
                          ? ledger.installmentDetails.lateFeePartial(
                              paid: inst.paidLateFee.toRupeeFormat(),
                              total: displayedLateFee.toRupeeFormat(),
                            )
                          : ledger.installmentDetails.lateFeePending(
                              amount: displayedLateFee.toRupeeFormat(),
                            ))),
              style: theme.textTheme.labelSmall?.copyWith(
                color: inst.isLateFeeWaived
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    final principalPaid =
        inst.customerPaidAmount.clamp(0.0, inst.installmentAmount);
    final lateFeePaid = inst.paidLateFee;

    final principalOwed = inst.outstandingPrincipal;
    final lateFeeOwed = inst.isLateFeeWaived
        ? 0.0
        : (displayedLateFee - inst.paidLateFee).clamp(0.0, double.infinity);
    final totalOwed = principalOwed + lateFeeOwed;

    final String paidBreakdown;
    if (lateFeePaid > 0) {
      paidBreakdown = ledger.installmentDetails.paidByCustomer(
        total: (principalPaid + lateFeePaid).toRupeeFormat(),
        principal: principalPaid.toRupeeFormat(),
        fee: lateFeePaid.toRupeeFormat(),
      );
    } else {
      paidBreakdown = ledger.installmentDetails.paidByCustomerOnly(
        principal: principalPaid.toRupeeFormat(),
      );
    }

    final String owedBreakdown;
    if (principalOwed > 0 && lateFeeOwed > 0) {
      owedBreakdown = ledger.installmentDetails.customerOwesBoth(
        total: totalOwed.toRupeeFormat(),
        principal: principalOwed.toRupeeFormat(),
        fee: lateFeeOwed.toRupeeFormat(),
      );
    } else if (principalOwed == 0 && lateFeeOwed > 0) {
      owedBreakdown = ledger.installmentDetails.customerOwesFeeOnly(
        total: totalOwed.toRupeeFormat(),
        fee: lateFeeOwed.toRupeeFormat(),
      );
    } else if (inst.isLateFeeWaived && principalOwed == 0) {
      owedBreakdown = ledger.installmentDetails.customerOwesWaived;
    } else if (inst.isLateFeeWaived && displayedLateFee > 0) {
      if (principalOwed > 0) {
        owedBreakdown = ledger.installmentDetails.customerOwesPrincipalWaived(
          total: totalOwed.toRupeeFormat(),
        );
      } else {
        owedBreakdown = ledger.installmentDetails.customerOwesWaived;
      }
    } else {
      owedBreakdown = ledger.installmentDetails.customerOwesPrincipal(
        total: totalOwed.toRupeeFormat(),
      );
    }

    final subtitleColumn = Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ledger.installmentDetails.dueInstallment(
              date: inst.dueDate.toAppFormat(),
              amount: inst.installmentAmount.toRupeeFormat(),
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (isOpeningBaseline) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    ledger.installmentDetails.openingBaseline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (inst.customerPaidAmount > 0 || inst.paidLateFee > 0)
              Text(
                paidBreakdown,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (totalOwed > 0 || (inst.isLateFeeWaived && displayedLateFee > 0))
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  owedBreakdown,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPoPaid
                        ? theme.colorScheme.tertiary
                        : isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isOverdue || isPoPaid
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            if (isPoPaid)
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    ledger.installmentDetails.depositedToPo(
                      date: inst.poPaidDate?.toAppFormat() ?? '',
                    ),
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
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert01,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.secondary,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    ledger.installmentDetails.pendingPoDeposit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );

    if (isSelectionMode) {
      return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: isSelected,
        onChanged: onSelectionChanged,
        title: titleRow,
        subtitle: subtitleColumn,
      );
    }

    final hasPendingFee = !isOpeningBaseline &&
        !inst.isLateFeeWaived &&
        displayedLateFee > 0 &&
        inst.paidLateFee < displayedLateFee;
    final canToggleWaiver =
        !isOpeningBaseline && (inst.isLateFeeWaived || hasPendingFee);

    return ListTile(
      title: titleRow,
      subtitle: subtitleColumn,
      trailing: !isSelectionMode && canToggleWaiver
          ? MenuAnchor(
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
                if (!inst.isLateFeeWaived)
                  MenuItemButton(
                    leadingIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                      size: AppDimensions.iconSm,
                      color: theme.colorScheme.secondary,
                    ),
                    child: Text(ledger.actions.forgiveFee),
                    onPressed: () async {
                      final pendingFeeAmount = (displayedLateFee - inst.paidLateFee)
                          .clamp(0.0, double.infinity);
                      final confirmed = await AppDialogs.confirmAction(
                        context,
                        title: ledger.actions.forgiveFeeTitle,
                        content: ledger.actions.forgiveFeeContent(
                          amount: pendingFeeAmount.toRupeeFormat(),
                          month: monthNum.toString(),
                        ),
                        confirmText: ledger.actions.forgiveFee,
                      );
                      if (confirmed == true && context.mounted) {
                        final result = await ref
                            .read(rDLedgerControllerProvider.notifier)
                            .toggleLateFeeWaiver(
                              installmentId: inst.id,
                              isWaived: true,
                            );
                        if (context.mounted) {
                          if (result is Success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  ledger.actions.forgiveFeeSuccess(
                                    month: monthNum.toString(),
                                  ),
                                ),
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
                  )
                else
                  MenuItemButton(
                    leadingIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert01,
                      size: AppDimensions.iconSm,
                      color: theme.colorScheme.error,
                    ),
                    child: Text(ledger.actions.reinstateFee),
                    onPressed: () async {
                      final result = await ref
                          .read(rDLedgerControllerProvider.notifier)
                          .toggleLateFeeWaiver(
                            installmentId: inst.id,
                            isWaived: false,
                          );
                      if (context.mounted) {
                        if (result is Success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                ledger.actions.reinstateFeeSuccess(
                                  month: monthNum.toString(),
                                ),
                              ),
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
                  ),
              ],
            )
          : null,
    );
  }
}

