import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_inspector_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_next_due_line.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_po_strip.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_yearly_accordion.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Passbook tab of the RD Detail screen: next-due line, PO strip and the month list.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- hooks (hoisted) -------------------------------------------------------------
    final isExpanded = useState(true);

    // --- providers -------------------------------------------------------------------
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(deposit.id));
    final latestPoDeposit = ref.watch(
      rdLedgerFactsProvider(deposit.id).select((async) => async.value?.latestPoDeposit),
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
          isEmbeddedTab: isEmbeddedTab,
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

class _Passbook extends StatelessWidget {
  final String rdId;
  final RDLedgerProjection projection;
  final RDPoDeposit? latestPoDeposit;
  final DateTime now;
  final bool isBusy;
  final bool isEmbeddedTab;

  const _Passbook({
    required this.rdId,
    required this.projection,
    required this.latestPoDeposit,
    required this.now,
    required this.isBusy,
    required this.isEmbeddedTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final installments = projection.installments;

    if (installments.isEmpty) {
      return _EmptyPassbook(rdId: rdId, isBusy: isBusy);
    }

    final summary = projection.summary;
    final nextDue = projection.nextDue;
    final readiness = projection.poReadiness;

    // Collect prefills everything owed (opening receivable, fronted months, arrears);
    // when nothing is owed yet it falls back to the next month's outstanding amount.
    final collectAmount = summary.owedByCustomer > 0
        ? summary.owedByCustomer
        : nextDue?.outstandingAmount;

    // The month right after the ready block: if the customer has not covered it, the
    // agent may front it from pocket in the same PO visit.
    final pocketCandidate = readiness.nextInstallmentNo == null
        ? null
        : projection.byNo(readiness.nextInstallmentNo! + readiness.readyCount);
    final canDepositFromPocket =
        pocketCandidate != null && !pocketCandidate.isCustomerSettled;

    return Padding(
      padding: isEmbeddedTab ? EdgeInsets.zero : const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RDPassbookNextDueLine(
            nextDue: nextDue,
            now: now,
            isBusy: isBusy,
            onCollect: () => showRDLogPaymentSheet(
              context,
              rdId: rdId,
              initialAmount: collectAmount,
            ),
          ),
          AppSpacings.gapSm,
          RDPassbookPoStrip(
            rdId: rdId,
            readiness: readiness,
            latestPoDeposit: latestPoDeposit,
            canDepositFromPocket: canDepositFromPocket,
            isBusy: isBusy,
          ),
          AppSpacings.gapMd,
          Text(
            ledger.installmentsTitle,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacings.gapSm,
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
      ),
    );
  }
}

class _EmptyPassbook extends StatelessWidget {
  final String rdId;
  final bool isBusy;

  const _EmptyPassbook({required this.rdId, required this.isBusy});

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
            label: Text(ledger.passbook.collect),
          ),
        ],
      ),
    );
  }
}

/// Shape-only placeholder rendered while the first projection loads.
class _PassbookSkeleton extends StatelessWidget {
  const _PassbookSkeleton();

  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
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
              title: Text(ledger.passbook.nextDue),
              subtitle: Text(ledger.installmentsTitle),
            ),
          ),
          AppSpacings.gapSm,
          Card(
            elevation: 0,
            child: ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconMd,
              ),
              title: Text(ledger.passbook.nothingReady),
            ),
          ),
          AppSpacings.gapMd,
          Card(
            elevation: 0,
            child: Column(
              children: [
                for (var i = 0; i < _placeholderRows; i++)
                  ListTile(
                    title: Text(ledger.installmentsTitle),
                    subtitle: Text(ledger.passbook.nextDue),
                    trailing: Text(ledger.passbook.collect),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
