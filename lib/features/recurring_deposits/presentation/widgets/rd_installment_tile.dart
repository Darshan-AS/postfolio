import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_schedule_actions.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// One row of the yearly schedule list.
class RDInstallmentTile extends ConsumerWidget {
  final String rdId;
  final RDInstallment installment;
  final DateTime now;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isBusy;
  final ValueChanged<bool?>? onSelectionChanged;

  const RDInstallmentTile({
    super.key,
    required this.rdId,
    required this.installment,
    required this.now,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isBusy,
    this.onSelectionChanged,
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
    final lateFeeOwed = inst.outstandingLateFeeAt(now);
    final principalPaid = inst.customerPaidAmount.clamp(0.0, inst.installmentAmount);
    final principalOwed = inst.outstandingPrincipal;
    final totalOwed = inst.outstandingAmountAt(now);

    final hasPendingFee = !isBaseline && !inst.isLateFeeWaived && lateFeeOwed > 0;
    final canToggleWaiver = !isBaseline && (inst.isLateFeeWaived || hasPendingFee);

    final title = Wrap(
      spacing: AppDimensions.paddingSm,
      runSpacing: AppDimensions.paddingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          ledger.installmentDetails.monthShort(month: monthNo.toString()),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        _Pill(
          icon: visual.icon,
          label: visual.label,
          foreground: visual.foreground,
          background: visual.background,
        ),
        if (displayedLateFee > 0)
          _Pill(
            label: inst.isLateFeeWaived
                ? ledger.installmentDetails.lateFeeWaived(
                    amount: displayedLateFee.toRupeeFormat(),
                  )
                : inst.paidLateFee >= displayedLateFee
                    ? ledger.installmentDetails.lateFeePaid(
                        amount: displayedLateFee.toRupeeFormat(),
                      )
                    : inst.paidLateFee > 0
                        ? ledger.installmentDetails.lateFeePartial(
                            paid: inst.paidLateFee.toRupeeFormat(),
                            total: displayedLateFee.toRupeeFormat(),
                          )
                        : ledger.installmentDetails.lateFeePending(
                            amount: displayedLateFee.toRupeeFormat(),
                          ),
            foreground: inst.isLateFeeWaived ? scheme.onSurfaceVariant : scheme.onErrorContainer,
            background: inst.isLateFeeWaived ? scheme.surfaceContainerHigh : scheme.errorContainer,
          ),
      ],
    );

    final String? paidLine = (inst.customerPaidAmount > 0 || inst.paidLateFee > 0)
        ? (inst.paidLateFee > 0
            ? ledger.installmentDetails.paidByCustomer(
                total: (principalPaid + inst.paidLateFee).toRupeeFormat(),
                principal: principalPaid.toRupeeFormat(),
                fee: inst.paidLateFee.toRupeeFormat(),
              )
            : ledger.installmentDetails.paidByCustomerOnly(
                principal: principalPaid.toRupeeFormat(),
              ))
        : null;

    final String? owedLine;
    if (principalOwed > 0 && lateFeeOwed > 0) {
      owedLine = ledger.installmentDetails.customerOwesBoth(
        total: totalOwed.toRupeeFormat(),
        principal: principalOwed.toRupeeFormat(),
        fee: lateFeeOwed.toRupeeFormat(),
      );
    } else if (principalOwed == 0 && lateFeeOwed > 0) {
      owedLine = ledger.installmentDetails.customerOwesFeeOnly(
        total: totalOwed.toRupeeFormat(),
        fee: lateFeeOwed.toRupeeFormat(),
      );
    } else if (inst.isLateFeeWaived && displayedLateFee > 0) {
      owedLine = principalOwed > 0
          ? ledger.installmentDetails.customerOwesPrincipalWaived(
              total: totalOwed.toRupeeFormat(),
            )
          : ledger.installmentDetails.customerOwesWaived;
    } else if (principalOwed > 0) {
      owedLine = ledger.installmentDetails.customerOwesPrincipal(
        total: totalOwed.toRupeeFormat(),
      );
    } else {
      owedLine = null;
    }

    final subtitle = Padding(
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
          if (isBaseline)
            Text(
              ledger.installmentDetails.openingBaseline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (paidLine != null)
              Text(
                paidLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (owedLine != null)
              Text(
                owedLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: status.isCustomerPending ? visual.foreground : scheme.onSurfaceVariant,
                  fontWeight: status.isCustomerPending ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (inst.isPoDeposited)
              Text(
                ledger.installmentDetails.depositedToPo(
                  date: inst.poPaidDate?.toAppFormat() ?? t.common.notProvided,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (inst.isInstallmentPaid)
              Text(
                ledger.installmentDetails.pendingPoDeposit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ],
      ),
    );

    if (isSelectionMode) {
      if (isBaseline) {
        return ListTile(
          leading: SizedBox(
            width: AppDimensions.minTapTarget,
            child: Center(
              child: Text(
                visual.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          title: title,
          subtitle: subtitle,
        );
      }
      return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: isSelected,
        onChanged: isBusy ? null : onSelectionChanged,
        title: title,
        subtitle: subtitle,
      );
    }

    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: canToggleWaiver
          ? MenuAnchor(
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
                if (!inst.isLateFeeWaived)
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
                  )
                else
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
              ],
            )
          : null,
    );
  }
}

class _Pill extends StatelessWidget {
  final List<List<dynamic>>? icon;
  final String label;
  final Color foreground;
  final Color background;

  const _Pill({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
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
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HugeIcon(icon: icon!, size: AppDimensions.iconXs, color: foreground),
            AppSpacings.gapXxs,
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
