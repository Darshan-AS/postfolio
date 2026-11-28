import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_layout.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Floating toolbar shown while rows are selected: clear the selection, what is selected,
/// and "Deposit N", which opens the Post Office visit planner seeded with the selected
/// depositable accounts.
///
/// A Material 3 Expressive floating toolbar in its vibrant colours: an elevated pill that
/// hugs its content and floats over the list. It is built from official widgets and
/// [AppButton], not from the community package's toolbar. At large text sizes the pill
/// becomes a rounded card with the action on its own row, so the summary keeps the full
/// width.
///
/// A PO visit deposits the *next contiguous collected months* of each selected account;
/// there is no per-month revert — only the latest visit of an account can be undone, from
/// the row's overflow menu.
class RDHubBatchBar extends ConsumerWidget {
  const RDHubBatchBar({super.key});

  /// Material elevation level 2, as for the app's menus and FABs.
  static const double _elevation = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ops = t.recurringDeposits.monthlyOperations;
    final strings = ops.batchPo;
    final summary = ref.watch(batchSelectionSummaryProvider);
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final selection = ref.read(rDHubSelectionProvider.notifier);

    final readyInstallments = summary.readyInstallments;
    // At large text the action moves under the summary.
    final stacked = RDHubLayout.isLargeText(context);

    void planVisit() {
      // The whole selection is the visit's scope; the planner lists the depositable rows and
      // only ever offers the selected unready ones for from-pocket deposits.
      ref.read(rDPoVisitPlannerProvider.notifier).start(items: summary.items);
      showRDPoVisitPlanner(context);
    }

    final clear = IconButton(
      icon: const AppIcon(HugeIcons.strokeRoundedCancel01),
      tooltip: strings.deselectAll,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onPrimaryContainer,
        minimumSize: const Size.square(AppDimensions.actionButtonSize),
      ),
      onPressed: selection.clear,
    );

    // Wraps instead of shrinking or being cut: the total stays readable at any width.
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.selectedSummary(
            count: summary.count,
            ready: readyInstallments,
            amount: summary.totalAmount.toRupeeFormat(),
          ),
          style: AppTypography.emphasizedOf(
            context,
          ).titleSmall?.copyWith(color: scheme.onPrimaryContainer),
        ),
        if (readyInstallments == 0)
          Text(
            strings.noneReady,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
      ],
    );

    final action = readyInstallments > 0
        ? AppButton(
            label: strings.action(count: readyInstallments),
            icon: HugeIcons.strokeRoundedBuilding03,
            expand: stacked,
            onPressed: isBusy ? null : planVisit,
          )
        : null;

    final content = stacked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  clear,
                  AppSpacings.gapXs,
                  Expanded(child: description),
                  AppSpacings.gapMd,
                ],
              ),
              if (action != null) ...[AppSpacings.gapXs, action],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              clear,
              AppSpacings.gapXs,
              Flexible(child: description),
              if (action != null) ...[
                AppSpacings.gapMd,
                action,
              ] else
                AppSpacings.gapLg,
            ],
          );

    final bar = Material(
      color: scheme.primaryContainer,
      elevation: _elevation,
      shadowColor: scheme.shadow,
      shape: stacked ? AppShapes.rounded(AppShapes.extraLarge) : AppShapes.pill,
      child: Padding(
        // The button is 40dp in a 64dp pill: 12dp above and below it, so 12dp after it.
        // With 8dp it sat off-centre in the pill's rounded end.
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimensions.paddingSm,
          AppDimensions.paddingSm,
          AppDimensions.paddingMd,
          AppDimensions.paddingSm,
        ),
        child: content,
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.all(AppDimensions.pageMargin),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: MediaQuery.disableAnimationsOf(context)
            ? bar
            : bar
                  .animate()
                  .fade(
                    duration: AppMotion.effectsFastDuration,
                    curve: AppMotion.effectsFastCurve,
                  )
                  .slideY(
                    begin: 1,
                    end: 0,
                    duration: AppMotion.spatialFastDuration,
                    curve: AppMotion.spatialFastCurve,
                  ),
      ),
    );
  }
}
