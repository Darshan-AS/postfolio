import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// One passbook line: `#N · <month>` with the money on the same row, then the due date
/// with the status pill, and captions underneath. Purely declarative — every number comes
/// from the projected [installment].
///
/// The line is a grouped tile: pass its [position] within the year so the months of a year
/// read as one container.
///
/// Tapping opens the month inspector sheet; there are no per-month PO actions here
/// because deposits are sequential and live in the PO strip.
class RDInstallmentTile extends StatelessWidget {
  final RDInstallment installment;
  final DateTime now;
  final VoidCallback? onTap;

  /// Where this month sits among the rows of its group.
  final AppGroupPosition position;

  const RDInstallmentTile({
    super.key,
    required this.installment,
    required this.now,
    this.onTap,
    this.position = AppGroupPosition.single,
  });

  /// Above this text scale the month and its amount no longer fit side by side, so every
  /// part of the line gets a row of its own.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  /// Share of the row the amount may take before it starts to shrink.
  static const double _amountMaxWidthFraction = 0.6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = installment;
    final status = inst.displayStatusAt(now);
    final visual = status.visualOf(context);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    final String amountLabel;
    final Color amountColor;
    if (inst.isOpeningBaseline) {
      amountLabel = inst.installmentAmount.toRupeeFormat();
      amountColor = scheme.onSurfaceVariant;
    } else if (inst.isPaidFromPocket) {
      amountLabel = passbook.owes(
        amount: inst.outstandingAmount.toRupeeFormat(),
      );
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
      amountColor = status.isCustomerPending
          ? visual.foreground
          : scheme.onSurface;
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

    final month = Text(
      passbook.monthLabel(
        month: inst.installmentNo.toString(),
        monthName: inst.installmentDate.toMonthYearFormat(),
      ),
      style: emphasized.bodyLarge,
    );
    // Amounts never wrap or truncate: the figure shrinks to the room it has.
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: stacked
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Text(
        amountLabel,
        maxLines: 1,
        style: emphasized.bodyLarge?.copyWith(color: amountColor),
      ),
    );
    final due = Text(
      passbook.dueOn(date: inst.dueDate.toAppFormat()),
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
    final pill = RDStatusPill(visual: visual);

    return AppGroupTile(
      position: position,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stacked) ...[
              month,
              amount,
            ] else
              LayoutBuilder(
                builder: (context, rowConstraints) {
                  final maxAmountWidth = rowConstraints.maxWidth.isFinite
                      ? rowConstraints.maxWidth * _amountMaxWidthFraction
                      : double.infinity;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: month),
                      AppSpacings.gapSm,
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxAmountWidth),
                        child: amount,
                      ),
                    ],
                  );
                },
              ),
            AppSpacings.gapXs,
            // Due date at the start, status at the end; the pill drops to the next line
            // when the two do not fit side by side.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingXs,
              children: [due, pill],
            ),
            for (final caption in captions) ...[
              AppSpacings.gapXs,
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
