import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_schedule_actions.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Detail panel for the month selected in the heatmap. Owns the primary "Log Payment" CTA.
class RDMonthInspectorCard extends ConsumerWidget {
  final String rdId;
  final RDInstallment installment;
  final DateTime now;
  final double customerCredit;
  final bool isBusy;

  const RDMonthInspectorCard({
    super.key,
    required this.rdId,
    required this.installment,
    required this.now,
    required this.customerCredit,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ledger = t.recurringDeposits.ledger;
    final inst = installment;
    final status = inst.displayStatusAt(now);
    final visual = status.visual(scheme);
    final isBaseline = inst.isOpeningBaseline;
    final monthNo = inst.installmentNo!;

    final displayedLateFee = isBaseline ? 0.0 : inst.dynamicLateFeeAt(now);
    final principalPaid = inst.customerPaidAmount.clamp(0.0, inst.installmentAmount);
    final principalOwed = inst.outstandingPrincipal;
    final lateFeeOwed = inst.outstandingLateFeeAt(now);
    final totalOwed = inst.outstandingAmountAt(now);
    final isFeePaid = inst.paidLateFee >= displayedLateFee;

    final hasPendingFee = !isBaseline && !inst.isLateFeeWaived && lateFeeOwed > 0;
    final canToggleWaiver = !isBaseline && (inst.isLateFeeWaived || hasPendingFee);
    final showMenu = canToggleWaiver || status.canRevertPo;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.primary, width: AppDimensions.borderSm),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar02,
                  size: AppDimensions.iconSm,
                  color: scheme.primary,
                ),
                AppSpacings.gapXs,
                Expanded(
                  child: Text(
                    ledger.inspector.monthTitle(
                      month: monthNo.toString(),
                      date: inst.dueDate.toAppFormat(),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacings.gapSm,
                _StatusChip(visual: visual),
                if (showMenu) ...[
                  AppSpacings.gapXs,
                  MenuAnchor(
                    builder: (context, controller, child) => IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMoreVertical,
                        size: AppDimensions.iconSm,
                      ),
                      tooltip: t.common.moreOptions,
                      onPressed: isBusy
                          ? null
                          : () => controller.isOpen
                              ? controller.close()
                              : controller.open(),
                    ),
                    menuChildren: [
                      if (canToggleWaiver && !inst.isLateFeeWaived)
                        MenuItemButton(
                          leadingIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                            size: AppDimensions.iconSm,
                            color: scheme.secondary,
                          ),
                          child: Text(ledger.actions.forgiveFee),
                          onPressed: () => RDScheduleActions.setFeeWaiver(
                            context,
                            ref,
                            rdId: rdId,
                            installment: inst,
                            waived: true,
                            pendingFeeAmount: lateFeeOwed,
                          ),
                        ),
                      if (canToggleWaiver && inst.isLateFeeWaived)
                        MenuItemButton(
                          leadingIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedAlert01,
                            size: AppDimensions.iconSm,
                            color: scheme.error,
                          ),
                          child: Text(ledger.actions.reinstateFee),
                          onPressed: () => RDScheduleActions.setFeeWaiver(
                            context,
                            ref,
                            rdId: rdId,
                            installment: inst,
                            waived: false,
                            pendingFeeAmount: 0,
                          ),
                        ),
                      if (status.canRevertPo)
                        MenuItemButton(
                          leadingIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowTurnBackward,
                            size: AppDimensions.iconSm,
                            color: scheme.error,
                          ),
                          child: Text(ledger.actions.revertPo),
                          onPressed: () => RDScheduleActions.confirmAndRevertPo(
                            context,
                            ref,
                            rdId: rdId,
                            installments: [inst],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            AppSpacings.gapMd,
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                children: [
                  _MetricRow(
                    label: ledger.inspector.principal,
                    value: inst.installmentAmount.toRupeeFormat(),
                    chipLabel: isBaseline
                        ? visual.label
                        : inst.isInstallmentPaid
                            ? ledger.inspector.paidTag
                            : principalPaid > 0
                                ? ledger.inspector.partiallyPaidTag(
                                    paid: principalPaid.toRupeeFormat(),
                                  )
                                : ledger.inspector.amountDue(
                                    due: principalOwed.toRupeeFormat(),
                                  ),
                    chipVisual: isBaseline
                        ? visual
                        : inst.isInstallmentPaid
                            ? RDInstallmentDisplayStatus.settled.visual(scheme)
                            : principalPaid > 0
                                ? RDInstallmentDisplayStatus.partiallyPaid.visual(scheme)
                                : inst.isOverdueAt(now)
                                    ? RDInstallmentDisplayStatus.overdue.visual(scheme)
                                    : RDInstallmentDisplayStatus.upcoming.visual(scheme),
                  ),
                  if (displayedLateFee > 0 || inst.isLateFeeWaived) ...[
                    const Divider(height: AppDimensions.dividerHeight),
                    _MetricRow(
                      label: ledger.inspector.defaultFee,
                      value: displayedLateFee.toRupeeFormat(),
                      chipLabel: inst.isLateFeeWaived
                          ? ledger.inspector.waivedTag
                          : isFeePaid
                              ? ledger.inspector.paidTag
                              : inst.paidLateFee > 0
                                  ? ledger.inspector.partiallyPaidTag(
                                      paid: inst.paidLateFee.toRupeeFormat(),
                                    )
                                  : ledger.inspector.pendingTag,
                      chipVisual: inst.isLateFeeWaived
                          ? RDInstallmentDisplayStatus.baseline.visual(scheme)
                          : isFeePaid
                              ? RDInstallmentDisplayStatus.settled.visual(scheme)
                              : RDInstallmentDisplayStatus.feePending.visual(scheme),
                    ),
                  ],
                  const Divider(height: AppDimensions.dividerHeight),
                  _MetricRow(
                    label: ledger.inspector.poStatus,
                    value: inst.isPoDeposited
                        ? (inst.poPaidDate?.toAppFormat() ?? ledger.inspector.depositedTag)
                        : t.common.notProvided,
                    chipLabel: isBaseline
                        ? visual.label
                        : inst.isPoDeposited
                            ? ledger.inspector.depositedTag
                            : ledger.inspector.pendingPoTag,
                    chipVisual: isBaseline
                        ? visual
                        : inst.isPoDeposited
                            ? RDInstallmentDisplayStatus.settled.visual(scheme)
                            : RDInstallmentDisplayStatus.collectedPendingPo.visual(scheme),
                  ),
                  if (customerCredit > 0) ...[
                    const Divider(height: AppDimensions.dividerHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingXs,
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedWallet02,
                            size: AppDimensions.iconXs,
                            color: scheme.primary,
                          ),
                          AppSpacings.gapXs,
                          Expanded(
                            child: Text(
                              ledger.statuses.customerCredit(
                                amount: customerCredit.toRupeeFormat(),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isBaseline && (totalOwed > 0 || status.canDepositToPo)) ...[
              AppSpacings.gapMd,
              Row(
                children: [
                  if (totalOwed > 0)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => showRDLogPaymentSheet(
                                  context,
                                  rdId: rdId,
                                  initialAmount: totalOwed,
                                  initialSplitMode: lateFeeOwed > 0
                                      ? PaymentSplitMode.includeFees
                                      : PaymentSplitMode.installmentsOnly,
                                ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCoins01,
                          size: AppDimensions.iconSm,
                        ),
                        label: Text(ledger.logPayment),
                      ),
                    ),
                  if (status.canDepositToPo) ...[
                    if (totalOwed > 0) AppSpacings.gapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => RDScheduleActions.confirmAndDepositToPo(
                                  context,
                                  ref,
                                  rdId: rdId,
                                  installments: [inst],
                                  offerUndo: true,
                                ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedBuilding03,
                          size: AppDimensions.iconSm,
                        ),
                        label: Text(ledger.actions.depositSingle),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RDStatusVisual visual;

  const _StatusChip({required this.visual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: visual.icon,
            size: AppDimensions.iconXs,
            color: visual.foreground,
          ),
          AppSpacings.gapXs,
          Text(
            visual.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: visual.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed 3-column row: label / value / status chip.
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String chipLabel;
  final RDStatusVisual chipVisual;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.chipLabel,
    required this.chipVisual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXs),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.paddingXxs,
                ),
                decoration: BoxDecoration(
                  color: chipVisual.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  chipLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: chipVisual.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
