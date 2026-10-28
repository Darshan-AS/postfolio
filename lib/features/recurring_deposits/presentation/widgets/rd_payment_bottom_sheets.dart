import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_payment_draft.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Single source of truth for the payment-mode glyphs and short labels used across the sheets.
extension RDPaymentModeIcon on RDPaymentMode {
  List<List<dynamic>> get icon => switch (this) {
        RDPaymentMode.cash => HugeIcons.strokeRoundedCoins01,
        RDPaymentMode.upi => HugeIcons.strokeRoundedCreditCard,
        RDPaymentMode.cheque => HugeIcons.strokeRoundedTicket01,
        RDPaymentMode.bankTransfer => HugeIcons.strokeRoundedBank,
      };

  /// One-word label that fits a segmented button next to the glyph.
  String get shortLabel => switch (this) {
        RDPaymentMode.cash => t.recurringDeposits.ledger.paymentModes.cash,
        RDPaymentMode.upi => t.recurringDeposits.ledger.paymentModes.upi,
        RDPaymentMode.cheque => t.recurringDeposits.ledger.paymentModes.cheque,
        RDPaymentMode.bankTransfer => t.recurringDeposits.ledger.paymentModes.bankTransfer,
      };
}

/// Opens the "collect customer payment" sheet. Resolves `true` when a payment was recorded.
Future<bool?> showRDLogPaymentSheet(
  BuildContext context, {
  required String rdId,
  double? initialAmount,
}) =>
    AppAdaptiveSheet.show<bool>(
      context,
      builder: (_) => _PaymentForm(
        rdId: rdId,
        initialAmount: initialAmount,
        hostContext: context,
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
      builder: (_) => _PaymentForm(
        rdId: rdId,
        existing: transaction,
        hostContext: context,
      ),
    );

// --- Form ---------------------------------------------------------------------------------

class _PaymentForm extends HookConsumerWidget {
  const _PaymentForm({
    required this.rdId,
    required this.hostContext,
    this.existing,
    this.initialAmount,
  });

  final String rdId;
  final RDTransaction? existing;
  final double? initialAmount;

  /// The caller's context — still mounted after this sheet pops, so the toast (and its
  /// Undo) outlive the sheet.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = usePaymentDraft(
      ref,
      rdId: rdId,
      existing: existing,
      initialAmount: initialAmount,
    );
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final isEditing = draft.isEditing;
    final deposit = draft.facts.value?.deposit;
    final customer = deposit?.customerName;
    final serial = deposit?.serialNo;

    final title = isEditing
        ? ledger.editPaymentTitle
        : (customer != null && customer.isNotEmpty)
            ? ledger.collectTitle(customer: customer, serial: serial ?? t.common.notProvided)
            : ledger.logPaymentTitle;

    String collectedMessage() {
      final who = customer ?? t.recurringDeposits.depositNotFound;
      final amount = draft.amount.toRupeeFormat();
      final month = draft.firstAllocatedMonth;
      if (month == null) return ledger.collectedNoMonth(amount: amount, customer: who);
      final locale = LocaleSettings.currentLocale.languageTag;
      return ledger.collected(
        amount: amount,
        customer: who,
        month: month.installmentNo.toString(),
        monthName: DateFormat.MMM(locale).format(month.installmentDate),
      );
    }

    Future<void> handleSubmit() async {
      // Resolve the toast copy before the write: the preview is derived from facts that
      // change the moment the payment lands.
      final successMessage = isEditing ? ledger.paymentUpdated : collectedMessage();
      final outcome = await draft.submit();
      if (!context.mounted) return;
      if (outcome.payment is Success<void, String>) {
        Navigator.of(context).pop(true);
        if (!hostContext.mounted) return;
        AppFeedback.showResult(
          hostContext,
          outcome.payment,
          successMessage: successMessage,
          undoLabel: isEditing ? null : t.recurringDeposits.monthlyOperations.undo,
          onUndo: isEditing
              ? null
              : () async {
                  final undone = await draft.undo();
                  if (!hostContext.mounted) return;
                  AppFeedback.showResult(
                    hostContext,
                    undone,
                    successMessage: ledger.paymentUndone,
                  );
                },
        );
        final absorption = outcome.absorption;
        if (absorption != null && outcome.absorbedInstallmentNo != null) {
          AppFeedback.showResult(
            hostContext,
            absorption,
            successMessage: ledger.feeAbsorbed(
              amount: outcome.absorbedAmount.toRupeeFormat(),
              month: outcome.absorbedInstallmentNo.toString(),
            ),
          );
        }
        return;
      }
      AppFeedback.showResult(context, outcome.payment, successMessage: successMessage);
    }

    // Edit: confirm when the saved payment was changed. Create: confirm when an amount was
    // typed (differs from the prefill) but not collected yet — a fat-finger dismiss must
    // not lose the entry.
    final hasUnsavedInput = isEditing
        ? draft.isDirty
        : draft.amount > 0 && !Money.equals(draft.amount, initialAmount ?? 0.0);

    Future<void> handlePopAttempt(bool didPop, bool? _) async {
      if (didPop) return;
      final discard = await AppDialogs.confirmAction(
        context,
        title: ledger.discardChangesTitle,
        content: isEditing ? ledger.discardChangesContent : ledger.discardAmountContent,
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
      body = ErrorStateView(
        message: draft.facts.error.toString(),
        onRetry: () => ref.invalidate(rdLedgerFactsProvider(rdId)),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final submitLabel = isEditing
        ? ledger.saveChanges
        : draft.amount > 0
            ? ledger.collectSubmit(amount: draft.amount.toRupeeFormat())
            : ledger.recordPayment;

    return PopScope<bool>(
      canPop: !hasUnsavedInput,
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
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppDimensions.minTapTarget),
              ),
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
              label: Text(submitLabel),
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
          text: ledger.paymentModeValue(mode: draft.paymentMode.value.shortLabel),
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
                  label: Text(mode.shortLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
        AppSpacings.gapLg,
        _PaidDateButton(draft: draft),
        if (draft.canAbsorbFee) ...[
          AppSpacings.gapSm,
          _AbsorbFeeTile(draft: draft),
        ],
        AppSpacings.gapLg,
        RDAllocationPreviewCard(
          amount: draft.amount,
          baseline: draft.baseline,
          preview: draft.preview,
          delta: draft.previewDelta,
          asOf: draft.lastDate,
          transactionId: draft.previewTransactionId,
          isRecalculation: draft.isEditing,
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
      label: Text(ledger.paymentDateValue(date: current.toAppFormat())),
    );
  }
}

/// "Absorb remaining fee ₹X from pocket" — offered only when, after this payment, the
/// earliest open month is short by no more than its default fee.
class _AbsorbFeeTile extends StatelessWidget {
  const _AbsorbFeeTile({required this.draft});

  final PaymentDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    return CheckboxListTile(
      value: draft.absorbFeeChecked.value,
      onChanged: (v) => draft.absorbFeeChecked.value = v ?? false,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        ledger.absorbFee(amount: draft.absorbableFee.toRupeeFormat()),
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        ledger.absorbFeeHint,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      secondary: HugeIcon(
        icon: HugeIcons.strokeRoundedWallet02,
        size: AppDimensions.iconSm,
        color: theme.colorScheme.secondary,
      ),
    );
  }
}

// --- Preview ------------------------------------------------------------------------------

/// Shows how the draft payment lands on the schedule: a one-line summary built from the
/// draft transaction's allocation slices, then every month whose collected amount changes,
/// each with its projected status chip.
class RDAllocationPreviewCard extends StatelessWidget {
  const RDAllocationPreviewCard({
    super.key,
    required this.amount,
    required this.baseline,
    required this.preview,
    required this.delta,
    required this.asOf,
    this.transactionId,
    this.isRecalculation = false,
  });

  final double amount;
  final RDLedgerProjection? baseline;
  final RDLedgerProjection? preview;
  final List<RDPreviewMonthDelta> delta;
  final DateTime asOf;

  /// Key of the draft transaction in `preview.allocationsByTransaction`
  /// (defaults to the unsaved-draft id used by `usePaymentDraft`).
  final String? transactionId;
  final bool isRecalculation;

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
                      strings.credit(amount: previewValue.customerCredit.toRupeeFormat()),
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
    final slices = previewValue
            .allocationsByTransaction[transactionId ?? rdDraftPreviewTransactionId] ??
        const [];
    if (slices.isEmpty) return strings.summaryNoChange;

    final parts = <String>[];
    var credit = 0.0;
    for (final slice in slices) {
      if (slice.isCredit) {
        credit += slice.amount;
      } else if (slice.isOpeningReceivable) {
        parts.add(strings.summaryOpeningPart(amount: slice.amount.toRupeeFormat()));
      } else {
        parts.add(strings.summaryMonthPart(
          month: slice.installmentNo.toString(),
          amount: slice.amount.toRupeeFormat(),
        ));
      }
    }
    if (credit > 0) parts.add(strings.summaryCreditPart(amount: credit.toRupeeFormat()));
    return strings.summaryLine(
      amount: amount.toRupeeFormat(),
      parts: parts.join(strings.summaryPartsSeparator),
      left: credit.toRupeeFormat(),
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
                strings.monthPaid(
                  paid: after.customerPaidAmount.toRupeeFormat(),
                  due: after.dueAmount.toRupeeFormat(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (after.customerFeeDue > 0)
                Text(
                  strings.monthFee(fee: after.customerFeeDue.toRupeeFormat()),
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
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
