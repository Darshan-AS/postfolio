import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_payment_draft.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

export 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart'
    show PaymentSplitMode;

/// Single source of truth for the payment-mode glyphs used across the sheets.
extension RDPaymentModeIcon on RDPaymentMode {
  List<List<dynamic>> get icon => switch (this) {
        RDPaymentMode.cash => HugeIcons.strokeRoundedCoins01,
        RDPaymentMode.upi => HugeIcons.strokeRoundedCreditCard,
        RDPaymentMode.cheque => HugeIcons.strokeRoundedTicket01,
        RDPaymentMode.bankTransfer => HugeIcons.strokeRoundedBank,
      };
}

/// Opens the "log customer payment" sheet. Resolves `true` when a payment was recorded.
Future<bool?> showRDLogPaymentSheet(
  BuildContext context, {
  required String rdId,
  double? initialAmount,
  PaymentSplitMode? initialSplitMode,
}) =>
    AppAdaptiveSheet.show<bool>(
      context,
      builder: (_) => _PaymentForm(
        rdId: rdId,
        initialAmount: initialAmount,
        initialSplitMode: initialSplitMode,
      ),
    );

/// Opens the "edit customer payment" sheet. Resolves `true` when the payment was updated.
Future<bool?> showRDEditPaymentSheet(
  BuildContext context, {
  required String rdId,
  required RDTransaction transaction,
}) =>
    AppAdaptiveSheet.show<bool>(
      context,
      builder: (_) => _PaymentForm(rdId: rdId, existing: transaction),
    );

// --- Form ---------------------------------------------------------------------------------

class _PaymentForm extends HookConsumerWidget {
  const _PaymentForm({
    required this.rdId,
    this.existing,
    this.initialAmount,
    this.initialSplitMode,
  });

  final String rdId;
  final RDTransaction? existing;
  final double? initialAmount;
  final PaymentSplitMode? initialSplitMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = usePaymentDraft(
      ref,
      rdId: rdId,
      existing: existing,
      initialAmount: initialAmount,
      initialSplitMode: initialSplitMode,
    );
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final isEditing = draft.isEditing;

    Future<void> handleSubmit() async {
      final result = await draft.submit();
      if (!context.mounted) return;
      AppFeedback.showResult(
        context,
        result,
        successMessage: isEditing ? ledger.paymentUpdated : ledger.paymentRecorded,
      );
      if (result is Success<void, String>) {
        Navigator.of(context).pop(true);
      }
    }

    Future<void> handlePopAttempt(bool didPop, bool? _) async {
      if (didPop) return;
      final discard = await AppDialogs.confirmAction(
        context,
        title: ledger.discardChangesTitle,
        content: ledger.discardChangesContent,
        confirmText: ledger.discard,
      );
      if (discard == true && context.mounted) {
        Navigator.of(context).pop(false);
      }
    }

    final Widget body;
    if (draft.facts.hasValue) {
      body = _FormBody(draft: draft);
    } else if (draft.facts.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Text(
          draft.facts.error.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        ),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope<bool>(
      canPop: !isEditing || !draft.isDirty,
      onPopInvokedWithResult: handlePopAttempt,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
              AppDimensions.paddingSm,
              AppDimensions.paddingNone,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? ledger.editPaymentTitle : ledger.logPaymentTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.common.close,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: AppDimensions.iconMd,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(false),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingSm,
              ),
              child: body,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
              AppDimensions.paddingLg,
              AppDimensions.paddingLg,
            ),
            child: FilledButton.icon(
              onPressed: draft.canSubmit ? handleSubmit : null,
              icon: draft.isSubmitting
                  ? const SizedBox.square(
                      dimension: AppDimensions.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppDimensions.strokeWidthSm,
                      ),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      size: AppDimensions.iconSm,
                    ),
              label: Text(isEditing ? ledger.saveChanges : ledger.recordPayment),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({required this.draft});

  final PaymentDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final amountText = draft.amountController.text.trim();
    final amountError =
        amountText.isNotEmpty && draft.validationError == ledger.enterValidAmount
            ? ledger.enterValidAmount
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: draft.amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          textInputAction: TextInputAction.done,
          style: theme.textTheme.titleLarge,
          decoration: AppInputDecoration.m3(
            context,
            labelText: ledger.paymentAmount,
            prefixText: t.format.currencySymbol,
            isRequired: true,
            errorText: amountError,
          ),
        ),
        if (draft.quickAmounts.isNotEmpty) ...[
          AppSpacings.gapSm,
          Wrap(
            spacing: AppDimensions.paddingSm,
            runSpacing: AppDimensions.paddingXs,
            children: [
              for (final quick in draft.quickAmounts)
                ChoiceChip(
                  label: Text(quick.label),
                  selected: draft.isQuickAmountSelected(quick),
                  onSelected: (_) => draft.applyQuickAmount(quick),
                ),
            ],
          ),
        ],
        AppSpacings.gapLg,
        _SectionLabel(
          text: '${ledger.paymentMode}${t.format.bulletSeparator}'
              '${draft.paymentMode.value.displayName}',
        ),
        AppSpacings.gapSm,
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<RDPaymentMode>(
            showSelectedIcon: false,
            selected: {draft.paymentMode.value},
            onSelectionChanged: (selection) => draft.paymentMode.value = selection.first,
            segments: [
              for (final mode in RDPaymentMode.values)
                ButtonSegment<RDPaymentMode>(
                  value: mode,
                  tooltip: mode.displayName,
                  icon: HugeIcon(icon: mode.icon, size: AppDimensions.iconSm),
                ),
            ],
          ),
        ),
        AppSpacings.gapLg,
        _PaidDateButton(draft: draft),
        AppSpacings.gapSm,
        _SplitSection(draft: draft),
        AppSpacings.gapLg,
        RDAllocationPreviewCard(
          isRecalculation: draft.isEditing,
          amount: draft.amount,
          baseline: draft.baseline,
          preview: draft.preview,
          delta: draft.previewDelta,
          asOf: draft.lastDate,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PaidDateButton extends StatelessWidget {
  const _PaidDateButton({required this.draft});

  final PaymentDraftState draft;

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    final current = draft.paidDate.value;
    final initial = current.isBefore(draft.firstDate)
        ? draft.firstDate
        : (current.isAfter(draft.lastDate) ? draft.lastDate : current);

    Future<void> pick() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: draft.firstDate,
        lastDate: draft.lastDate,
      );
      if (selected == null || !context.mounted) return;
      draft.paidDate.value = selected;
    }

    return OutlinedButton.icon(
      onPressed: pick,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar01,
        size: AppDimensions.iconSm,
      ),
      label: Text('${ledger.paymentDate}: ${current.toAppFormat()}'),
    );
  }
}

class _SplitSection extends StatelessWidget {
  const _SplitSection({required this.draft});

  final PaymentDraftState draft;

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    final expanded = draft.showAdvancedSplit.value;
    final isCustom = draft.splitMode.value == PaymentSplitMode.custom;
    final showMismatch = isCustom &&
        draft.validationError != null &&
        draft.validationError != ledger.amountRequired &&
        draft.validationError != ledger.enterValidAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => draft.showAdvancedSplit.value = !expanded,
          icon: HugeIcon(
            icon: expanded
                ? HugeIcons.strokeRoundedArrowUp01
                : HugeIcons.strokeRoundedArrowDown01,
            size: AppDimensions.iconSm,
          ),
          label: Text(expanded ? ledger.hideSplit : ledger.adjustSplit),
        ),
        if (expanded) ...[
          _SectionLabel(text: ledger.allocationPriority),
          AppSpacings.gapSm,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<PaymentSplitMode>(
              showSelectedIcon: false,
              selected: {draft.splitMode.value},
              onSelectionChanged: (selection) => draft.setSplitMode(selection.first),
              segments: [
                ButtonSegment(
                  value: PaymentSplitMode.installmentsOnly,
                  label: Text(ledger.splitModes.installmentsOnly),
                  tooltip: ledger.splitModes.installmentsOnlyTooltip,
                ),
                ButtonSegment(
                  value: PaymentSplitMode.includeFees,
                  label: Text(ledger.splitModes.includeFees),
                  tooltip: ledger.splitModes.includeFeesTooltip,
                ),
                ButtonSegment(
                  value: PaymentSplitMode.feesOnly,
                  label: Text(ledger.splitModes.feesOnly),
                  tooltip: ledger.splitModes.feesOnlyTooltip,
                ),
                ButtonSegment(
                  value: PaymentSplitMode.custom,
                  label: Text(ledger.splitModes.custom),
                  tooltip: ledger.splitModes.customTooltip,
                ),
              ],
            ),
          ),
        ],
        if (isCustom) ...[
          AppSpacings.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.installmentComponentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: AppInputDecoration.m3(
                    context,
                    labelText: ledger.toInstallment,
                    prefixText: t.format.currencySymbol,
                  ),
                ),
              ),
              AppSpacings.gapMd,
              Expanded(
                child: TextFormField(
                  controller: draft.lateFeeComponentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: AppInputDecoration.m3(
                    context,
                    labelText: ledger.toDefaultFee,
                    prefixText: t.format.currencySymbol,
                  ),
                ),
              ),
            ],
          ),
          AppSpacings.gapXs,
          _SplitHelperText(
            text: showMismatch
                ? draft.validationError!
                : ledger.customSplitHint(total: draft.amount.toRupeeFormat()),
            isError: showMismatch,
          ),
        ],
      ],
    );
  }
}

class _SplitHelperText extends StatelessWidget {
  const _SplitHelperText({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// --- Preview ------------------------------------------------------------------------------

/// Shows how the draft payment lands on the schedule: a one-line summary, then every month
/// whose collected principal or fee changes, each with its projected status chip.
class RDAllocationPreviewCard extends StatelessWidget {
  const RDAllocationPreviewCard({
    super.key,
    required this.isRecalculation,
    required this.amount,
    required this.baseline,
    required this.preview,
    required this.delta,
    required this.asOf,
  });

  final bool isRecalculation;
  final double amount;
  final RDLedgerProjection? baseline;
  final RDLedgerProjection? preview;
  final List<RDPreviewMonthDelta> delta;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = t.recurringDeposits.ledger.preview;
    final previewValue = preview;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedActivity01,
                size: AppDimensions.iconSm,
                color: scheme.primary,
              ),
              AppSpacings.gapSm,
              Expanded(
                child: Text(
                  isRecalculation ? strings.recalculatedTitle : strings.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacings.gapSm,
          if (previewValue == null)
            Text(
              isRecalculation ? strings.recalculatedHint : strings.hint,
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Text(
              _summaryLine(previewValue),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (delta.isNotEmpty) ...[
              AppSpacings.gapSm,
              for (final month in delta) ...[
                _PreviewMonthRow(month: month, asOf: asOf),
                AppSpacings.gapXs,
              ],
            ],
            if (previewValue.customerCredit > 0) ...[
              AppSpacings.gapSm,
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: AppDimensions.iconXs,
                    color: scheme.primary,
                  ),
                  AppSpacings.gapXs,
                  Expanded(
                    child: Text(
                      strings.advanceCredit(
                        amount: previewValue.customerCredit.toRupeeFormat(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _summaryLine(RDLedgerProjection previewValue) {
    final strings = t.recurringDeposits.ledger.preview;
    if (delta.isEmpty) return strings.summaryNoChange;
    final parts = <String>[];
    var feeDelta = 0.0;
    for (final month in delta) {
      final principal = month.after.customerPaidAmount - month.before.customerPaidAmount;
      if (principal != 0) {
        parts.add(strings.summaryPrincipalPart(
          month: month.after.installmentNo.toString(),
          amount: principal.toRupeeFormat(),
        ));
      }
      feeDelta += month.after.paidLateFee - month.before.paidLateFee;
    }
    if (feeDelta != 0) {
      parts.add(strings.summaryFeePart(amount: feeDelta.toRupeeFormat()));
    }
    final left = previewValue.customerCredit - (baseline?.customerCredit ?? 0.0);
    return strings.summaryLine(
      amount: amount.toRupeeFormat(),
      parts: parts.join(', '),
      left: left.toRupeeFormat(),
    );
  }
}

class _PreviewMonthRow extends StatelessWidget {
  const _PreviewMonthRow({required this.month, required this.asOf});

  final RDPreviewMonthDelta month;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = t.recurringDeposits.ledger.preview;
    final after = month.after;
    final visual = after.displayStatusAt(asOf).visual(scheme);

    final principalText = after.isInstallmentPaid
        ? strings.principalCovered(amount: after.installmentAmount.toRupeeFormat())
        : strings.principalAllocated(
            paid: after.customerPaidAmount.toRupeeFormat(),
            total: after.installmentAmount.toRupeeFormat(),
          );

    final fee = after.dynamicLateFeeAt(asOf);
    final String? feeText;
    final Color feeColor;
    if (after.isLateFeeWaived) {
      feeText = strings.feeWaived;
      feeColor = scheme.secondary;
    } else if (fee <= 0) {
      feeText = null;
      feeColor = scheme.onSurfaceVariant;
    } else if (after.paidLateFee >= fee) {
      feeText = strings.feePaid(amount: fee.toRupeeFormat());
      feeColor = scheme.primary;
    } else if (after.paidLateFee > 0) {
      feeText = strings.feePartial(
        paid: after.paidLateFee.toRupeeFormat(),
        pending: (fee - after.paidLateFee).toRupeeFormat(),
      );
      feeColor = scheme.error;
    } else {
      feeText = strings.feePending(amount: fee.toRupeeFormat());
      feeColor = scheme.error;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              HugeIcon(
                icon: visual.icon,
                size: AppDimensions.iconXs,
                color: visual.foreground,
              ),
              AppSpacings.gapXs,
              Text(
                strings.monthLabel(month: after.installmentNo.toString()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: visual.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        AppSpacings.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                principalText,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (feeText != null)
                Text(
                  feeText,
                  style: theme.textTheme.bodySmall?.copyWith(color: feeColor),
                ),
              Text(
                visual.label,
                style: theme.textTheme.labelSmall?.copyWith(color: visual.foreground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
