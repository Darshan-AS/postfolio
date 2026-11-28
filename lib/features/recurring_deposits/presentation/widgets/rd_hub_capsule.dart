import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// M3E uniform-tonal 2-step flipbook track (`Customer | PO`) on a Monthly Hub card.
///
/// Colors follow System 1 (`PO` is strictly binary Grey vs Green; `Customer` carries urgency,
/// `Partial`, `Paid`, or `Receivable` `Unpaid`) with zero borders across all states.
class RDHubStageCapsule extends StatelessWidget {
  const RDHubStageCapsule({super.key, required this.track});

  final RDHubStepTrack track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final financial = AppFinancialColors.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final card = ops.card;
    final statuses = t.recurringDeposits.ledger.statuses;

    switch (track) {
      case RDHubBaselineTrack():
        return ExcludeSemantics(
          child: RDStatusPill(
            visual: RDInstallmentDisplayStatus.baseline.visual(
              scheme,
              financial: financial,
            ),
          ),
        );
      case RDHubTwoStepTrack(:final customer, :final po):
        final mutedBg = scheme.surfaceContainerHighest;
        final mutedFg = scheme.onSurfaceVariant;

        final (s1Bg, s1Fg, s1Icon, s1Label) = switch (customer) {
          RDCustomerOverdue(:final months) => (
            financial.overdue.container,
            financial.overdue.onContainer,
            HugeIcons.strokeRoundedAlert01,
            months > 1 ? card.lateMonthsShort(n: months) : statuses.overdue,
          ),
          RDCustomerDueToday() => (
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            HugeIcons.strokeRoundedTimer02,
            statuses.dueToday,
          ),
          RDCustomerUpcoming() => (
            mutedBg,
            mutedFg,
            HugeIcons.strokeRoundedCoins01,
            card.stepUnpaid,
          ),
          RDCustomerPartial() => (
            financial.partial.container,
            financial.partial.onContainer,
            HugeIcons.strokeRoundedChartRing,
            card.partialShort,
          ),
          RDCustomerReceivable() => (
            financial.receivable.container,
            financial.receivable.onContainer,
            HugeIcons.strokeRoundedCoins01,
            card.stepUnpaid,
          ),
          RDCustomerPaid() => (
            financial.settled.container,
            financial.settled.onContainer,
            HugeIcons.strokeRoundedTick02,
            card.stepPaid,
          ),
        };

        final (s2Bg, s2Fg, s2Icon) = switch (po) {
          RDPoStep.pending => (
            mutedBg,
            mutedFg,
            HugeIcons.strokeRoundedBuilding03,
          ),
          RDPoStep.deposited => (
            financial.settled.container,
            financial.settled.onContainer,
            HugeIcons.strokeRoundedTick02,
          ),
        };

        const rOuter = Radius.circular(AppShapes.large);
        const rInner = Radius.circular(AppShapes.extraSmall);

        return ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _StepChip(
                  label: s1Label,
                  icon: s1Icon,
                  background: s1Bg,
                  foreground: s1Fg,
                  borderRadius: const BorderRadius.horizontal(
                    left: rOuter,
                    right: rInner,
                  ),
                  textStyle: emphasized.labelSmall,
                ),
              ),
              const SizedBox(width: AppShapes.groupGap),
              _StepChip(
                label: card.stepPo,
                icon: s2Icon,
                background: s2Bg,
                foreground: s2Fg,
                borderRadius: const BorderRadius.horizontal(
                  left: rInner,
                  right: rOuter,
                ),
                textStyle: emphasized.labelSmall,
              ),
            ],
          ),
        );
    }
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.borderRadius,
    required this.textStyle,
  });

  final String label;
  final AppIconData icon;
  final Color background;
  final Color foreground;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final iconSize = MediaQuery.textScalerOf(
      context,
    ).scale(AppDimensions.iconXs);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.stepChipMinHeight,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm,
            vertical: AppDimensions.paddingXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: iconSize, color: foreground),
              AppSpacings.gapXs,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
