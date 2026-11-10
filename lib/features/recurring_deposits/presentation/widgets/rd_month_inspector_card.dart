import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Opens the month inspector for installment [installmentNo] of [rdId].
///
/// The sheet watches the live projection so a write made from inside it (absorb / clear
/// fee) is reflected immediately. "Collect" closes the sheet and opens the payment sheet
/// on the caller's context so the two never stack.
Future<void> showRDMonthInspectorSheet(
  BuildContext context, {
  required String rdId,
  required int installmentNo,
}) {
  return AppAdaptiveSheet.show<void>(
    context,
    builder: (sheetContext) => RDMonthInspectorSheet(
      rdId: rdId,
      installmentNo: installmentNo,
      onCollect: (amount) {
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        showRDLogPaymentSheet(context, rdId: rdId, initialAmount: amount);
      },
    ),
  );
}

/// Body of the month inspector: 3-column metric rows plus the month's actions.
class RDMonthInspectorSheet extends ConsumerWidget {
  final String rdId;
  final int installmentNo;
  final ValueChanged<double> onCollect;

  const RDMonthInspectorSheet({
    super.key,
    required this.rdId,
    required this.installmentNo,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(rdId));
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(rDLedgerControllerProvider).isLoading;

    Widget loaded(RDLedgerProjection projection) {
      final inst = projection.byNo(installmentNo);
      return inst == null
          ? ErrorStateView(message: t.recurringDeposits.depositNotFound)
          : _InspectorBody(
              rdId: rdId,
              installment: inst,
              nextDueNo: projection.summary.nextDueNo,
              now: now,
              isBusy: isBusy,
              onCollect: onCollect,
            );
    }

    final body = switch (projectionAsync) {
      AsyncData(:final value) => loaded(value),
      AsyncLoading(:final value?) => loaded(value),
      AsyncError(:final error) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(rdLedgerProjectionProvider(rdId)),
        ),
      AsyncLoading() => const _InspectorSkeleton(),
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLg,
          AppDimensions.paddingSm,
          AppDimensions.paddingLg,
          AppDimensions.paddingLg,
        ),
        child: body,
      ),
    );
  }
}

class _InspectorBody extends ConsumerWidget {
  final String rdId;
  final RDInstallment installment;

  /// Earliest open month of the account — the only month "Collect" may target, because
  /// payments are applied sequentially by the projector.
  final int? nextDueNo;
  final DateTime now;
  final bool isBusy;
  final ValueChanged<double> onCollect;

  const _InspectorBody({
    required this.rdId,
    required this.installment,
    required this.nextDueNo,
    required this.now,
    required this.isBusy,
    required this.onCollect,
  });

  Future<void> _absorbRemainingFee(BuildContext context, WidgetRef ref) async {
    final inspector = t.recurringDeposits.ledger.inspector;
    final inst = installment;
    // The one absorb rule: exactly `absorbableFee`, never principal.
    final amount = inst.absorbableFee;
    final monthNo = inst.installmentNo.toString();

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: inspector.absorbFeeTitle,
      content: inspector.absorbFeeContent(amount: amount.toRupeeFormat(), month: monthNo),
      confirmText: inspector.absorbRemainingFee(amount: amount.toRupeeFormat()),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(rDLedgerControllerProvider.notifier).absorbFee(
          rdId: rdId,
          installmentNo: inst.installmentNo,
          amount: amount,
        );
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: inspector.absorbFeeSuccess(
        amount: amount.toRupeeFormat(),
        month: monthNo,
      ),
    );
  }

  Future<void> _clearAbsorbedFee(BuildContext context, WidgetRef ref) async {
    final inspector = t.recurringDeposits.ledger.inspector;
    final result = await ref.read(rDLedgerControllerProvider.notifier).clearAbsorbedFee(
          rdId: rdId,
          installmentNo: installment.installmentNo,
        );
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: inspector.clearAbsorbedFeeSuccess(
        month: installment.installmentNo.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inspector = t.recurringDeposits.ledger.inspector;
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = installment;
    final status = inst.displayStatusAt(now);
    final visual = status.visual(scheme);
    final isBaseline = inst.isOpeningBaseline;

    final isOpen = !isBaseline && inst.outstandingAmount > 0;
    final isNextDue = nextDueNo != null && inst.installmentNo == nextDueNo;
    final canCollect = isOpen && isNextDue;
    final showCollectHint = isOpen && !isNextDue;
    final canAbsorbFee = !isBaseline && inst.absorbableFee > 0;
    final canClearAbsorbed = !isBaseline && inst.absorbedFee > 0;
    final depositedOn = inst.poDepositedOn;

    final metricRows = <Widget>[
      _MetricRow(
        label: inspector.installment,
        value: inst.installmentAmount.toRupeeFormat(),
        trailing: inst.installmentDate.toMonthYearFormat(),
      ),
      if (inst.lateFee > 0)
        _MetricRow(
          label: inspector.customerFee,
          value: inst.lateFee.toRupeeFormat(),
          trailing: inst.customerFeeDue > 0
              ? passbook.owes(amount: inst.customerFeeDue.toRupeeFormat())
              : t.common.notProvided,
        ),
      if (inst.poLateFee > 0)
        _MetricRow(
          label: inspector.poFee,
          value: inst.poLateFee.toRupeeFormat(),
          trailing: t.common.notProvided,
        ),
      if (inst.agentDelayCost > 0)
        _MetricRow(
          label: inspector.agentDelay,
          value: inst.agentDelayCost.toRupeeFormat(),
          trailing: t.common.notProvided,
          valueColor: scheme.error,
        ),
      if (inst.absorbedFee > 0)
        _MetricRow(
          label: inspector.absorbed,
          value: inst.absorbedFee.toRupeeFormat(),
          trailing: t.common.notProvided,
        ),
      _MetricRow(
        label: inspector.paid,
        value: inst.customerPaidAmount.toRupeeFormat(),
        trailing: inst.outstandingAmount > 0
            ? passbook.owes(amount: inst.outstandingAmount.toRupeeFormat())
            : inspector.paid,
        trailingColor: inst.outstandingAmount > 0 ? visual.foreground : scheme.primary,
      ),
      // No "deposited on" row when there is no date — the status chip already says so.
      if (depositedOn != null)
        _MetricRow(
          label: inspector.depositedOn,
          value: depositedOn.toAppFormat(),
          trailing: inst.poBatchId ?? t.common.notProvided,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar02,
              size: AppDimensions.iconSm,
              color: scheme.primary,
            ),
            AppSpacings.gapXs,
            Expanded(
              child: Text(
                inspector.monthTitle(
                  month: inst.installmentNo.toString(),
                  date: inst.dueDate.toAppFormat(),
                ),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpacings.gapSm,
            _StatusChip(visual: visual),
          ],
        ),
        AppSpacings.gapMd,
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            children: [
              for (var i = 0; i < metricRows.length; i++) ...[
                if (i > 0) const Divider(height: AppDimensions.dividerHeight),
                metricRows[i],
              ],
            ],
          ),
        ),
        if (showCollectHint) ...[
          AppSpacings.gapSm,
          Text(
            inspector.collectHint(month: nextDueNo.toString()),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (canCollect || canAbsorbFee || canClearAbsorbed) ...[
          AppSpacings.gapLg,
          if (canCollect)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppDimensions.minTapTarget),
              ),
              onPressed: isBusy ? null : () => onCollect(inst.outstandingAmount),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(passbook.collect),
            ),
          if (canAbsorbFee) ...[
            AppSpacings.gapSm,
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _absorbRemainingFee(context, ref),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedWallet02,
                size: AppDimensions.iconSm,
              ),
              label: Text(
                inspector.absorbRemainingFee(amount: inst.absorbableFee.toRupeeFormat()),
              ),
            ),
          ],
          if (canClearAbsorbed) ...[
            AppSpacings.gapSm,
            TextButton.icon(
              onPressed: isBusy ? null : () => _clearAbsorbedFee(context, ref),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconSm,
              ),
              label: Text(inspector.clearAbsorbedFee),
            ),
          ],
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RDStatusVisual visual;

  const _StatusChip({required this.visual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: visual.icon, size: AppDimensions.iconXs, color: visual.foreground),
          AppSpacings.gapXs,
          Text(
            visual.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: visual.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed 3-column row: label / value / trailing note.
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String trailing;
  final Color? valueColor;
  final Color? trailingColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.trailing,
    this.valueColor,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXs),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              trailing,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: trailingColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorSkeleton extends StatelessWidget {
  const _InspectorSkeleton();

  static const int _rows = 6;

  @override
  Widget build(BuildContext context) {
    final inspector = t.recurringDeposits.ledger.inspector;
    return Skeletonizer(
      enabled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _rows; i++)
            ListTile(
              dense: true,
              title: Text(inspector.installment),
              trailing: Text(inspector.paid),
            ),
        ],
      ),
    );
  }
}
