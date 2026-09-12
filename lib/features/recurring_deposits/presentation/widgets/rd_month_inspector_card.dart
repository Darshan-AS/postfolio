import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
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

class RDMonthInspectorCard extends ConsumerWidget {
  final RecurringDeposit deposit;
  final RDInstallment installment;
  final int monthNum;
  final bool isOpeningBaseline;
  final List<RDInstallment> allInstallments;

  const RDMonthInspectorCard({
    super.key,
    required this.deposit,
    required this.installment,
    required this.monthNum,
    required this.isOpeningBaseline,
    required this.allInstallments,
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

    final principalPaid =
        inst.customerPaidAmount.clamp(0.0, inst.installmentAmount);
    final principalOwed = inst.outstandingPrincipal;
    final lateFeeOwed = inst.isLateFeeWaived
        ? 0.0
        : (displayedLateFee - inst.paidLateFee).clamp(0.0, double.infinity);
    final totalOwed = principalOwed + lateFeeOwed;

    // Status mapping
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
      statusColor =
          isOverdue ? theme.colorScheme.error : theme.colorScheme.outline;
      statusIcon = isOverdue
          ? HugeIcons.strokeRoundedAlert01
          : HugeIcons.strokeRoundedTimer02;
      statusText = isOverdue ? ledger.statuses.overdue : ledger.statuses.unpaid;
    }

    // Waiver permissions
    final hasPendingFee = !isOpeningBaseline &&
        !inst.isLateFeeWaived &&
        displayedLateFee > 0 &&
        inst.paidLateFee < displayedLateFee;
    final canToggleWaiver =
        !isOpeningBaseline && (inst.isLateFeeWaived || hasPendingFee);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Month Title & Status Badge & Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar02,
                        size: AppDimensions.iconSm,
                        color: theme.colorScheme.primary,
                      ),
                      AppSpacings.gapXs,
                      Flexible(
                        child: Text(
                          ledger.inspector.monthTitle(
                            month: monthNum.toString(),
                            date: inst.dueDate.toAppFormat(),
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacings.gapSm,
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: statusIcon,
                            size: AppDimensions.iconXs - 1,
                            color: statusColor,
                          ),
                          const SizedBox(width: 3),
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
                    if (canToggleWaiver) ...[
                      AppSpacings.gapXs,
                      MenuAnchor(
                        builder: (context, controller, child) {
                          return IconButton(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedMoreVertical,
                              size: AppDimensions.iconSm,
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
                              onPressed: () => _handleForgiveFee(
                                context,
                                ref,
                                displayedLateFee,
                              ),
                            )
                          else
                            MenuItemButton(
                              leadingIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedAlert01,
                                size: AppDimensions.iconSm,
                                color: theme.colorScheme.error,
                              ),
                              child: Text(ledger.actions.reinstateFee),
                              onPressed: () => _handleReinstateFee(context, ref),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            AppSpacings.gapMd,

            // Clean 2-Column Key Metric Rows
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                children: [
                  // Row 1: Principal
                  _buildMetricRow(
                    context,
                    label: ledger.inspector.principal,
                    value: inst.installmentAmount.toRupeeFormat(),
                    status: inst.isInstallmentPaid
                        ? '✓ ${ledger.statuses.settled}'
                        : (principalPaid > 0
                            ? ledger.inspector.paidDue(
                                paid: principalPaid.toRupeeFormat(),
                                due: principalOwed.toRupeeFormat(),
                              )
                            : ledger.inspector.amountDue(
                                due: principalOwed.toRupeeFormat(),
                              )),
                    isPositive: inst.isInstallmentPaid,
                  ),

                  // Row 2: Default Fee (Noise-Free: ONLY rendered if fee > 0 or waived!)
                  if (displayedLateFee > 0 || inst.isLateFeeWaived) ...[
                    const Divider(height: AppDimensions.dividerHeight),
                    _buildMetricRow(
                      context,
                      label: ledger.inspector.defaultFee,
                      value: displayedLateFee.toRupeeFormat(),
                      status: inst.isLateFeeWaived
                          ? ledger.preview.feeWaived
                          : (inst.paidLateFee >= displayedLateFee
                              ? '✓ ${ledger.inspector.paidTag}'
                              : (inst.paidLateFee > 0
                                  ? ledger.inspector.partiallyPaidTag(
                                      paid: inst.paidLateFee.toRupeeFormat(),
                                    )
                                  : ledger.inspector.pendingTag)),
                      isPositive: inst.isLateFeeWaived ||
                          inst.paidLateFee >= displayedLateFee,
                    ),
                  ],

                  // Row 3: Post Office Status
                  const Divider(height: AppDimensions.dividerHeight),
                  _buildMetricRow(
                    context,
                    label: ledger.inspector.poStatus,
                    value: isPoPaid
                        ? (inst.poPaidDate != null
                            ? inst.poPaidDate!.toAppFormat()
                            : ledger.statuses.settled)
                        : (isOpeningBaseline
                            ? ledger.installmentDetails.openingBaseline
                            : ledger.installmentDetails.pendingPoDeposit),
                    status: isPoPaid
                        ? '✓ ${ledger.inspector.depositedTag}'
                        : ledger.inspector.pendingPoTag,
                    isPositive: isPoPaid,
                  ),
                ],
              ),
            ),

            // Actions Row
            if (!isOpeningBaseline && (totalOwed > 0 || !isPoPaid)) ...[
              AppSpacings.gapMd,
              Row(
                children: [
                  if (totalOwed > 0)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) => RDLogPaymentSheet(
                              deposit: deposit,
                              currentSchedule: allInstallments,
                              initialAmount: totalOwed,
                            ),
                          );
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCoins01,
                          size: AppDimensions.iconSm,
                        ),
                        label: Text(ledger.logPayment),
                      ),
                    ),
                  if (inst.isInstallmentPaid && !isPoPaid) ...[
                    if (totalOwed > 0) AppSpacings.gapSm,
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final toUpdate = [
                            inst.copyWith(
                              poStatus: RDPoStatus.paid,
                              poPaidDate: DateTime.now(),
                            )
                          ];
                          final result = await ref
                              .read(rDLedgerControllerProvider.notifier)
                              .recordPoPayments(installments: toUpdate);
                          if (context.mounted && result is Success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  ledger.actions.depositSuccess(count: '1'),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          size: AppDimensions.iconSm,
                        ),
                        label: Text(ledger.actions.deposit(count: '1')),
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

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    required String status,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacings.gapSm,
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacings.gapXs,
                Text(
                  '($status)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPositive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgiveFee(
    BuildContext context,
    WidgetRef ref,
    double displayedLateFee,
  ) async {
    final ledger = t.recurringDeposits.ledger;
    final pendingFeeAmount =
        (displayedLateFee - installment.paidLateFee).clamp(0.0, double.infinity);

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
            installmentId: installment.id,
            isWaived: true,
          );

      if (context.mounted) {
        if (result is Success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                ledger.actions.forgiveFeeSuccess(month: monthNum.toString()),
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
  }

  Future<void> _handleReinstateFee(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ledger = t.recurringDeposits.ledger;
    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .toggleLateFeeWaiver(
          installmentId: installment.id,
          isWaived: false,
        );

    if (context.mounted) {
      if (result is Success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              ledger.actions.reinstateFeeSuccess(month: monthNum.toString()),
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
}

