import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
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
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_sheet_parts.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_account_identity.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Single source of truth for the payment-mode glyphs and short labels used across the sheets.
extension RDPaymentModeIcon on RDPaymentMode {
  List<List<dynamic>> get icon => switch (this) {
    RDPaymentMode.cash => HugeIcons.strokeRoundedCoins01,
    RDPaymentMode.upi => HugeIcons.strokeRoundedCreditCard,
    RDPaymentMode.cheque => HugeIcons.strokeRoundedTicket01,
    RDPaymentMode.bankTransfer => HugeIcons.strokeRoundedBank,
  };

  /// One-word label that fits a button-group segment next to the glyph.
  String get shortLabel => switch (this) {
    RDPaymentMode.cash => t.recurringDeposits.ledger.paymentModes.cash,
    RDPaymentMode.upi => t.recurringDeposits.ledger.paymentModes.upi,
    RDPaymentMode.cheque => t.recurringDeposits.ledger.paymentModes.cheque,
    RDPaymentMode.bankTransfer =>
      t.recurringDeposits.ledger.paymentModes.bankTransfer,
  };
}

/// Result of the collect customer payment sheet.
enum RDLogPaymentOutcome { saved, dismissed, depositFromPocket }

/// Opens the "collect customer payment" sheet.
Future<RDLogPaymentOutcome?> showRDLogPaymentSheet(
  BuildContext context, {
  required String rdId,
  double? initialAmount,
  bool showDepositFromPocketShortcut = false,
}) => AppAdaptiveSheet.show<RDLogPaymentOutcome>(
  context,
  builder: (_) => _PaymentForm(
    rdId: rdId,
    initialAmount: initialAmount,
    hostContext: context,
    showDepositFromPocketShortcut: showDepositFromPocketShortcut,
  ),
);

/// Opens the "edit customer payment" sheet. Resolves `true` when the payment was updated.
Future<bool?> showRDEditPaymentSheet(
  BuildContext context, {
  required String rdId,
  required RDTransaction transaction,
}) =>
    AppAdaptiveSheet.show<RDLogPaymentOutcome>(
      context,
      builder: (_) =>
          _PaymentForm(rdId: rdId, existing: transaction, hostContext: context),
    ).then(
      (outcome) => switch (outcome) {
        RDLogPaymentOutcome.saved => true,
        RDLogPaymentOutcome.dismissed ||
        RDLogPaymentOutcome.depositFromPocket => false,
        null => null,
      },
    );

// --- Form ---------------------------------------------------------------------------------

class _PaymentForm extends HookConsumerWidget {
  const _PaymentForm({
    required this.rdId,
    required this.hostContext,
    this.existing,
    this.initialAmount,
    this.showDepositFromPocketShortcut = false,
  });

  final String rdId;
  final RDTransaction? existing;
  final double? initialAmount;
  final bool showDepositFromPocketShortcut;

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
    final ledger = t.recurringDeposits.ledger;
    final isEditing = draft.isEditing;
    final deposit = draft.facts.value?.deposit;
    final customer = deposit?.customerName;

    final title = isEditing
        ? ledger.editPaymentTitle
        : (customer != null && customer.isNotEmpty)
        ? ledger.collectTitle(customer: customer)
        : ledger.logPaymentTitle;

    String collectedMessage() {
      final who = customer ?? t.recurringDeposits.depositNotFound;
      final amount = draft.amount.toRupeeFormat();
      final month = draft.firstAllocatedMonth;
      if (month == null) {
        return ledger.collectedNoMonth(amount: amount, customer: who);
      }
      final rawLocale = LocaleSettings.currentLocale.languageTag;
      String locale = 'en_US';
      try {
        if (DateFormat.localeExists(rawLocale)) locale = rawLocale;
      } catch (_) {}
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
      final successMessage = isEditing
          ? ledger.paymentUpdated
          : collectedMessage();
      final outcome = await draft.submit();
      if (!context.mounted) return;
      if (outcome.payment is Success<void, String>) {
        Navigator.of(context).pop(RDLogPaymentOutcome.saved);
        if (!hostContext.mounted) return;
        AppFeedback.showResult(
          hostContext,
          outcome.payment,
          successMessage: successMessage,
          undoLabel: isEditing
              ? null
              : t.recurringDeposits.monthlyOperations.undo,
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
      AppFeedback.showResult(
        context,
        outcome.payment,
        successMessage: successMessage,
      );
    }

    // Edit: confirm when the saved payment was changed. Create: confirm when an amount was
    // typed (differs from the prefill) but not collected yet — a fat-finger dismiss must
    // not lose the entry.
    final hasUnsavedInput = isEditing
        ? draft.isDirty
        : draft.amount > 0 && !Money.equals(draft.amount, initialAmount ?? 0.0);

    Future<void> handlePopAttempt(bool didPop, RDLogPaymentOutcome? _) async {
      if (didPop) return;
      final discard = await AppDialogs.confirmAction(
        context,
        title: ledger.discardChangesTitle,
        content: isEditing
            ? ledger.discardChangesContent
            : ledger.discardAmountContent,
        confirmText: ledger.discard,
      );
      if (discard == true && context.mounted) {
        Navigator.of(context).pop(RDLogPaymentOutcome.dismissed);
      }
    }

    Future<void> handleDepositFromPocketShortcut() async {
      if (hasUnsavedInput) {
        final discard = await AppDialogs.confirmAction(
          context,
          title: ledger.discardChangesTitle,
          content: ledger.discardAmountContent,
          confirmText: ledger.discard,
        );
        if (discard != true || !context.mounted) return;
      }
      Navigator.of(context).pop(RDLogPaymentOutcome.depositFromPocket);
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
        child: Center(child: AppLoadingIndicator()),
      );
    }

    final submitLabel = isEditing
        ? ledger.saveChanges
        : draft.amount > 0
        ? ledger.collectSubmit(amount: draft.amount.toRupeeFormat())
        : ledger.recordPayment;

    return PopScope<RDLogPaymentOutcome>(
      canPop: !hasUnsavedInput,
      onPopInvokedWithResult: handlePopAttempt,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RDSheetHeader(
            title: title,
            subtitle: deposit == null ? null : rdAccountIdentity(deposit),
            onClose: () =>
                Navigator.of(context).maybePop(RDLogPaymentOutcome.dismissed),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
                vertical: AppDimensions.paddingSm,
              ),
              child: body,
            ),
          ),
          RDSheetFooter(
            children: [
              RDSheetPrimaryAction(
                label: submitLabel,
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                isLoading: draft.isSubmitting,
                onPressed: draft.canSubmit ? handleSubmit : null,
              ),
              if (!isEditing && showDepositFromPocketShortcut) ...[
                AppSpacings.gapXs,
                AppButton.text(
                  label: ledger.depositFromPocketShortcut,
                  icon: HugeIcons.strokeRoundedWallet02,
                  size: AppButtonSize.small,
                  expand: true,
                  foregroundColor: AppFinancialColors.of(
                    context,
                  ).receivable.onContainer,
                  onPressed: draft.isSubmitting
                      ? null
                      : handleDepositFromPocketShortcut,
                ),
              ],
            ],
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
    final scheme = Theme.of(context).colorScheme;
    final ledger = t.recurringDeposits.ledger;
    final amountText = draft.amountController.text.trim();
    final amountError =
        amountText.isNotEmpty &&
            draft.validationError == ledger.enterValidAmount
        ? ledger.enterValidAmount
        : null;
    // The amount is the hero of the sheet: the field is set in a headline role.
    final amountStyle = rdSheetLargeType(
      context,
      AppTypography.emphasizedOf(context).headlineMedium,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: draft.amountController,
          autofocus: !draft.hasInitialPrefill,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.done,
          style: amountStyle,
          decoration:
              AppInputDecoration.m3(
                context,
                labelText: ledger.paymentAmount,
                prefixText: t.format.currencySymbol,
                isRequired: true,
                errorText: amountError,
              ).copyWith(
                prefixStyle: amountStyle?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
        ),
        if (draft.quickAmounts.isNotEmpty) ...[
          AppSpacings.gapSm,
          // Suggestions that fill the field: chips, filled while the field holds their
          // amount. Each brings its own touch padding above and below, which spaces the
          // lines when they wrap. At large text a chip fills that padding, so the lines get
          // a gap of their own.
          Wrap(
            spacing: AppDimensions.paddingSm,
            runSpacing: AppDimensions.isLargeText(context)
                ? AppDimensions.paddingSm
                : 0,
            children: [
              for (final quick in draft.quickAmounts)
                ChoiceChip(
                  // As on a button: the label carries an amount, so one that does not
                  // fit shrinks. A chip would cut it.
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(quick.label),
                  ),
                  selected: draft.isQuickAmountSelected(quick),
                  onSelected: (_) => draft.applyQuickAmount(quick),
                ),
            ],
          ),
        ],
        AppSpacings.gapLg,
        // Four segments have no room for a glyph each on a phone, so the caption carries
        // the glyph of the chosen mode.
        RDSheetSectionLabel(
          ledger.paymentModeValue(mode: draft.paymentMode.value.shortLabel),
          icon: draft.paymentMode.value.icon,
        ),
        AppSpacings.gapSm,
        AppButtonGroup<RDPaymentMode>(
          selected: draft.paymentMode.value,
          onChanged: (mode) => draft.paymentMode.value = mode,
          segments: [
            for (final mode in RDPaymentMode.values)
              AppSegment(
                value: mode,
                label: mode.shortLabel,
                tooltip: mode.displayName,
              ),
          ],
        ),
        AppSpacings.gapLg,
        _PaidDateTile(
          draft: draft,
          position: draft.canAbsorbFee
              ? AppGroupPosition.first
              : AppGroupPosition.single,
        ),
        if (draft.canAbsorbFee) ...[
          const SizedBox(height: AppShapes.groupGap),
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

class _PaidDateTile extends StatelessWidget {
  const _PaidDateTile({required this.draft, required this.position});

  final PaymentDraftState draft;
  final AppGroupPosition position;

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

    return RDSheetPickerTile(
      icon: HugeIcons.strokeRoundedCalendar01,
      label: ledger.paymentDateValue(date: current.toAppFormat()),
      onTap: pick,
      position: position,
    );
  }
}

/// "Absorb remaining fee ₹X from pocket" — offered only when, after this payment, the
/// earliest open month is short by no more than its default fee.
///
/// The last row of the group that starts with the payment date.
class _AbsorbFeeTile extends StatelessWidget {
  const _AbsorbFeeTile({required this.draft});

  final PaymentDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    return AppGroupTile(
      position: AppGroupPosition.last,
      // Padding and gap put the checkbox under the date row's icon and the text under its
      // text.
      child: ListTileTheme.merge(
        horizontalTitleGap: AppDimensions.paddingXs,
        child: CheckboxListTile(
          value: draft.absorbFeeChecked.value,
          onChanged: (v) => draft.absorbFeeChecked.value = v ?? false,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsetsDirectional.only(
            start: AppDimensions.paddingSm,
            end: AppDimensions.paddingLg,
          ),
          title: Text(
            ledger.absorbFee(amount: draft.absorbableFee.toRupeeFormat()),
            style: AppTypography.emphasizedOf(context).bodyMedium,
          ),
          subtitle: Text(
            ledger.absorbFeeHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          secondary: HugeIcon(
            icon: HugeIcons.strokeRoundedWallet02,
            size: AppDimensions.iconMd,
            color: theme.colorScheme.secondary,
          ),
        ),
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
    final emphasized = AppTypography.emphasizedOf(context);
    final strings = t.recurringDeposits.ledger.preview;
    final previewValue = preview;

    return RDSheetBlock(
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
                  style: emphasized.titleSmall?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
          AppSpacings.gapSm,
          if (previewValue == null)
            Text(
              isRecalculation ? strings.recalculatedHint : strings.hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text(_summaryLine(previewValue), style: emphasized.bodyMedium),
            if (delta.isNotEmpty) ...[
              AppSpacings.gapMd,
              for (final month in delta) ...[
                _PreviewMonthRow(month: month, asOf: asOf),
                AppSpacings.gapSm,
              ],
            ],
            if (previewValue.customerCredit > 0) ...[
              AppSpacings.gapSm,
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: AppDimensions.iconSm,
                    color: scheme.primary,
                  ),
                  AppSpacings.gapSm,
                  Expanded(
                    child: Text(
                      strings.credit(
                        amount: previewValue.customerCredit.toRupeeFormat(),
                      ),
                      style: emphasized.bodySmall?.copyWith(
                        color: scheme.primary,
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
    final slices =
        previewValue.allocationsByTransaction[transactionId ??
            rdDraftPreviewTransactionId] ??
        const [];
    if (slices.isEmpty) return strings.summaryNoChange;

    final parts = <String>[];
    var credit = 0.0;
    for (final slice in slices) {
      if (slice.isCredit) {
        credit += slice.amount;
      } else if (slice.isOpeningReceivable) {
        parts.add(
          strings.summaryOpeningPart(amount: slice.amount.toRupeeFormat()),
        );
      } else {
        parts.add(
          strings.summaryMonthPart(
            month: slice.installmentNo.toString(),
            amount: slice.amount.toRupeeFormat(),
          ),
        );
      }
    }
    if (credit > 0) {
      parts.add(strings.summaryCreditPart(amount: credit.toRupeeFormat()));
    }
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
    final emphasized = AppTypography.emphasizedOf(context);
    final strings = t.recurringDeposits.ledger.preview;
    final after = month.after;
    final visual = after.displayStatusAt(asOf).visualOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm,
            vertical: AppDimensions.paddingXs,
          ),
          decoration: ShapeDecoration(
            color: visual.background,
            shape: AppShapes.rounded(AppShapes.small),
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
                style: emphasized.labelMedium?.copyWith(
                  color: visual.foreground,
                ),
              ),
            ],
          ),
        ),
        AppSpacings.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.monthPaid(
                  paid: after.customerPaidAmount.toRupeeFormat(),
                  due: after.dueAmount.toRupeeFormat(),
                ),
                style: emphasized.bodyMedium,
              ),
              if (after.customerFeeDue > 0)
                Text(
                  strings.monthFee(fee: after.customerFeeDue.toRupeeFormat()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              Text(
                visual.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: visual.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
