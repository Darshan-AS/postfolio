import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_menu.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Post Office strip of the passbook: a grouped row showing months collected in hand
/// (`In hand · N months` + `₹X ready for Post Office`) with tonal **Deposit**, or a
/// calm `Nothing collected to deposit yet` line when nothing is ready, plus the overflow
/// menu for "Deposit from pocket" and "Undo last PO deposit".
///
/// Deposits are sequential, so the strip only ever offers "the next N"; it never lets
/// the agent pick months.
class RDPassbookPoStrip extends ConsumerWidget {
  final String rdId;
  final RDPoReadiness readiness;
  final RDPoDeposit? latestPoDeposit;

  /// True when the month right after the ready block is still unpaid/partial, i.e. the
  /// agent could deposit it from pocket in the same visit.
  final bool canDepositFromPocket;
  final bool isBusy;

  /// Where this row sits inside the top passbook action group.
  final AppGroupPosition position;

  const RDPassbookPoStrip({
    super.key,
    required this.rdId,
    required this.readiness,
    required this.latestPoDeposit,
    required this.canDepositFromPocket,
    required this.isBusy,
    this.position = AppGroupPosition.single,
  });

  Future<void> _undoLatest(BuildContext context, WidgetRef ref) async {
    final passbook = t.recurringDeposits.ledger.passbook;
    final latest = latestPoDeposit;
    if (latest == null) return;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: passbook.undoLastDepositTitle,
      content: passbook.undoLastDepositContent(
        count: latest.installmentCount.toString(),
        date: latest.depositedOn.toAppFormat(),
        amount: latest.amount.toRupeeFormat(),
      ),
      confirmText: passbook.undoLastDeposit,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .undoLatestPoDeposit(rdId);
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: passbook.undoLastDepositSuccess,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final passbook = t.recurringDeposits.ledger.passbook;
    final hasReady = readiness.hasReady;
    final canUndo = latestPoDeposit != null;
    final stacked = AppDimensions.isLargeText(context);

    final leading = AppIcon(
      HugeIcons.strokeRoundedBuilding03,
      size: AppDimensions.iconMd,
      color: hasReady
          ? AppFinancialColors.of(context).inHand.accent
          : scheme.onSurfaceVariant,
    );

    final Widget labelContent = hasReady
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                passbook.inHandTitle(n: readiness.readyCount),
                style: emphasized.labelLarge?.copyWith(color: scheme.onSurface),
              ),
              AppSpacings.gapXxs,
              Text(
                readiness.readyFee > 0
                    ? passbook.inHandSubtitleWithFee(
                        amount: readiness.readyAmount.toRupeeFormat(),
                        fee: readiness.readyFee.toRupeeFormat(),
                      )
                    : passbook.inHandSubtitle(
                        amount: readiness.readyAmount.toRupeeFormat(),
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : Text(
            passbook.nothingReady,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );

    final Widget? deposit = hasReady
        ? AppButton.tonal(
            label: passbook.deposit,
            size: stacked ? AppButtonSize.medium : AppButtonSize.small,
            expand: stacked,
            onPressed: isBusy
                ? null
                : () => showRDDepositSheet(
                    context,
                    rdId: rdId,
                    initialCount: readiness.readyCount,
                  ),
          )
        : null;

    final menu = AppMenu(
      entries: [
        AppMenuEntry(
          label: passbook.depositFromPocket,
          icon: const AppIcon(
            HugeIcons.strokeRoundedWallet02,
            size: AppDimensions.iconSm,
          ),
          onPressed: canDepositFromPocket
              ? () => showRDDepositSheet(
                  context,
                  rdId: rdId,
                  initialCount: readiness.readyCount + 1,
                )
              : null,
        ),
        AppMenuEntry(
          label: passbook.undoLastDeposit,
          icon: const AppIcon(
            HugeIcons.strokeRoundedArrowTurnBackward,
            size: AppDimensions.iconSm,
          ),
          isDestructive: true,
          onPressed: canUndo ? () => _undoLatest(context, ref) : null,
        ),
      ],
      anchorBuilder: (context, open) => IconButton(
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(
            AppDimensions.minTapTarget,
            AppDimensions.minTapTarget,
          ),
          maximumSize: const Size(
            AppDimensions.minTapTarget,
            AppDimensions.minTapTarget,
          ),
          padding: EdgeInsets.zero,
        ),
        icon: const AppIcon(
          HugeIcons.strokeRoundedMoreVertical,
          size: AppDimensions.iconMd,
        ),
        tooltip: t.common.moreOptions,
        onPressed: isBusy ? null : open,
      ),
    );

    return AppGroupTile(
      position: position,
      color: scheme.raised,
      child: Padding(
        // The overflow button brings its own inset, so the trailing edge needs little.
        padding: const EdgeInsetsDirectional.only(
          start: AppDimensions.paddingLg,
          top: AppDimensions.paddingSm,
          bottom: AppDimensions.paddingSm,
          end: AppDimensions.paddingXs,
        ),
        child: stacked && deposit != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppDimensions.paddingMd,
                    ),
                    child: Row(
                      children: [
                        leading,
                        AppSpacings.gapMd,
                        Expanded(child: labelContent),
                      ],
                    ),
                  ),
                  AppSpacings.gapSm,
                  Row(
                    children: [
                      Expanded(child: deposit),
                      menu,
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  leading,
                  AppSpacings.gapMd,
                  Expanded(child: labelContent),
                  if (deposit != null) ...[AppSpacings.gapSm, deposit],
                  menu,
                ],
              ),
      ),
    );
  }
}
