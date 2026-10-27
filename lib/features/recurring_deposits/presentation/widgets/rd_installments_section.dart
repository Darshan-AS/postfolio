import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_heatmap.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_inspector_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_next_due_hero_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_schedule_action_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_yearly_accordion.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Schedule tab of the RD Detail screen: hero, KPIs, Manage PO bar, matrix/list.
///
/// All ephemeral state lives in hooks declared at the top of `build` (never inside an
/// `AsyncValue` branch). Every number shown comes from `rdLedgerProjectionProvider`.
class RDInstallmentsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final bool isEmbeddedTab;

  const RDInstallmentsSection({
    super.key,
    required this.deposit,
    this.isEmbeddedTab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- hooks (hoisted) -------------------------------------------------------------
    final pinnedMonthNo = useState<int?>(null);
    final isSelectionMode = useState(false);
    final selectedNos = useState<Set<int>>(const {});
    final isListView = useState(false);
    final isExpanded = useState(true);

    // --- providers -------------------------------------------------------------------
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(deposit.id));
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;
    final theme = Theme.of(context);

    void toggleSelection(int no) {
      final next = Set<int>.of(selectedNos.value);
      if (!next.remove(no)) next.add(no);
      selectedNos.value = next;
    }

    void setSelectionMode(bool enabled) {
      isSelectionMode.value = enabled;
      if (!enabled) selectedNos.value = const {};
    }

    Widget loaded(RDLedgerProjection projection) => _LoadedSchedule(
          rdId: deposit.id,
          projection: projection,
          now: now,
          isBusy: isBusy,
          isEmbeddedTab: isEmbeddedTab,
          pinnedMonthNo: pinnedMonthNo.value,
          onPinMonth: (no) => pinnedMonthNo.value = no,
          isSelectionMode: isSelectionMode.value,
          selectedNos: selectedNos.value,
          onToggleSelection: toggleSelection,
          onSetSelectionMode: setSelectionMode,
          isListView: isListView.value,
          onSetListView: (value) => isListView.value = value,
        );

    final content = switch (projectionAsync) {
      AsyncData(:final value) => loaded(value),
      // A re-projection in flight (e.g. after a write) keeps the previous frame visible.
      AsyncLoading(:final value?) => loaded(value),
      AsyncError(:final error) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(rdLedgerProjectionProvider(deposit.id)),
        ),
      AsyncLoading() => const _ScheduleSkeleton(),
    };

    if (isEmbeddedTab) return content;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          t.recurringDeposits.ledger.installmentsTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        onExpansionChanged: (value) => isExpanded.value = value,
        children: [if (isExpanded.value) content],
      ),
    );
  }
}

class _LoadedSchedule extends StatelessWidget {
  final String rdId;
  final RDLedgerProjection projection;
  final DateTime now;
  final bool isBusy;
  final bool isEmbeddedTab;
  final int? pinnedMonthNo;
  final ValueChanged<int?> onPinMonth;
  final bool isSelectionMode;
  final Set<int> selectedNos;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<bool> onSetSelectionMode;
  final bool isListView;
  final ValueChanged<bool> onSetListView;

  const _LoadedSchedule({
    required this.rdId,
    required this.projection,
    required this.now,
    required this.isBusy,
    required this.isEmbeddedTab,
    required this.pinnedMonthNo,
    required this.onPinMonth,
    required this.isSelectionMode,
    required this.selectedNos,
    required this.onToggleSelection,
    required this.onSetSelectionMode,
    required this.isListView,
    required this.onSetListView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final installments = projection.installments;

    if (installments.isEmpty) {
      return _EmptySchedule(rdId: rdId, isBusy: isBusy);
    }

    final nextDue = projection.nextDue;
    final nextDueNo = nextDue?.installmentNo;
    // Selection follows next-due until the user pins a month explicitly.
    final requestedNo = pinnedMonthNo ?? nextDueNo ?? 1;
    final effectiveNo = requestedNo.clamp(1, installments.length);
    final inspected = projection.byNo(effectiveNo)!;

    final selectedInstallments = [
      for (final no in selectedNos) ?projection.byNo(no),
    ];
    final depositable = [
      for (final inst in selectedInstallments)
        if (inst.displayStatusAt(now).canDepositToPo) inst,
    ];
    final revertible = [
      for (final inst in selectedInstallments)
        if (inst.displayStatusAt(now).canRevertPo) inst,
    ];

    final cashInHand = projection.summary.cashInHand;
    final pocketAdvance = projection.summary.pocketAdvance;

    return Padding(
      padding: isEmbeddedTab ? EdgeInsets.zero : const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RDNextDueHeroCard(
            rdId: rdId,
            projection: projection,
            now: now,
            isCollapsed: nextDueNo != null && effectiveNo == nextDueNo,
            isBusy: isBusy,
          ),
          AppSpacings.gapMd,
          if (cashInHand > 0 || pocketAdvance > 0) ...[
            RDInstallmentKpiRow(
              pendingPoAmount: cashInHand,
              advancedPoAmount: pocketAdvance,
            ),
            AppSpacings.gapMd,
          ],
          RDInstallmentActionBar(
            rdId: rdId,
            isSelectionMode: isSelectionMode,
            selectedCount: selectedInstallments.length,
            depositable: depositable,
            revertible: revertible,
            isBusy: isBusy,
            onToggleSelectionMode: onSetSelectionMode,
          ),
          AppSpacings.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ledger.installmentsTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(ledger.viewModes.grid),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedGridView,
                      size: AppDimensions.iconXs,
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(ledger.viewModes.list),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckList,
                      size: AppDimensions.iconXs,
                    ),
                  ),
                ],
                selected: {isListView},
                onSelectionChanged: (selection) => onSetListView(selection.first),
              ),
            ],
          ),
          AppSpacings.gapSm,
          if (!isListView) ...[
            RDInstallmentHeatmap(
              installments: installments,
              now: now,
              selectedMonthNo: effectiveNo,
              nextDueNo: nextDueNo,
              onSelectMonth: (no) => onPinMonth(no == nextDueNo ? null : no),
              isSelectionMode: isSelectionMode,
              selectedNos: selectedNos,
              onToggleSelection: onToggleSelection,
            ),
            AppSpacings.gapMd,
            RDMonthInspectorCard(
              rdId: rdId,
              installment: inspected,
              now: now,
              customerCredit: projection.customerCredit,
              isBusy: isBusy,
            ),
          ] else
            RDYearlyAccordion(
              rdId: rdId,
              installments: installments,
              now: now,
              isSelectionMode: isSelectionMode,
              selectedNos: selectedNos,
              isBusy: isBusy,
              onToggleSelection: onToggleSelection,
            ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final String rdId;
  final bool isBusy;

  const _EmptySchedule({required this.rdId, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingXl),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar03,
            size: AppDimensions.iconXl,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacings.gapMd,
          Text(
            ledger.schedule.emptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          AppSpacings.gapXs,
          Text(
            ledger.schedule.emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacings.gapLg,
          FilledButton.icon(
            onPressed: isBusy ? null : () => showRDLogPaymentSheet(context, rdId: rdId),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCoins01,
              size: AppDimensions.iconSm,
            ),
            label: Text(ledger.logPayment),
          ),
        ],
      ),
    );
  }
}

/// Shape-only placeholder rendered while the first projection loads.
class _ScheduleSkeleton extends StatelessWidget {
  const _ScheduleSkeleton();

  static const int _placeholderCells = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                size: AppDimensions.iconMd,
              ),
              title: Text(ledger.hero.title),
              subtitle: Text(ledger.installmentsTitle),
            ),
          ),
          AppSpacings.gapMd,
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.paddingXs,
                crossAxisSpacing: AppDimensions.paddingXs,
                children: [
                  for (var i = 0; i < _placeholderCells; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AppSpacings.gapMd,
          Card(
            elevation: 0,
            child: ListTile(
              title: Text(ledger.inspector.title),
              subtitle: Text(ledger.inspector.inspectHint),
            ),
          ),
        ],
      ),
    );
  }
}
