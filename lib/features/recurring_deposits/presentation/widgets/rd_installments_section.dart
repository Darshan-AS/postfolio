import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_inspector_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_next_due_line.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_po_strip.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_yearly_accordion.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Passbook tab of the RD Detail screen: next-due card, PO strip and the month list.
///
/// Every number shown comes from `rdLedgerProjectionProvider`; the only fact read directly
/// is the latest PO event (for "Undo last PO deposit"). Hooks are declared at the top of
/// `build`, never inside an `AsyncValue` branch.
class RDInstallmentsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final bool isEmbeddedTab;

  const RDInstallmentsSection({
    super.key,
    required this.deposit,
    this.isEmbeddedTab = false,
  });

  /// Half a turn: the chevron points up while the section is open.
  static const double _openChevronTurns = 0.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- hooks (hoisted) -------------------------------------------------------------
    final isExpanded = useState(true);

    // --- providers -------------------------------------------------------------------
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(deposit.id));
    final latestPoDeposit = ref.watch(
      rdLedgerFactsProvider(
        deposit.id,
      ).select((async) => async.value?.latestPoDeposit),
    );
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final theme = Theme.of(context);

    Widget loaded(RDLedgerProjection projection) => _Passbook(
      rdId: deposit.id,
      projection: projection,
      latestPoDeposit: latestPoDeposit,
      now: now,
      isBusy: isBusy,
    );

    final content = switch (projectionAsync) {
      AsyncData(:final value) => loaded(value),
      // A re-projection in flight (e.g. after a write) keeps the previous frame visible.
      AsyncLoading(:final value?) => loaded(value),
      AsyncError(:final error) => ErrorStateView(
        message: error.toString(),
        onRetry: () => ref.invalidate(rdLedgerProjectionProvider(deposit.id)),
      ),
      AsyncLoading() => const _PassbookSkeleton(),
    };

    if (isEmbeddedTab) return content;

    // Stand-alone: a header row that folds the passbook away. The passbook sits on the
    // page below the header rather than inside it, so its cards are not nested in a card.
    final isOpen = isExpanded.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGroupTile(
          onTap: () => isExpanded.value = !isOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingLg,
            ),
            child: Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedCalendar01,
                  size: AppDimensions.iconMd,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: Text(
                    t.recurringDeposits.ledger.installmentsTitle,
                    style: AppTypography.emphasizedOf(context).titleMedium,
                  ),
                ),
                AppSpacings.gapSm,
                AnimatedRotation(
                  turns: isOpen ? _openChevronTurns : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.spatialFastDuration,
                  curve: AppMotion.spatialFastCurve,
                  child: AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: AppDimensions.iconMd,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[AppSpacings.gapSm, content],
      ],
    );
  }
}

class _Passbook extends StatelessWidget {
  final String rdId;
  final RDLedgerProjection projection;
  final RDPoDeposit? latestPoDeposit;
  final DateTime now;
  final bool isBusy;

  const _Passbook({
    required this.rdId,
    required this.projection,
    required this.latestPoDeposit,
    required this.now,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    final installments = projection.installments;

    if (installments.isEmpty) {
      return _EmptyPassbook(rdId: rdId, isBusy: isBusy);
    }

    final summary = projection.summary;
    final nextDue = projection.nextDue;
    final readiness = projection.poReadiness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RDPassbookNextDueLine(
          nextDue: nextDue,
          now: now,
          isBusy: isBusy,
          hasReadyForPo: readiness.hasReady,
          collectAmount: projection.collectPrefillAmount,
          position: AppGroupPosition.first,
          onCollect: () async {
            final outcome = await showRDLogPaymentSheet(
              context,
              rdId: rdId,
              initialAmount: projection.collectPrefillAmount,
              showDepositFromPocketShortcut:
                  projection.canDepositFromPocket && !isBusy,
            );
            if (outcome == RDLogPaymentOutcome.depositFromPocket &&
                context.mounted) {
              await showRDDepositSheet(
                context,
                rdId: rdId,
                initialCount: readiness.readyCount + 1,
              );
            }
          },
        ),
        const SizedBox(height: AppShapes.groupGap),
        RDPassbookPoStrip(
          rdId: rdId,
          readiness: readiness,
          latestPoDeposit: latestPoDeposit,
          canDepositFromPocket: projection.canDepositFromPocket,
          isBusy: isBusy,
          position: AppGroupPosition.last,
        ),
        AppSpacings.gapLg,
        DetailSectionTitle(ledger.installmentsTitle),
        RDYearlyAccordion(
          rdId: rdId,
          installments: installments,
          now: now,
          nextDueNo: summary.nextDueNo,
          onTapMonth: (inst) => showRDMonthInspectorSheet(
            context,
            rdId: rdId,
            installmentNo: inst.installmentNo,
          ),
        ),
      ],
    );
  }
}

class _EmptyPassbook extends StatelessWidget {
  final String rdId;
  final bool isBusy;

  const _EmptyPassbook({required this.rdId, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    return EmptyStateView(
      icon: HugeIcons.strokeRoundedCalendar03,
      message: ledger.schedule.emptyTitle,
      subtitle: ledger.schedule.emptyHint,
      actionLabel: ledger.passbook.collect,
      isPrimaryAction: true,
      onAction: isBusy
          ? null
          : () => showRDLogPaymentSheet(context, rdId: rdId),
    );
  }
}

/// Shape-only placeholder rendered while the first projection loads.
class _PassbookSkeleton extends StatelessWidget {
  const _PassbookSkeleton();

  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroupTile(
            position: AppGroupPosition.first,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ledger.passbook.nextDue,
                    style: theme.textTheme.labelLarge,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    ledger.installmentsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacings.gapMd,
                  Text(
                    ledger.passbook.collect,
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppShapes.groupGap),
          AppGroupTile(
            position: AppGroupPosition.last,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Text(ledger.passbook.nothingReady),
            ),
          ),
          AppSpacings.gapLg,
          AppGroup(
            children: [
              for (var i = 0; i < _placeholderRows; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                    vertical: AppDimensions.paddingMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ledger.installmentsTitle),
                            AppSpacings.gapXs,
                            Text(
                              ledger.passbook.nextDue,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      AppSpacings.gapSm,
                      Text(ledger.passbook.collect),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
