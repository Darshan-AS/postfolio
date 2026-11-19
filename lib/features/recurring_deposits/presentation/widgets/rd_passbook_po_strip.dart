import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/expressive/app_menu.dart';

/// Post Office strip of the passbook: a raised tile reading "Ready to deposit: N months ·
/// ₹X" with **Deposit** and an overflow for "Deposit from pocket" / "Undo last PO deposit".
///
/// Deposits are sequential, so the strip only ever offers "the next N"; it never lets
/// the agent pick months.
class RDPassbookPoStrip extends ConsumerWidget {
  final String rdId;
  final RDPoReadiness readiness;
  final RDPoDeposit? latestPoDeposit;

  /// True when the month right after the ready block is still unpaid/partial, i.e. the
  /// agent could front it from pocket in the same visit.
  final bool canDepositFromPocket;
  final bool isBusy;

  const RDPassbookPoStrip({
    super.key,
    required this.rdId,
    required this.readiness,
    required this.latestPoDeposit,
    required this.canDepositFromPocket,
    required this.isBusy,
  });

  Future<void> _undoLatest(BuildContext context, WidgetRef ref) async {
    final passbook = t.recurringDeposits.ledger.passbook;
    final latest = latestPoDeposit;
    if (latest == null) return;
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: passbook.undoLastDepositTitle,
      content: passbook.undoLastDepositContent(
        count: latest.installmentCount.toString(),
        date: latest.depositedOn.toAppFormat(),
        amount: latest.amount.toRupeeFormat(),
      ),
      confirmText: passbook.undoLastDeposit,
      confirmBackgroundColor: scheme.errorContainer,
      confirmForegroundColor: scheme.onErrorContainer,
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

  /// Above this text scale the label needs the full width, so the actions move to a row of
  /// their own below it.
  static const double _stackAboveTextScale = AppDimensions.largeTextScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passbook = t.recurringDeposits.ledger.passbook;
    final hasReady = readiness.hasReady;
    final canUndo = latestPoDeposit != null;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackAboveTextScale;

    final label = !hasReady
        ? passbook.nothingReady
        : readiness.readyFee > 0
        ? passbook.readyToDepositWithFee(
            n: readiness.readyCount,
            amount: readiness.readyAmount.toRupeeFormat(),
            fee: readiness.readyFee.toRupeeFormat(),
          )
        : passbook.readyToDeposit(
            n: readiness.readyCount,
            amount: readiness.readyAmount.toRupeeFormat(),
          );

    // The tile stays on the raised tone either way; months waiting for the Post Office
    // are signalled by the tinted icon, the heavier label and the enabled button.
    final leading = HugeIcon(
      icon: HugeIcons.strokeRoundedBuilding03,
      size: AppDimensions.iconMd,
      color: hasReady ? scheme.primary : scheme.onSurfaceVariant,
    );
    final labelText = Text(
      label,
      style: hasReady
          ? AppTypography.emphasizedOf(
              context,
            ).bodyMedium?.copyWith(color: scheme.onSurface)
          : theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
    );
    final deposit = AppButton.tonal(
      label: passbook.deposit,
      expand: stacked,
      onPressed: isBusy || !hasReady
          ? null
          : () => showRDDepositSheet(
              context,
              rdId: rdId,
              initialCount: readiness.readyCount,
            ),
    );
    final menu = AppMenu(
      entries: [
        AppMenuEntry(
          label: passbook.depositFromPocket,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedWallet02,
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
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowTurnBackward,
            size: AppDimensions.iconSm,
          ),
          isDestructive: true,
          onPressed: canUndo ? () => _undoLatest(context, ref) : null,
        ),
      ],
      anchorBuilder: (context, open) => IconButton(
        padding: EdgeInsets.zero,
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
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedMoreVertical,
          size: AppDimensions.iconMd,
        ),
        tooltip: t.common.moreOptions,
        onPressed: isBusy ? null : open,
      ),
    );

    return Material(
      color: scheme.raised,
      shape: AppShapes.rounded(AppShapes.groupOuter),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // The overflow button brings its own inset, so the trailing edge needs little.
        padding: const EdgeInsetsDirectional.only(
          start: AppDimensions.paddingLg,
          top: AppDimensions.paddingSm,
          bottom: AppDimensions.paddingSm,
          end: AppDimensions.paddingXs,
        ),
        child: stacked
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
                        Expanded(child: labelText),
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
                  Expanded(child: labelText),
                  AppSpacings.gapSm,
                  deposit,
                  menu,
                ],
              ),
      ),
    );
  }
}
