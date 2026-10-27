import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// A one-tap amount suggestion shown as a chip above the amount field.
typedef RDQuickAmount = ({String label, double amount, PaymentSplitMode splitMode});

/// One month whose customer-paid principal or fee changes between the baseline
/// projection and the live preview.
typedef RDPreviewMonthDelta = ({RDInstallment before, RDInstallment after});

/// Everything the payment sheets need. Produced by [usePaymentDraft]; the sheets are
/// pure layouts over this object.
class PaymentDraftState {
  const PaymentDraftState({
    required this.rdId,
    required this.existing,
    required this.amountController,
    required this.installmentComponentController,
    required this.lateFeeComponentController,
    required this.paidDate,
    required this.paymentMode,
    required this.splitMode,
    required this.showAdvancedSplit,
    required this.facts,
    required this.baseline,
    required this.preview,
    required this.previewDelta,
    required this.amount,
    required this.validationError,
    required this.quickAmounts,
    required this.isSubmitting,
    required this.isDirty,
    required this.firstDate,
    required this.lastDate,
    required this.setSplitMode,
    required this.applyQuickAmount,
    required this.submit,
  });

  final String rdId;
  final RDTransaction? existing;

  final TextEditingController amountController;
  final TextEditingController installmentComponentController;
  final TextEditingController lateFeeComponentController;
  final ValueNotifier<DateTime> paidDate;
  final ValueNotifier<RDPaymentMode> paymentMode;
  final ValueNotifier<PaymentSplitMode> splitMode;
  final ValueNotifier<bool> showAdvancedSplit;

  final AsyncValue<RDLedgerFacts> facts;

  /// Ledger as it stands without this draft (in edit mode: without the existing tx).
  final RDLedgerProjection? baseline;

  /// Ledger with the draft applied. Null while facts load or the amount is invalid.
  final RDLedgerProjection? preview;
  final List<RDPreviewMonthDelta> previewDelta;

  /// Parsed amount (0 when the field is empty or unparsable).
  final double amount;
  final String? validationError;
  final List<RDQuickAmount> quickAmounts;
  final bool isSubmitting;
  final bool isDirty;

  /// Allowed paid-date range: deposit start through today.
  final DateTime firstDate;
  final DateTime lastDate;

  final void Function(PaymentSplitMode mode) setSplitMode;
  final void Function(RDQuickAmount quick) applyQuickAmount;
  final Future<Result<void, String>> Function() submit;

  bool get isEditing => existing != null;
  bool get canSubmit => !isSubmitting && validationError == null && preview != null;

  /// Whether [quick] matches the current amount and split mode (for chip selection).
  bool isQuickAmountSelected(RDQuickAmount quick) =>
      Money.equals(amount, quick.amount) && splitMode.value == quick.splitMode;
}

const String _previewTxId = '__draft_preview__';

String _formatAmount(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

double? _parseAmount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

/// Owns all state and derived values for the log/edit payment sheets.
///
/// Reads facts via `rdLedgerFactsProvider` and recomputes a live preview projection with
/// the draft transaction applied, so what the agent sees is exactly what gets recorded.
PaymentDraftState usePaymentDraft(
  WidgetRef ref, {
  required String rdId,
  RDTransaction? existing,
  double? initialAmount,
  PaymentSplitMode? initialSplitMode,
}) {
  final today = ref.watch(clockProvider)().toDateOnly();
  final facts = ref.watch(rdLedgerFactsProvider(rdId));
  final projector = ref.watch(rdLedgerProjectorProvider);
  final isSubmitting = ref.watch(rDLedgerControllerProvider).isLoading;

  // --- Ephemeral state ------------------------------------------------------------------
  final amountController = useTextEditingController(
    text: existing != null
        ? _formatAmount(existing.amount)
        : (initialAmount != null && initialAmount > 0 ? _formatAmount(initialAmount) : ''),
  );
  final installmentComponentController = useTextEditingController(
    text: existing != null && existing.splitMode == PaymentSplitMode.custom
        ? _formatAmount(existing.installmentAmount)
        : '',
  );
  final lateFeeComponentController = useTextEditingController(
    text: existing != null && existing.splitMode == PaymentSplitMode.custom
        ? _formatAmount(existing.lateFeeAmount)
        : '',
  );
  final paidDate = useState<DateTime>(existing?.paidDate.toDateOnly() ?? today);
  final paymentMode = useState<RDPaymentMode>(existing?.paymentMode ?? RDPaymentMode.cash);
  final splitMode = useState<PaymentSplitMode>(
    existing?.splitMode ?? initialSplitMode ?? PaymentSplitMode.includeFees,
  );
  final showAdvancedSplit = useState<bool>(false);

  useListenable(amountController);
  useListenable(installmentComponentController);
  useListenable(lateFeeComponentController);

  final amountInput = _parseAmount(amountController.text);
  final amount = amountInput ?? 0.0;
  final installmentComponent = _parseAmount(installmentComponentController.text) ?? 0.0;
  final lateFeeComponent = _parseAmount(lateFeeComponentController.text) ?? 0.0;

  // --- Projections ----------------------------------------------------------------------
  final factsValue = facts.value;

  final factsWithoutExisting = useMemoized<RDLedgerFacts?>(
    () {
      if (factsValue == null) return null;
      if (existing == null) return factsValue;
      return factsValue.copyWith(
        transactions: factsValue.transactions.where((t) => t.id != existing.id).toList(),
      );
    },
    [factsValue, existing?.id],
  );

  final baseline = useMemoized<RDLedgerProjection?>(
    () => factsWithoutExisting == null
        ? null
        : projector.project(factsWithoutExisting, asOf: today),
    [factsWithoutExisting, projector, today],
  );

  final RDPaymentDraft draft = (
    rdId: rdId,
    transactionId: existing?.id,
    amount: amount,
    paidDate: paidDate.value,
    paymentMode: paymentMode.value,
    splitMode: splitMode.value,
    installmentComponent: installmentComponent,
    lateFeeComponent: lateFeeComponent,
  );

  final draftTx = draft.toTransaction(id: existing?.id ?? _previewTxId);

  // --- Validation -----------------------------------------------------------------------
  final ledger = t.recurringDeposits.ledger;
  final String? validationError;
  if (amountController.text.trim().isEmpty) {
    validationError = ledger.amountRequired;
  } else if (amountInput == null || amountInput <= 0) {
    validationError = ledger.enterValidAmount;
  } else if (splitMode.value == PaymentSplitMode.custom &&
      (installmentComponent < 0 ||
          lateFeeComponent < 0 ||
          RDLedgerProjector.validateSplit(draftTx) != null)) {
    validationError = ledger.customSplitMismatch(
      inst: installmentComponent.toRupeeFormat(),
      fee: lateFeeComponent.toRupeeFormat(),
      total: amount.toRupeeFormat(),
    );
  } else {
    validationError = null;
  }

  final preview = useMemoized<RDLedgerProjection?>(
    () {
      if (factsWithoutExisting == null || validationError != null) return null;
      return projector.project(
        factsWithoutExisting.copyWith(
          transactions: [...factsWithoutExisting.transactions, draftTx],
        ),
        asOf: today,
      );
    },
    [
      factsWithoutExisting,
      projector,
      today,
      validationError,
      amount,
      paidDate.value,
      splitMode.value,
      installmentComponent,
      lateFeeComponent,
      paymentMode.value,
    ],
  );

  final previewDelta = useMemoized<List<RDPreviewMonthDelta>>(
    () {
      if (baseline == null || preview == null) return const [];
      final deltas = <RDPreviewMonthDelta>[];
      final count = baseline.installments.length < preview.installments.length
          ? baseline.installments.length
          : preview.installments.length;
      for (var i = 0; i < count; i++) {
        final before = baseline.installments[i];
        final after = preview.installments[i];
        if (!Money.equals(before.customerPaidAmount, after.customerPaidAmount) ||
            !Money.equals(before.paidLateFee, after.paidLateFee)) {
          deltas.add((before: before, after: after));
        }
      }
      return List.unmodifiable(deltas);
    },
    [baseline, preview],
  );

  // --- Quick amounts --------------------------------------------------------------------
  final quickAmounts = useMemoized<List<RDQuickAmount>>(
    () {
      if (baseline == null || factsValue == null) return const [];
      final installment = factsValue.deposit.installmentAmount;
      final arrears = baseline.totalArrears;
      final fees = baseline.installments
          .fold<double>(0.0, (sum, i) => sum + i.outstandingLateFeeAt(today));
      final candidates = <RDQuickAmount>[
        (
          label: ledger.chips.oneInstallment(amount: installment.toRupeeFormat()),
          amount: installment,
          splitMode: PaymentSplitMode.installmentsOnly,
        ),
        for (final n in const [2, 3])
          (
            label: ledger.chips.installments(
              count: n.toString(),
              amount: (installment * n).toRupeeFormat(),
            ),
            amount: installment * n,
            splitMode: PaymentSplitMode.installmentsOnly,
          ),
        (
          label: ledger.chips.clearAllArrears(amount: arrears.toRupeeFormat()),
          amount: arrears,
          splitMode: PaymentSplitMode.includeFees,
        ),
        (
          label: ledger.chips.feesOnly(amount: fees.toRupeeFormat()),
          amount: fees,
          splitMode: PaymentSplitMode.feesOnly,
        ),
      ];
      final seen = <int>{};
      return List.unmodifiable([
        for (final c in candidates)
          if (c.amount > 0 && seen.add(Money.toPaise(c.amount))) c,
      ]);
    },
    [baseline, factsValue, today],
  );

  // --- Dirty tracking (edit mode) --------------------------------------------------------
  final bool isDirty;
  if (existing == null) {
    isDirty = false;
  } else {
    final sameComponents = splitMode.value != PaymentSplitMode.custom ||
        (Money.equals(existing.installmentAmount, installmentComponent) &&
            Money.equals(existing.lateFeeAmount, lateFeeComponent));
    isDirty = !Money.equals(existing.amount, amount) ||
        existing.paidDate.toDateOnly() != paidDate.value ||
        existing.paymentMode != paymentMode.value ||
        existing.splitMode != splitMode.value ||
        !sameComponents;
  }

  // --- Date limits ----------------------------------------------------------------------
  final startDate = factsValue?.deposit.startDate.toDateOnly();
  final firstDate = startDate != null && !startDate.isAfter(today) ? startDate : today;

  // --- Actions --------------------------------------------------------------------------
  void setSplitMode(PaymentSplitMode mode) {
    if (mode == PaymentSplitMode.custom && splitMode.value != PaymentSplitMode.custom) {
      installmentComponentController.text = _formatAmount(amount);
      lateFeeComponentController.text = '0';
    }
    splitMode.value = mode;
  }

  void applyQuickAmount(RDQuickAmount quick) {
    amountController.text = _formatAmount(quick.amount);
    setSplitMode(quick.splitMode);
  }

  Future<Result<void, String>> submit() async {
    if (validationError != null) return Failure(validationError);
    final notifier = ref.read(rDLedgerControllerProvider.notifier);
    if (existing == null) return notifier.recordPayment(draft);
    final updated = existing.copyWith(
      amount: amount,
      paidDate: paidDate.value,
      paymentMode: paymentMode.value,
      splitMode: splitMode.value,
      installmentAmount: draftTx.installmentAmount,
      lateFeeAmount: draftTx.lateFeeAmount,
      updatedAt: ref.read(clockProvider)(),
    );
    return notifier.updatePayment(updated);
  }

  return PaymentDraftState(
    rdId: rdId,
    existing: existing,
    amountController: amountController,
    installmentComponentController: installmentComponentController,
    lateFeeComponentController: lateFeeComponentController,
    paidDate: paidDate,
    paymentMode: paymentMode,
    splitMode: splitMode,
    showAdvancedSplit: showAdvancedSplit,
    facts: facts,
    baseline: baseline,
    preview: preview,
    previewDelta: previewDelta,
    amount: amount,
    validationError: validationError,
    quickAmounts: quickAmounts,
    isSubmitting: isSubmitting,
    isDirty: isDirty,
    firstDate: firstDate,
    lastDate: today,
    setSplitMode: setSplitMode,
    applyQuickAmount: applyQuickAmount,
    submit: submit,
  );
}
