import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'rd_po_visit_controller.freezed.dart';
part 'rd_po_visit_controller.g.dart';

/// India Post accepts at most this much **cash** per agent lot; UPI/cheque lots are uncapped.
const double kPoCashLotLimit = 20000.0;

/// One account line of a planned Post Office visit — exactly what the agent keys into the
/// DOP portal: account → number of installments (+ the fee the counter will add).
@freezed
sealed class RDPoVisitLine with _$RDPoVisitLine {
  const RDPoVisitLine._();

  const factory RDPoVisitLine({
    required RDMonthlyOperationItem item,
    /// Collected-but-undeposited months (what the customer has paid for).
    required int readyCount,
    /// Extra months the agent chose to front from pocket (0 or more).
    @Default(0) int frontedCount,
    @Default(true) bool included,
    /// Optional explicit fee charged at the PO counter (e.g. `0` when a holiday extended due date).
    double? feeOverride,
    /// Counter quote for `readyCount + frontedCount` months on the chosen date.
    @Default(0.0) double amount,
    @Default(0.0) double fee,
    /// Portion of [amount] not covered by customer money (customer still owes it).
    @Default(0.0) double fromPocket,
    /// Customer money for the ready months, by mode (from the summary cache).
    @Default(0.0) double cashPortion,
    @Default(0.0) double digitalPortion,
  }) = _RDPoVisitLine;

  int get count => readyCount + frontedCount;
  String get rdId => item.deposit.id;
  bool get canFrontMore =>
      item.summary.depositedThroughNo + count < item.deposit.totalMonths;
}

/// A cash lot (≤ ₹20,000) the agent should create on the portal.
typedef RDPoCashLot = ({int index, List<String> rdIds, double cashAmount});

@freezed
sealed class RDPoVisitPlan with _$RDPoVisitPlan {
  const RDPoVisitPlan._();

  const factory RDPoVisitPlan({
    required DateTime depositedOn,
    @Default(<RDPoVisitLine>[]) List<RDPoVisitLine> lines,
  }) = _RDPoVisitPlan;

  Iterable<RDPoVisitLine> get included => lines.where((l) => l.included && l.count > 0);
  int get accountCount => included.length;
  int get installmentCount => included.fold(0, (s, l) => s + l.count);
  double get totalAmount => Money.round(included.fold(0.0, (s, l) => s + l.amount));
  double get totalFee => Money.round(included.fold(0.0, (s, l) => s + l.fee));
  double get totalFromPocket => Money.round(included.fold(0.0, (s, l) => s + l.fromPocket));
  double get totalCash => Money.round(included.fold(0.0, (s, l) => s + l.cashPortion));
  double get totalDigital => Money.round(included.fold(0.0, (s, l) => s + l.digitalPortion));

  /// Greedy ≤₹20k grouping of the cash portion, in list order (display-only guidance).
  List<RDPoCashLot> get cashLots {
    final lots = <RDPoCashLot>[];
    var current = <String>[];
    var sum = 0;
    final limit = Money.toPaise(kPoCashLotLimit);
    for (final l in included) {
      final c = Money.toPaise(l.cashPortion);
      if (c <= 0) continue;
      if (sum > 0 && sum + c > limit) {
        lots.add((index: lots.length + 1, rdIds: current, cashAmount: Money.toRupees(sum)));
        current = <String>[];
        sum = 0;
      }
      current.add(l.rdId);
      sum += c;
    }
    if (sum > 0) {
      lots.add((index: lots.length + 1, rdIds: current, cashAmount: Money.toRupees(sum)));
    }
    return lots;
  }

  bool get exceedsSingleCashLot => Money.toPaise(totalCash) > Money.toPaise(kPoCashLotLimit);

  /// Earliest date this visit may carry: the Post Office ledger is sequential, so a visit
  /// cannot be dated before any included account's last recorded visit.
  DateTime? get earliestAllowedDate {
    DateTime? latest;
    for (final l in lines) {
      final d = l.item.summary.lastPoVisitOn;
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    return latest;
  }
}

/// Plans and records a Post Office visit for the accounts currently in the Hub.
@Riverpod(keepAlive: true)
class RDPoVisitPlanner extends _$RDPoVisitPlanner {
  @override
  RDPoVisitPlan build() {
    ref.watch(activeSessionKeyProvider);
    final today = ref.watch(currentDateProvider);
    return RDPoVisitPlan(depositedOn: today);
  }

  static const _rules = RDLedgerRules.standard;

  /// (Re)builds the plan from [items]. When [preserveEdits] is true (e.g. toggling
  /// `includeUnready` inside the open sheet), existing user choices (`included`, `frontedCount`,
  /// `feeOverride`) are retained for matching accounts.
  void start({
    Iterable<RDMonthlyOperationItem>? items,
    bool includeUnready = false,
    bool preserveEdits = false,
  }) {
    final source = items ??
        (ref.read(monthlyOperationItemsProvider).value ?? const <RDMonthlyOperationItem>[]);
    final previousByRd = preserveEdits
        ? {for (final l in state.lines) l.rdId: l}
        : const <String, RDPoVisitLine>{};

    final lines = <RDPoVisitLine>[
      for (final item in source)
        if (item.readyForPoCount > 0 || includeUnready)
          _quote(
            () {
              final prev = previousByRd[item.deposit.id];
              return RDPoVisitLine(
                item: item,
                readyCount: item.readyForPoCount,
                frontedCount: prev?.frontedCount ?? 0,
                included: prev?.included ?? (item.readyForPoCount > 0),
                feeOverride: prev?.feeOverride,
              );
            }(),
          ),
    ];
    state = state.copyWith(lines: lines);
  }

  void setDate(DateTime date) {
    final day = date.toDateOnly();
    state = state.copyWith(
      depositedOn: day,
      lines: [for (final l in state.lines) _quote(l, on: day)],
    );
  }

  void toggleIncluded(String rdId) => _update(rdId, (l) => l.copyWith(included: !l.included));

  void setFronted(String rdId, int frontedCount) => _update(
        rdId,
        (l) => _quote(l.copyWith(frontedCount: frontedCount < 0 ? 0 : frontedCount, included: true)),
      );

  void setFeeOverride(String rdId, double? feeOverride) => _update(
        rdId,
        (l) => _quote(
          l.copyWith(
            feeOverride:
                feeOverride == null ? null : (feeOverride < 0 ? 0.0 : Money.round(feeOverride)),
          ),
        ),
      );

  /// Validates every included account upfront and commits the entire PO visit batch atomically.
  Future<Result<String, String>> record() {
    final plan = state;
    final batchId = const Uuid().v4();
    final ledger = ref.read(rDLedgerControllerProvider.notifier);
    return ledger.depositBatchToPo(
      lines: [
        for (final line in plan.included)
          (rdId: line.rdId, count: line.count, feeOverride: line.feeOverride),
      ],
      depositedOn: plan.depositedOn,
      batchId: batchId,
    );
  }

  Future<Result<void, String>> undoVisit(String batchId) =>
      ref.read(rDLedgerControllerProvider.notifier).undoBatch(batchId);

  // --- internals -------------------------------------------------------------------------

  void _update(String rdId, RDPoVisitLine Function(RDPoVisitLine) f) {
    state = state.copyWith(
      lines: [for (final l in state.lines) l.rdId == rdId ? f(l) : l],
    );
  }

  RDPoVisitLine _quote(RDPoVisitLine line, {DateTime? on}) {
    final day = on ?? state.depositedOn;
    final deposit = line.item.deposit;
    final summary = line.item.summary;
    final n = deposit.totalMonths;
    final through = summary.depositedThroughNo;
    final amountP = Money.toPaise(deposit.installmentAmount);

    final coveredCount =
        (through + line.count <= n) ? line.count : (n - through).clamp(0, n);
    final ruleFees = <int>[];
    for (var k = 1; k <= coveredCount; k++) {
      final no = through + k;
      final due = _rules.dueDateFor(
        deposit.startDate,
        RDScheduleFactory.installmentDateFor(deposit.startDate, no),
      );
      ruleFees.add(
        Money.toPaise(
          _rules.defaultFeeFor(deposit.installmentAmount, _rules.defaultedMonths(due, day)),
        ),
      );
    }

    final ruleFeeSum = ruleFees.fold<int>(0, (s, f) => s + f);
    final fee = line.feeOverride != null
        ? Money.toPaise(line.feeOverride!)
        : ruleFeeSum;
    final amount = coveredCount * amountP + fee;

    // Distribute effective counter fee across covered months (matching RDLedgerProjector) so
    // `fromPocket` and `cashPortion` reflect counter fee overrides accurately.
    final monthFees = List<int>.filled(coveredCount, 0);
    if (coveredCount > 0 && fee > 0) {
      if (fee == ruleFeeSum) {
        for (var i = 0; i < coveredCount; i++) {
          monthFees[i] = ruleFees[i];
        }
      } else if (ruleFeeSum == 0) {
        monthFees[0] = fee;
      } else {
        var assigned = 0;
        var lastIdx = 0;
        for (var i = 0; i < coveredCount; i++) {
          if (ruleFees[i] > 0) lastIdx = i;
          final share = fee * ruleFees[i] ~/ ruleFeeSum;
          monthFees[i] = share;
          assigned += share;
        }
        monthFees[lastIdx] += fee - assigned;
      }
    }

    var pocket = 0;
    for (var k = 1; k <= coveredCount; k++) {
      if (k > line.readyCount) {
        final no = through + k;
        final inst = summary.installmentFor(deposit, no, day);
        pocket += (amountP + monthFees[k - 1]) - Money.toPaise(inst.customerPaidAmount);
      }
    }
    if (pocket < 0) pocket = 0;

    final heldCash = Money.toPaise(summary.cashInHandCash);
    final heldDigital = Money.toPaise(summary.cashInHandDigital);
    final readyAmount = (amount - pocket).clamp(0, amount);
    final held = heldCash + heldDigital;
    final cashShare = held == 0 ? readyAmount : (readyAmount * heldCash ~/ held);
    return line.copyWith(
      amount: Money.toRupees(amount),
      fee: Money.toRupees(fee),
      fromPocket: Money.toRupees(pocket),
      cashPortion: Money.toRupees(cashShare),
      digitalPortion: Money.toRupees(readyAmount - cashShare),
    );
  }
}
