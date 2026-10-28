import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';

/// Everything the "Deposit next N at the Post Office" sheet needs. The sheet is a pure
/// layout over this object; every number comes from the projector.
class DepositDraftState {
  const DepositDraftState({
    required this.rdId,
    required this.facts,
    required this.projection,
    required this.count,
    required this.depositedOn,
    required this.depositedThroughNo,
    required this.readyCount,
    required this.remaining,
    required this.quote,
    required this.fromPocket,
    required this.firstDate,
    required this.lastDate,
    required this.isSubmitting,
    required this.setCount,
    required this.submit,
    required this.undo,
  });

  final String rdId;
  final AsyncValue<RDLedgerFacts> facts;
  final AsyncValue<RDLedgerProjection> projection;

  /// Effective installment count (already clamped to `1..remaining`).
  final int count;
  final ValueNotifier<DateTime> depositedOn;

  /// Last month already at the Post Office (baseline + all events).
  final int depositedThroughNo;

  /// Months collected in full and waiting for the PO.
  final int readyCount;

  /// Months not yet deposited on this account.
  final int remaining;

  /// What the counter will charge for [count] months on [depositedOn].
  final ({double amount, double fee})? quote;

  /// Portion of [quote] the customer has not paid yet — the agent fronts it.
  final double fromPocket;

  final DateTime firstDate;
  final DateTime lastDate;
  final bool isSubmitting;

  final void Function(int value) setCount;
  final Future<Result<void, String>> Function() submit;
  final Future<Result<void, String>> Function() undo;

  bool get isLoaded => facts.hasValue && projection.hasValue;
  bool get isAllDeposited => isLoaded && remaining == 0;
  bool get canSubmit => isLoaded && !isSubmitting && count >= 1 && count <= remaining;
  bool get canDecrement => count > 1;
  bool get canIncrement => count < remaining;
  bool get isFrontingFromPocket => fromPocket > 0;

  int get fromNo => depositedThroughNo + 1;
  int get toNo => depositedThroughNo + count;
}

/// Owns the count / date state of the deposit sheet and derives the live quote.
DepositDraftState useDepositDraft(
  WidgetRef ref, {
  required String rdId,
  int? initialCount,
}) {
  final today = ref.watch(clockProvider)().toDateOnly();
  final facts = ref.watch(rdLedgerFactsProvider(rdId));
  final projection = ref.watch(rdLedgerProjectionProvider(rdId));
  final projector = ref.watch(rdLedgerProjectorProvider);
  final isSubmitting = ref.watch(rDLedgerControllerProvider).isLoading;

  final countInput = useState<int?>(initialCount);
  final depositedOn = useState<DateTime>(today);

  final factsValue = facts.value;
  final projectionValue = projection.value;

  final depositedThroughNo = projectionValue?.summary.depositedThroughNo ?? 0;
  final readyCount = projectionValue?.poReadiness.readyCount ?? 0;
  final totalMonths = factsValue?.deposit.totalMonths ?? 0;
  final remaining = (totalMonths - depositedThroughNo).clamp(0, totalMonths);

  final requested = countInput.value ?? (readyCount > 0 ? readyCount : 1);
  final count = remaining == 0 ? 0 : requested.clamp(1, remaining);

  final quote = useMemoized<({double amount, double fee})?>(
    () {
      if (factsValue == null || count == 0) return null;
      return projector.quoteNextDeposit(
        factsValue,
        count: count,
        depositedOn: depositedOn.value,
      );
    },
    [factsValue, projector, count, depositedOn.value],
  );

  final fromPocket = useMemoized<double>(
    () {
      if (projectionValue == null || count == 0) return 0.0;
      var sum = 0.0;
      for (var no = depositedThroughNo + 1; no <= depositedThroughNo + count; no++) {
        sum += projectionValue.byNo(no)?.outstandingAmount ?? 0.0;
      }
      return sum;
    },
    [projectionValue, depositedThroughNo, count],
  );

  // Date range: never before the last PO visit (sequential ledger), never after today.
  final startDate = factsValue?.deposit.startDate.toDateOnly();
  final lastVisit = factsValue?.latestPoDeposit?.depositedOn.toDateOnly();
  var firstDate = lastVisit ?? startDate ?? today;
  if (firstDate.isAfter(today)) firstDate = today;

  void setCount(int value) => countInput.value = value;

  // Resolved eagerly: the controller is kept alive, so Undo can still run from a snackbar
  // after the sheet itself has been popped and its `ref` disposed.
  final ledger = ref.read(rDLedgerControllerProvider.notifier);

  Future<Result<void, String>> submit() =>
      ledger.depositNextToPo(rdId: rdId, count: count, depositedOn: depositedOn.value);

  Future<Result<void, String>> undo() => ledger.undoLatestPoDeposit(rdId);

  return DepositDraftState(
    rdId: rdId,
    facts: facts,
    projection: projection,
    count: count,
    depositedOn: depositedOn,
    depositedThroughNo: depositedThroughNo,
    readyCount: readyCount,
    remaining: remaining,
    quote: quote,
    fromPocket: fromPocket,
    firstDate: firstDate,
    lastDate: today,
    isSubmitting: isSubmitting,
    setCount: setCount,
    submit: submit,
    undo: undo,
  );
}
