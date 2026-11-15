import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Hero card at the top of the passbook: the month the customer owes on next, what is
/// outstanding on it, and the single **Collect** action.
///
/// [nextDue] is the earliest month the customer still owes on; when `null` the account
/// is fully paid and the card turns into an "all settled" note.
class RDPassbookNextDueLine extends StatelessWidget {
  final RDInstallment? nextDue;
  final DateTime now;
  final bool isBusy;
  final VoidCallback onCollect;

  const RDPassbookNextDueLine({
    super.key,
    required this.nextDue,
    required this.now,
    required this.isBusy,
    required this.onCollect,
  });

  /// Above this text scale the amount and the Collect button no longer fit side by side,
  /// so the button moves under the amount and takes the full width.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = nextDue;

    final financial = AppFinancialColors.of(context);

    if (inst == null) {
      final settled = financial.settled;
      return Material(
        color: settled.container,
        shape: AppShapes.rounded(AppShapes.extraLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Row(
            children: [
              AppShapeAvatar(
                shape: AppAvatarShape.cookie12,
                backgroundColor: settled.onContainer,
                foregroundColor: settled.container,
                child: const AppIcon(
                  HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: AppDimensions.iconMd,
                ),
              ),
              AppSpacings.gapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passbook.allSettled,
                      style: emphasized.titleMedium?.copyWith(
                        color: settled.onContainer,
                      ),
                    ),
                    AppSpacings.gapXxs,
                    Text(
                      passbook.allSettledHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: settled.onContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visual = inst.displayStatusAt(now).visual(scheme, financial: financial);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    // The amount is the hero of the card; it shrinks rather than wraps when width is tight.
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        inst.outstandingAmount.toRupeeFormat(),
        maxLines: 1,
        style: emphasized.headlineMedium?.copyWith(color: visual.foreground),
      ),
    );
    final collect = AppButton(
      label: passbook.collect,
      icon: HugeIcons.strokeRoundedCoins01,
      size: stacked ? AppButtonSize.medium : AppButtonSize.small,
      expand: stacked,
      onPressed: isBusy ? null : onCollect,
    );

    return Material(
      color: scheme.raised,
      shape: AppShapes.rounded(AppShapes.extraLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label and status share a line when they fit; the pill drops below otherwise.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingXs,
              children: [
                Text(
                  passbook.nextDue,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                RDStatusPill(visual: visual),
              ],
            ),
            AppSpacings.gapXs,
            Text(
              passbook.nextDueLine(
                month: inst.installmentNo.toString(),
                date: inst.dueDate.toAppFormat(),
              ),
              style: emphasized.titleMedium,
            ),
            AppSpacings.gapMd,
            if (stacked) ...[
              amount,
              AppSpacings.gapMd,
              collect,
            ] else
              Row(
                children: [
                  Expanded(child: amount),
                  AppSpacings.gapMd,
                  collect,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
