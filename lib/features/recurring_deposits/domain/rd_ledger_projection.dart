import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

part 'rd_ledger_projection.freezed.dart';

/// Projected metadata for one Post Office deposit visit: the installment range it
/// covered sequentially, how many covered months are still owed from the agent's
/// pocket, and whether it is the most recent visit (eligible for undo).
typedef RDPoVisitEntry = ({
  RDPoDeposit deposit,
  int startInstallmentNo,
  int endInstallmentNo,
  int unpaidFromPocketCount,
  bool isLatest,
});

/// How much of one customer payment went to one month.
/// `installmentNo == 0` means "repaid the opening receivable"; a slice with
/// `isCredit` is money left over after every month was covered.
@freezed
sealed class RDAllocationSlice with _$RDAllocationSlice {
  const RDAllocationSlice._();

  const factory RDAllocationSlice({
    required int installmentNo,
    required double amount,
    @Default(false) bool isCredit,
  }) = _RDAllocationSlice;

  bool get isOpeningReceivable => installmentNo == 0 && !isCredit;
}

/// What the next PO visit can carry for this account.
@freezed
sealed class RDPoReadiness with _$RDPoReadiness {
  const RDPoReadiness._();

  const factory RDPoReadiness({
    /// Months collected in full and not yet deposited (contiguous).
    @Default(0) int readyCount,

    /// Sum of those months' due amounts (installment + fee) at the given deposit date.
    @Default(0.0) double readyAmount,
    @Default(0.0) double readyFee,

    /// The first month that is not yet deposited, if any.
    int? nextInstallmentNo,

    /// Whether the next undeposited month is only partially collected.
    @Default(0.0) double partialShortfall,
  }) = _RDPoReadiness;

  bool get hasReady => readyCount > 0;

  /// The month right after the ready block — the first one the agent could pay from
  /// pocket in the same PO visit. `null` when every month is already deposited.
  int? get nextFromPocketInstallmentNo =>
      nextInstallmentNo == null ? null : nextInstallmentNo! + readyCount;
}

/// Immutable output of `RDLedgerProjector.project` — everything the UI needs for one RD.
@freezed
sealed class RDLedgerProjection with _$RDLedgerProjection {
  const RDLedgerProjection._();

  const factory RDLedgerProjection({
    required DateTime asOf,
    required List<RDInstallment> installments,
    required Map<String, List<RDAllocationSlice>> allocationsByTransaction,
    required RDLedgerSummary summary,
    required RDPoReadiness poReadiness,
    @Default(<String>[]) List<String> warnings,
  }) = _RDLedgerProjection;

  RDInstallment? byNo(int installmentNo) =>
      installmentNo >= 1 && installmentNo <= installments.length
      ? installments[installmentNo - 1]
      : null;

  /// First month the customer still owes on, or null when fully paid.
  RDInstallment? get nextDue =>
      summary.nextDueNo == null ? null : byNo(summary.nextDueNo!);

  double get customerCredit => summary.customerCredit;

  List<RDInstallment> get readyForPo =>
      installments.where((i) => i.isReadyForPo).toList(growable: false);

  List<RDInstallment> get customerPending => installments
      .where((i) => !i.isCustomerSettled && !i.isOpeningBaseline)
      .toList(growable: false);

  /// Months past due that the customer has not settled.
  List<RDInstallment> get arrears => installments
      .where(
        (i) =>
            !i.isOpeningBaseline &&
            !i.isCustomerSettled &&
            i.dueDate.isBefore(asOf),
      )
      .toList(growable: false);

  double get totalCollected => installments.fold(
    0.0,
    (s, i) => s + (i.isOpeningBaseline ? 0 : i.customerPaidAmount),
  );

  /// Amount the **Collect** sheet should prefill: everything owed (opening receivable,
  /// paid-from-pocket months, arrears); when nothing is owed yet, the next month's outstanding.
  double? get collectPrefillAmount => summary.owedByCustomer > 0
      ? summary.owedByCustomer
      : nextDue?.outstandingAmount;

  /// The month after the ready block, when the customer has not covered it — i.e. the
  /// month the agent may deposit from pocket in the next PO visit.
  RDInstallment? get nextFromPocketInstallment {
    final no = poReadiness.nextFromPocketInstallmentNo;
    final candidate = no == null ? null : byNo(no);
    return candidate != null && !candidate.isCustomerSettled ? candidate : null;
  }

  bool get canDepositFromPocket => nextFromPocketInstallment != null;

  /// Projects [poDeposits] into display entries ordered newest-first, mapping each
  /// sequential visit to the exact installment range `[startInstallmentNo..endInstallmentNo]`
  /// after opening-baseline months and counting covered months still owed from pocket.
  List<RDPoVisitEntry> poVisitEntries(List<RDPoDeposit> poDeposits) {
    if (poDeposits.isEmpty) return const <RDPoVisitEntry>[];
    final ordered = [...poDeposits]..sort(RDLedgerFacts.comparePoDeposits);

    var depositedThrough = installments
        .where((i) => i.isOpeningBaseline)
        .length;
    final entries = <RDPoVisitEntry>[];
    for (var i = 0; i < ordered.length; i++) {
      final ev = ordered[i];
      final remaining = installments.length - depositedThrough;
      if (remaining <= 0 || ev.installmentCount <= 0) continue;
      final coveredCount = ev.installmentCount > remaining
          ? remaining
          : ev.installmentCount;

      final start = depositedThrough + 1;
      final end = depositedThrough + coveredCount;
      depositedThrough = end;

      var unpaidFromPocketCount = 0;
      for (var no = start; no <= end; no++) {
        final inst = byNo(no);
        if (inst != null && inst.isPaidFromPocket) {
          unpaidFromPocketCount++;
        }
      }

      entries.add((
        deposit: ev,
        startInstallmentNo: start,
        endInstallmentNo: end,
        unpaidFromPocketCount: unpaidFromPocketCount,
        isLatest: i == ordered.length - 1,
      ));
    }

    return entries.reversed.toList(growable: false);
  }

  /// Groups payments by calendar month, newest month (and newest payment) first.
  static List<({DateTime month, List<RDTransaction> items})>
  groupTransactionsByMonth(List<RDTransaction> transactions) {
    final sorted = [...transactions]
      ..sort((a, b) => b.paidDate.compareTo(a.paidDate));
    final groups = <({DateTime month, List<RDTransaction> items})>[];
    for (final tx in sorted) {
      final month = DateTime(tx.paidDate.year, tx.paidDate.month);
      if (groups.isEmpty || groups.last.month != month) {
        groups.add((month: month, items: <RDTransaction>[]));
      }
      groups.last.items.add(tx);
    }
    return List.unmodifiable(groups);
  }
}
