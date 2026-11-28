import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_capsule.dart';
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
      onCollect: (amount) {},
      onCollectFromSheet: (req) async {
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        final outcome = await showRDLogPaymentSheet(
          context,
          rdId: rdId,
          initialAmount: req.amount,
          showDepositFromPocketShortcut: req.canDepositFromPocket,
        );
        if (outcome == RDLogPaymentOutcome.depositFromPocket &&
            context.mounted) {
          await showRDDepositSheet(
            context,
            rdId: rdId,
            initialCount: req.fromPocketCount,
          );
        }
      },
    ),
  );
}

typedef RDInspectorCollectRequest = ({
  double amount,
  bool canDepositFromPocket,
  int fromPocketCount,
});

/// Body of the month inspector: the month's money rows as a group of tonal tiles, plus the
/// month's actions.
class RDMonthInspectorSheet extends ConsumerWidget {
  final String rdId;
  final int installmentNo;
  final ValueChanged<double> onCollect;
  final ValueChanged<RDInspectorCollectRequest>? onCollectFromSheet;

  const RDMonthInspectorSheet({
    super.key,
    required this.rdId,
    required this.installmentNo,
    required this.onCollect,
    this.onCollectFromSheet,
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
              onCollect: () {
                if (onCollectFromSheet != null) {
                  onCollectFromSheet!((
                    amount:
                        projection.collectPrefillAmount ??
                        inst.outstandingAmount,
                    canDepositFromPocket:
                        projection.canDepositFromPocket && !isBusy,
                    fromPocketCount: projection.poReadiness.readyCount + 1,
                  ));
                } else {
                  onCollect(inst.outstandingAmount);
                }
              },
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
        padding: EdgeInsets.fromLTRB(
          AppDimensions.pageMargin,
          // A bottom sheet has its drag handle above the title; a dialog has nothing, so
          // the title needs the same inset as the sides.
          AppAdaptiveSheet.isCompact(context)
              ? AppDimensions.paddingSm
              : AppDimensions.paddingLg,
          AppDimensions.pageMargin,
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
  final VoidCallback onCollect;

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
      content: inspector.absorbFeeContent(
        amount: amount.toRupeeFormat(),
        month: monthNo,
      ),
      confirmText: inspector.absorbRemainingFee(amount: amount.toRupeeFormat()),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .absorbFee(
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
    final result = await ref
        .read(rDLedgerControllerProvider.notifier)
        .clearAbsorbedFee(rdId: rdId, installmentNo: installment.installmentNo);
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
    final financial = AppFinancialColors.of(context);
    final inspector = t.recurringDeposits.ledger.inspector;
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = installment;
    final status = inst.displayStatusAt(now);
    final visual = status.visual(scheme, financial: financial);
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
              : null,
        ),
      if (inst.poLateFee > 0)
        _MetricRow(
          label: inspector.poFee,
          value: inst.poLateFee.toRupeeFormat(),
        ),
      if (inst.agentDelayCost > 0)
        _MetricRow(
          label: inspector.agentDelay,
          value: inst.agentDelayCost.toRupeeFormat(),
          valueColor: financial.overdue.onContainer,
        ),
      if (inst.absorbedFee > 0)
        _MetricRow(
          label: inspector.absorbed,
          value: inst.absorbedFee.toRupeeFormat(),
        ),
      _MetricRow(
        label: inspector.paid,
        value: inst.customerPaidAmount.toRupeeFormat(),
        trailing: inst.outstandingAmount > 0
            ? passbook.owes(amount: inst.outstandingAmount.toRupeeFormat())
            : inspector.paid,
        trailingColor: inst.outstandingAmount > 0
            ? visual.foreground
            : financial.settled.onContainer,
      ),
      // No "deposited on" row when there is no date — the status chip already says so.
      if (depositedOn != null)
        _MetricRow(
          label: inspector.depositedOn,
          value: depositedOn.toAppFormat(),
          trailing: inst.poBatchId != null ? inspector.poVisitBadge : null,
        ),
    ];

    final actions = <Widget>[
      if (canCollect)
        AppButton(
          label: passbook.collect,
          icon: HugeIcons.strokeRoundedCoins01,
          size: AppButtonSize.medium,
          expand: true,
          onPressed: isBusy ? null : onCollect,
        ),
      if (canAbsorbFee)
        AppButton.tonal(
          label: inspector.absorbRemainingFee(
            amount: inst.absorbableFee.toRupeeFormat(),
          ),
          icon: HugeIcons.strokeRoundedWallet02,
          expand: true,
          onPressed: isBusy ? null : () => _absorbRemainingFee(context, ref),
        ),
      if (canClearAbsorbed)
        AppButton.text(
          label: inspector.clearAbsorbedFee,
          icon: HugeIcons.strokeRoundedArrowTurnBackward,
          expand: true,
          onPressed: isBusy ? null : () => _clearAbsorbedFee(context, ref),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title and status share a line when they fit; the track drops below otherwise.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppDimensions.paddingSm,
          runSpacing: AppDimensions.paddingXs,
          children: [
            Text(
              inspector.monthTitle(
                month: inst.installmentNo.toString(),
                date: inst.dueDate.toAppFormat(),
              ),
              style: AppTypography.emphasizedOf(context).titleLarge,
            ),
            RDHubStageCapsule(track: inst.stepTrackAt(now)),
          ],
        ),
        AppSpacings.gapLg,
        AppGroup(children: metricRows),
        if (showCollectHint) ...[
          AppSpacings.gapSm,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
            ),
            child: Text(
              inspector.collectHint(month: nextDueNo.toString()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        for (final (i, action) in actions.indexed) ...[
          if (i == 0) AppSpacings.gapLg else AppSpacings.gapSm,
          action,
        ],
      ],
    );
  }
}

/// One money row of the inspector: what the figure is, the figure itself in an emphasized
/// role, and a short note at the end of the line.
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;
  final Color? valueColor;
  final Color? trailingColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacings.gapXxs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Figures shrink to the room they have; they never wrap or truncate.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: emphasized.titleMedium?.copyWith(
                      color: valueColor ?? scheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                AppSpacings.gapSm,
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      style: emphasized.labelLarge?.copyWith(
                        color: trailingColor ?? scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
      child: AppGroup(
        children: [
          for (var i = 0; i < _rows; i++)
            _MetricRow(
              label: inspector.installment,
              value: inspector.depositedOn,
              trailing: inspector.paid,
            ),
        ],
      ),
    );
  }
}
