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
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// A one-tap amount suggestion shown as a chip above the amount field.
typedef RDQuickAmount = ({String label, double amount});

/// One month whose customer-paid amount changes between the baseline projection and the
/// live preview.
typedef RDPreviewMonthDelta = ({RDInstallment before, RDInstallment after});

/// Everything the payment sheets need. Produced by [usePaymentDraft]; the sheets are
/// pure layouts over this object.
///
/// A payment is just money: amount + mode + date. The projector decides which months it
/// fills (sequentially, earliest open month first), so there is nothing to split.
class PaymentDraftState {
  const PaymentDraftState({
    required this.rdId,
    required this.existing,
    required this.amountController,
    required this.paidDate,
    required this.paymentMode,
    required this.absorbFeeChecked,
    required this.facts,
    required this.baseline,
    required this.preview,
    required this.previewDelta,
    required this.previewTransactionId,
    required this.amount,
    required this.validationError,
    required this.quickAmounts,
    required this.absorbableFee,
    required this.absorbableInstallmentNo,
    required this.isSubmitting,
    required this.isDirty,
    required this.firstDate,
    required this.lastDate,
    required this.applyQuickAmount,
    required this.submit,
  });

  final String rdId;
  final RDTransaction? existing;

  final TextEditingController amountController;
  final ValueNotifier<DateTime> paidDate;
  final ValueNotifier<RDPaymentMode> paymentMode;

  /// "Absorb remaining fee from pocket" checkbox (only meaningful when [absorbableFee] > 0).
  final ValueNotifier<bool> absorbFeeChecked;

  final AsyncValue<RDLedgerFacts> facts;

  /// Ledger as it stands without this draft (in edit mode: without the existing tx).
  final RDLedgerProjection? baseline;

  /// Ledger with the draft applied. Null while facts load or the amount is invalid.
  final RDLedgerProjection? preview;
  final List<RDPreviewMonthDelta> previewDelta;

  /// Key into `preview.allocationsByTransaction` for the draft transaction.
  final String previewTransactionId;

  /// Parsed amount (0 when the field is empty or unparsable).
  final double amount;
  final String? validationError;
  final List<RDQuickAmount> quickAmounts;

  /// After this draft, the remaining balance on the earliest open month **if** it is no
  /// larger than that month's customer fee — i.e. what the agent could absorb to make the
  /// month whole. `0` when not applicable.
  final double absorbableFee;
  final int? absorbableInstallmentNo;

  final bool isSubmitting;
  final bool isDirty;

  /// Allowed paid-date range: deposit start through today.
  final DateTime firstDate;
  final DateTime lastDate;

  final void Function(RDQuickAmount quick) applyQuickAmount;

  /// Records / updates the payment. When the absorb checkbox is on, also absorbs the fee
  /// after a successful record and returns the combined outcome (first failure wins).
  final Future<PaymentSubmitOutcome> Function() submit;

  bool get isEditing => existing != null;
  bool get canSubmit => !isSubmitting && validationError == null && preview != null;
  bool get canAbsorbFee => !isEditing && absorbableFee > 0 && absorbableInstallmentNo != null;

  /// Whether [quick] matches the current amount (for chip selection).
  bool isQuickAmountSelected(RDQuickAmount quick) => Money.equals(amount, quick.amount);
}

/// Result of [PaymentDraftState.submit]: the payment write and (optionally) the fee
/// absorption that followed it.
typedef PaymentSubmitOutcome = ({
  Result<void, String> payment,
  Result<void, String>? absorption,
  double absorbedAmount,
  int? absorbedInstallmentNo,
});

/// Id of the not-yet-saved draft transaction inside the preview projection.
const String rdDraftPreviewTransactionId = '__draft_preview__';
const int _maxQuickMonths = 3;

String _formatAmount(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

double? _parseAmount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

/// Owns all state and derived values for the collect/edit payment sheets.
///
/// Reads facts via `rdLedgerFactsProvider` and recomputes a live preview projection with
/// the draft transaction applied, so what the agent sees is exactly what gets recorded.
PaymentDraftState usePaymentDraft(
  WidgetRef ref, {
  required String rdId,
  RDTransaction? existing,
  double? initialAmount,
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
  final paidDate = useState<DateTime>(existing?.paidDate.toDateOnly() ?? today);
  final paymentMode = useState<RDPaymentMode>(existing?.paymentMode ?? RDPaymentMode.cash);
  final absorbFeeChecked = useState<bool>(false);

  useListenable(amountController);

  final amountInput = _parseAmount(amountController.text);
  final amount = amountInput ?? 0.0;

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
  );
  final previewTxId = existing?.id ?? rdDraftPreviewTransactionId;
  final draftTx = draft.toTransaction(id: previewTxId);

  // --- Validation -----------------------------------------------------------------------
  final ledger = t.recurringDeposits.ledger;
  final String? validationError;
  if (amountController.text.trim().isEmpty) {
    validationError = ledger.amountRequired;
  } else if (amountInput == null || amountInput <= 0) {
    validationError = ledger.enterValidAmount;
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
        if (!Money.equals(before.customerPaidAmount, after.customerPaidAmount)) {
          deltas.add((before: before, after: after));
        }
      }
      return List.unmodifiable(deltas);
    },
    [baseline, preview],
  );

  // --- Absorbable fee ---------------------------------------------------------------------
  // After the draft, if the earliest open month is partially paid and what is left is no
  // more than its customer fee, the agent may cover that remainder from pocket.
  final ({double amount, int? installmentNo}) absorbable = useMemoized(
    () {
      if (preview == null) return (amount: 0.0, installmentNo: null);
      final next = preview.nextDue;
      if (next == null || !next.isPartiallyPaid) return (amount: 0.0, installmentNo: null);
      final remaining = next.outstandingAmount;
      if (Money.toPaise(remaining) <= 0 ||
          Money.toPaise(remaining) > Money.toPaise(next.customerFeeDue)) {
        return (amount: 0.0, installmentNo: null);
      }
      return (amount: remaining, installmentNo: next.installmentNo);
    },
    [preview],
  );

  // --- Quick amounts --------------------------------------------------------------------
  final quickAmounts = useMemoized<List<RDQuickAmount>>(
    () {
      if (baseline == null) return const [];
      final candidates = <RDQuickAmount>[];
      final owed = baseline.summary.owedByCustomer;
      if (owed > 0) {
        candidates.add((label: ledger.chips.dueNow(amount: owed.toRupeeFormat()), amount: owed));
      }
      final open = baseline.customerPending;
      var running = 0.0;
      for (var n = 1; n <= _maxQuickMonths && n <= open.length; n++) {
        running += open[n - 1].outstandingAmount;
        candidates.add((
          label: ledger.chips.months(n: n, amount: running.toRupeeFormat()),
          amount: running,
        ));
      }
      final seen = <int>{};
      return List.unmodifiable([
        for (final c in candidates)
          if (c.amount > 0 && seen.add(Money.toPaise(c.amount))) c,
      ]);
    },
    [baseline],
  );

  // --- Dirty tracking (edit mode) --------------------------------------------------------
  final isDirty = existing != null &&
      (!Money.equals(existing.amount, amount) ||
          existing.paidDate.toDateOnly() != paidDate.value ||
          existing.paymentMode != paymentMode.value);

  // --- Date limits ----------------------------------------------------------------------
  final startDate = factsValue?.deposit.startDate.toDateOnly();
  final firstDate = startDate != null && !startDate.isAfter(today) ? startDate : today;

  // --- Actions --------------------------------------------------------------------------
  void applyQuickAmount(RDQuickAmount quick) {
    amountController.text = _formatAmount(quick.amount);
  }

  Future<PaymentSubmitOutcome> submit() async {
    PaymentSubmitOutcome only(Result<void, String> payment) =>
        (payment: payment, absorption: null, absorbedAmount: 0.0, absorbedInstallmentNo: null);

    if (validationError != null) return only(Failure(validationError));
    final notifier = ref.read(rDLedgerControllerProvider.notifier);

    if (existing != null) {
      final updated = existing.copyWith(
        amount: amount,
        paidDate: paidDate.value,
        paymentMode: paymentMode.value,
        updatedAt: ref.read(clockProvider)(),
      );
      return only(await notifier.updatePayment(updated));
    }

    final payment = await notifier.recordPayment(draft);
    final absorbNo = absorbable.installmentNo;
    final shouldAbsorb =
        payment is Success<void, String> && absorbFeeChecked.value && absorbNo != null;
    if (!shouldAbsorb) return only(payment);

    final absorption = await notifier.absorbFee(
      rdId: rdId,
      installmentNo: absorbNo,
      amount: absorbable.amount,
    );
    return (
      payment: payment,
      absorption: absorption,
      absorbedAmount: absorbable.amount,
      absorbedInstallmentNo: absorbNo,
    );
  }

  return PaymentDraftState(
    rdId: rdId,
    existing: existing,
    amountController: amountController,
    paidDate: paidDate,
    paymentMode: paymentMode,
    absorbFeeChecked: absorbFeeChecked,
    facts: facts,
    baseline: baseline,
    preview: preview,
    previewDelta: previewDelta,
    previewTransactionId: previewTxId,
    amount: amount,
    validationError: validationError,
    quickAmounts: quickAmounts,
    absorbableFee: absorbable.amount,
    absorbableInstallmentNo: absorbable.installmentNo,
    isSubmitting: isSubmitting,
    isDirty: isDirty,
    firstDate: firstDate,
    lastDate: today,
    applyQuickAmount: applyQuickAmount,
    submit: submit,
  );
}
