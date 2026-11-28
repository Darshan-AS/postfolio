import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Hero card at the top of the passbook: the month the customer owes on next, what is
/// outstanding on it, and the single **Collect** action.
///
/// [nextDue] is the earliest month the customer still owes on; when `null` the account
/// turns into an Amber "All months collected" note if [hasReadyForPo] is true, or the
/// green "All installments settled" note otherwise.
class RDPassbookNextDueLine extends StatelessWidget {
  final RDInstallment? nextDue;
  final DateTime now;
  final bool isBusy;
  final bool hasReadyForPo;
  final double? collectAmount;
  final VoidCallback onCollect;

  /// Where this card sits when paired with the PO deposit row below it.
  final AppGroupPosition position;

  const RDPassbookNextDueLine({
    super.key,
    required this.nextDue,
    required this.now,
    required this.isBusy,
    this.hasReadyForPo = false,
    this.collectAmount,
    required this.onCollect,
    this.position = AppGroupPosition.single,
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
      final banner = hasReadyForPo ? financial.inHand : financial.settled;
      final bannerTitle = hasReadyForPo
          ? passbook.allCollected
          : passbook.allSettled;
      final bannerHint = hasReadyForPo
          ? passbook.allCollectedHint
          : passbook.allSettledHint;
      final bannerIcon = hasReadyForPo
          ? HugeIcons.strokeRoundedBuilding03
          : HugeIcons.strokeRoundedCheckmarkBadge01;
      return AppGroupTile(
        position: position,
        color: banner.container,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Row(
            children: [
              AppShapeAvatar(
                shape: AppAvatarShape.cookie12,
                backgroundColor: banner.onContainer,
                foregroundColor: banner.container,
                child: AppIcon(bannerIcon, size: AppDimensions.iconMd),
              ),
              AppSpacings.gapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitle,
                      style: emphasized.titleMedium?.copyWith(
                        color: banner.onContainer,
                      ),
                    ),
                    AppSpacings.gapXxs,
                    Text(
                      bannerHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: banner.onContainer,
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

    final status = inst.displayStatusAt(now);
    final visual = status.visual(scheme, financial: financial);
    final amountColor =
        status == RDInstallmentDisplayStatus.overdue ||
            status == RDInstallmentDisplayStatus.partiallyPaid ||
            status == RDInstallmentDisplayStatus.paidFromPocket
        ? visual.foreground
        : scheme.onSurface;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;
    final displayAmount = collectAmount ?? inst.outstandingAmount;
    final showsMultiMonthTotal =
        collectAmount != null &&
        !Money.equals(collectAmount!, inst.outstandingAmount);

    final contextLine = Text(
      '${passbook.toCollectLabel} · ${passbook.nextDueLine(month: inst.installmentNo.toString(), date: inst.dueDate.toDayMonthFormat())}',
      style: theme.textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );

    // The amount is the hero of the row; it shrinks rather than wraps when width is tight.
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        displayAmount.toRupeeFormat(),
        maxLines: 1,
        style: emphasized.headlineSmall?.copyWith(color: amountColor),
      ),
    );
    final totalOwedNote = showsMultiMonthTotal
        ? Text(
            passbook.totalOwedNote(
              month: inst.installmentNo.toString(),
              amount: inst.outstandingAmount.toRupeeFormat(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        : null;
    final collect = AppButton(
      label: passbook.collect,
      size: stacked ? AppButtonSize.medium : AppButtonSize.small,
      expand: stacked,
      onPressed: isBusy ? null : onCollect,
    );

    return AppGroupTile(
      position: position,
      color: scheme.raised,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            contextLine,
            AppSpacings.gapXs,
            if (stacked) ...[
              amount,
              if (totalOwedNote != null) ...[AppSpacings.gapXxs, totalOwedNote],
              AppSpacings.gapMd,
              collect,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        amount,
                        if (totalOwedNote != null) ...[
                          AppSpacings.gapXxs,
                          totalOwedNote,
                        ],
                      ],
                    ),
                  ),
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
