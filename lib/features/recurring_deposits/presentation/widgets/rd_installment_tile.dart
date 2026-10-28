import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// One passbook line: `#N · <month>` · due date · status chip, with the money column on
/// the right. Purely declarative — every number comes from the projected [installment].
///
/// Tapping opens the month inspector sheet; there are no per-month PO actions here
/// because deposits are sequential and live in the PO strip.
class RDInstallmentTile extends StatelessWidget {
  final RDInstallment installment;
  final DateTime now;
  final VoidCallback? onTap;

  const RDInstallmentTile({
    super.key,
    required this.installment,
    required this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = installment;
    final status = inst.displayStatusAt(now);
    final visual = status.visual(scheme);

    final String amountLabel;
    final Color amountColor;
    if (inst.isOpeningBaseline) {
      amountLabel = inst.installmentAmount.toRupeeFormat();
      amountColor = scheme.onSurfaceVariant;
    } else if (inst.isFrontedByAgent) {
      amountLabel = passbook.owes(amount: inst.outstandingAmount.toRupeeFormat());
      amountColor = visual.foreground;
    } else if (inst.isCustomerSettled) {
      amountLabel = passbook.amountPaid(amount: inst.dueAmount.toRupeeFormat());
      amountColor = scheme.onSurface;
    } else if (inst.isPartiallyPaid) {
      amountLabel = passbook.amountPartial(
        paid: inst.customerPaidAmount.toRupeeFormat(),
        due: inst.dueAmount.toRupeeFormat(),
      );
      amountColor = visual.foreground;
    } else if (inst.customerFeeDue > 0) {
      amountLabel = passbook.amountWithFee(
        amount: inst.dueAmount.toRupeeFormat(),
        fee: inst.customerFeeDue.toRupeeFormat(),
      );
      amountColor = status.isCustomerPending ? visual.foreground : scheme.onSurface;
    } else {
      amountLabel = inst.dueAmount.toRupeeFormat();
      amountColor = scheme.onSurface;
    }

    final captions = <String>[
      if (inst.absorbedFee > 0)
        passbook.feeAbsorbed(amount: inst.absorbedFee.toRupeeFormat()),
      if (inst.agentDelayCost > 0)
        passbook.agentDelay(amount: inst.agentDelayCost.toRupeeFormat()),
    ];

    return ListTile(
      onTap: onTap,
      title: Text(
        passbook.monthLabel(
          month: inst.installmentNo.toString(),
          monthName: inst.installmentDate.toMonthYearFormat(),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Wrap(
          spacing: AppDimensions.paddingSm,
          runSpacing: AppDimensions.paddingXs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              passbook.dueOn(date: inst.dueDate.toAppFormat()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            _StatusChip(visual: visual),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amountLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          for (final caption in captions)
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
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
          HugeIcon(icon: visual.icon, size: AppDimensions.iconXs, color: visual.foreground),
          AppSpacings.gapXxs,
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
