import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
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
}

/// Plans and records a Post Office visit for the accounts currently in the Hub.
///
/// The plan is quoted from each account's summary + the fee rule on the chosen date, so the
/// numbers shown are the numbers the counter will charge. Recording writes one PO event per
/// account under a single `batch_id`, which is what "Undo visit" deletes.
@Riverpod(keepAlive: true)
class RDPoVisitPlanner extends _$RDPoVisitPlanner {
  @override
  RDPoVisitPlan build() {
    final today = ref.watch(clockProvider)().toDateOnly();
    return RDPoVisitPlan(depositedOn: today);
  }

  static const _rules = RDLedgerRules.standard;

  /// (Re)builds the plan from [items] (defaults to every Hub row with ready months, or every
  /// row when [includeUnready] so the agent can choose to front).
  void start({Iterable<RDMonthlyOperationItem>? items, bool includeUnready = false}) {
    final source = items ??
        (ref.read(monthlyOperationItemsProvider).value ?? const <RDMonthlyOperationItem>[]);
    final lines = <RDPoVisitLine>[
      for (final item in source)
        if (item.readyForPoCount > 0 || includeUnready)
          _quote(RDPoVisitLine(
            item: item,
            readyCount: item.readyForPoCount,
            included: item.readyForPoCount > 0,
          )),
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

  /// Writes one PO event per included account under a single batch id.
  /// Returns the batch id so the caller can offer "Undo visit".
  Future<Result<String, String>> record() async {
    final plan = state;
    final batchId = const Uuid().v4();
    final ledger = ref.read(rDLedgerControllerProvider.notifier);
    var done = 0;
    for (final line in plan.included) {
      final r = await ledger.depositNextToPo(
        rdId: line.rdId,
        count: line.count,
        depositedOn: plan.depositedOn,
        batchId: batchId,
      );
      if (r case Failure(:final error)) {
        return Failure(
          done == 0 ? error : '$error (deposited $done of ${plan.accountCount} accounts — undo the visit to roll back)',
        );
      }
      done++;
    }
    return Success(batchId);
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
    var amount = 0;
    var fee = 0;
    var pocket = 0;
    for (var k = 1; k <= line.count && through + k <= n; k++) {
      final no = through + k;
      final due = _rules.dueDateFor(
          deposit.startDate, RDScheduleFactory.installmentDateFor(deposit.startDate, no));
      final f = Money.toPaise(
          _rules.defaultFeeFor(deposit.installmentAmount, _rules.defaultedMonths(due, day)));
      amount += amountP + f;
      fee += f;
      if (k > line.readyCount) {
        // Fronted month: customer money (if any partial) reduces what comes from pocket.
        final inst = summary.installmentFor(deposit, no, day);
        pocket += (amountP + f) - Money.toPaise(inst.customerPaidAmount);
      }
    }
    // Customer money held for the ready months, by mode, from the summary cache.
    final heldCash = Money.toPaise(summary.cashInHandCash);
    final heldDigital = Money.toPaise(summary.cashInHandDigital);
    final readyAmount = amount - pocket;
    final held = heldCash + heldDigital;
    final cashShare = held == 0 ? readyAmount : (readyAmount * heldCash ~/ held);
    return line.copyWith(
      amount: Money.toRupees(amount),
      fee: Money.toRupees(fee),
      fromPocket: Money.toRupees(pocket < 0 ? 0 : pocket),
      cashPortion: Money.toRupees(cashShare),
      digitalPortion: Money.toRupees(readyAmount - cashShare),
    );
  }
}
