import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Post Office strip of the passbook: "Ready to deposit: N months · ₹X" with **Deposit**
/// and an overflow for "Deposit from pocket" / "Undo last PO deposit".
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

    final result =
        await ref.read(rDLedgerControllerProvider.notifier).undoLatestPoDeposit(rdId);
    if (!context.mounted) return;
    AppFeedback.showResult(context, result, successMessage: passbook.undoLastDepositSuccess);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passbook = t.recurringDeposits.ledger.passbook;
    final hasReady = readiness.hasReady;
    final canUndo = latestPoDeposit != null;

    final label = !hasReady
        ? passbook.nothingReady
        : readiness.readyFee > 0
            ? passbook.readyToDepositWithFee(
                count: readiness.readyCount.toString(),
                amount: readiness.readyAmount.toRupeeFormat(),
                fee: readiness.readyFee.toRupeeFormat(),
              )
            : passbook.readyToDeposit(
                count: readiness.readyCount.toString(),
                amount: readiness.readyAmount.toRupeeFormat(),
              );

    return Card(
      elevation: 0,
      color: hasReady ? scheme.primaryContainer : scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingXs,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBuilding03,
              size: AppDimensions.iconMd,
              color: hasReady ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            AppSpacings.gapSm,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasReady ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                  fontWeight: hasReady ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            AppSpacings.gapSm,
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: isBusy || !hasReady
                  ? null
                  : () => showRDDepositSheet(
                        context,
                        rdId: rdId,
                        initialCount: readiness.readyCount,
                      ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconXs,
              ),
              label: Text(passbook.deposit),
            ),
            MenuAnchor(
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
                MenuItemButton(
                  leadingIcon: const HugeIcon(
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
                  child: Text(passbook.depositFromPocket),
                ),
                MenuItemButton(
                  leadingIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowTurnBackward,
                    size: AppDimensions.iconSm,
                    color: canUndo ? scheme.error : null,
                  ),
                  onPressed: canUndo ? () => _undoLatest(context, ref) : null,
                  child: Text(
                    passbook.undoLastDeposit,
                    style: canUndo ? TextStyle(color: scheme.error) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
