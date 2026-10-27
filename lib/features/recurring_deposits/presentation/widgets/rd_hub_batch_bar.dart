import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Floating bar shown while rows are selected: summary + batch deposit / revert.
class RDHubBatchBar extends ConsumerWidget {
  const RDHubBatchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations.batchPo;
    final summary = ref.watch(batchSelectionSummaryProvider);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final actions = ref.read(rDMonthlyOperationsActionsProvider.notifier);
    final selection = ref.read(rDHubSelectionProvider.notifier);

    final depositCount = summary.depositable.length;
    final revertCount = summary.revertible.length;

    Future<void> onRevert() async {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: ops.revertConfirmTitle,
        content: ops.revertConfirmMessage(count: revertCount),
        confirmText: ops.revertButton,
        confirmBackgroundColor: theme.colorScheme.error,
        confirmForegroundColor: theme.colorScheme.onError,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.revertSelectedPo();
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: ops.revertSuccess(count: revertCount),
      );
    }

    Future<void> onDeposit() async {
      final base = ops.confirmMessage(
        count: depositCount,
        amount: (summary.collectedAmount + summary.fromPocketAmount).toRupeeFormat(),
      );
      final message = summary.fromPocketCount > 0
          ? '$base\n\n${ops.confirmBreakdown(collectedCount: summary.collectedCount.toString(), advanceCount: summary.fromPocketCount.toString())}'
          : base;
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: ops.confirmTitle,
        content: message,
        confirmText: ops.confirmButton,
      );
      if (confirmed != true || !context.mounted) return;
      final result = await actions.depositSelectedToPo();
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: ops.success(count: depositCount),
      );
    }

    return Card.filled(
      margin: const EdgeInsets.all(AppDimensions.paddingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingSm,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: AppDimensions.iconSm,
              ),
              tooltip: ops.deselectAll,
              onPressed: selection.clear,
            ),
            AppSpacings.gapXs,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ops.selectedSummary(
                      count: summary.count,
                      amount: summary.totalAmount.toRupeeFormat(),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary.fromPocketCount > 0)
                    Text(
                      ops.selectedBreakdown(
                        collected: summary.collectedAmount.toRupeeFormat(),
                        pocket: summary.fromPocketAmount.toRupeeFormat(),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (revertCount > 0) ...[
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: isBusy ? null : onRevert,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowTurnBackward,
                  size: AppDimensions.iconXs,
                  color: theme.colorScheme.onErrorContainer,
                ),
                label: Text(ops.revertAction(count: revertCount)),
              ),
              if (depositCount > 0) AppSpacings.gapXs,
            ],
            if (depositCount > 0)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: isBusy ? null : onDeposit,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedBuilding03,
                  size: AppDimensions.iconSm,
                  color: theme.colorScheme.onPrimary,
                ),
                label: Text(ops.action(count: depositCount)),
              ),
          ],
        ),
      ),
    );
  }
}
