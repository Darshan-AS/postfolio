import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Floating bar shown while rows are selected: summary + "Deposit N" which opens the Post
/// Office visit planner seeded with the selected depositable accounts.
///
/// A PO visit deposits the *next contiguous collected months* of each selected account;
/// there is no per-month revert — only the latest visit of an account can be undone, from
/// the row's overflow menu.
class RDHubBatchBar extends ConsumerWidget {
  const RDHubBatchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ops = t.recurringDeposits.monthlyOperations;
    final strings = ops.batchPo;
    final summary = ref.watch(batchSelectionSummaryProvider);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final selection = ref.read(rDHubSelectionProvider.notifier);

    final readyInstallments = summary.readyInstallments;

    void planVisit() {
      ref.read(rDPoVisitPlannerProvider.notifier).start(items: summary.depositable);
      showRDPoVisitPlanner(context);
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
              tooltip: strings.deselectAll,
              onPressed: selection.clear,
            ),
            AppSpacings.gapXs,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Money is never ellipsised: shrink to fit instead.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.selectedSummary(
                        count: summary.count,
                        ready: readyInstallments,
                        amount: summary.totalAmount.toRupeeFormat(),
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (readyInstallments == 0)
                    Text(
                      strings.noneReady,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (readyInstallments > 0)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: AppDimensions.paddingXs,
                  ),
                  minimumSize: const Size(0, AppDimensions.minTapTarget),
                ),
                onPressed: isBusy ? null : planVisit,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedBuilding03,
                  size: AppDimensions.iconSm,
                  color: theme.colorScheme.onPrimary,
                ),
                label: Text(strings.action(count: readyInstallments)),
              ),
          ],
        ),
      ),
    );
  }
}
