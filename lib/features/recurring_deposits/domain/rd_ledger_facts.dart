import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'rd_ledger_facts.freezed.dart';

/// Everything the ledger knows for one RD — the complete input to `RDLedgerProjector`.
///
/// Facts are the only persisted ledger data. If a field could be recomputed from the others
/// it does not belong here.
@freezed
sealed class RDLedgerFacts with _$RDLedgerFacts {
  const RDLedgerFacts._();

  const factory RDLedgerFacts({
    required RecurringDeposit deposit,
    @Default(<RDTransaction>[]) List<RDTransaction> transactions,
    @Default(<RDPoDeposit>[]) List<RDPoDeposit> poDeposits,
    @Default(<RDFeeAbsorption>[]) List<RDFeeAbsorption> absorptions,
  }) = _RDLedgerFacts;

  /// Monotonic token used to detect a stale cached summary.
  int get version =>
      transactions.length * 1000003 + poDeposits.length * 1009 + absorptions.length;

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasPoDeposits => poDeposits.isNotEmpty;
  bool get hasFeeAbsorptions => absorptions.isNotEmpty;

  /// Financial terms (amount, start date, tenure, baseline) freeze once the ledger has activity.
  bool get isFinancialTermsLocked =>
      hasTransactions || hasPoDeposits || hasFeeAbsorptions;

  /// PO deposit events in the order the Post Office applied them.
  List<RDPoDeposit> get poDepositsInOrder => [...poDeposits]..sort(comparePoDeposits);

  /// The only PO event that may be undone.
  RDPoDeposit? get latestPoDeposit =>
      poDeposits.isEmpty ? null : poDepositsInOrder.last;

  static int comparePoDeposits(RDPoDeposit a, RDPoDeposit b) {
    final byDay = a.depositedOn.compareTo(b.depositedOn);
    if (byDay != 0) return byDay;
    if (a.createdAt != null && b.createdAt != null) {
      final byCreated = a.createdAt!.compareTo(b.createdAt!);
      if (byCreated != 0) return byCreated;
    }
    return a.id.compareTo(b.id);
  }

  /// Pure-Dart domain invariant: a PO visit (`batchId`) can only be undone if no account
  /// in that batch has a newer Post Office deposit recorded afterward.
  static String? validateBatchUndo({
    required String batchId,
    required Iterable<RDPoDeposit> deposits,
  }) {
    final byRd = <String, List<RDPoDeposit>>{};
    for (final d in deposits) {
      byRd.putIfAbsent(d.rdId, () => []).add(d);
    }
    for (final list in byRd.values) {
      final batchEvents = list.where((d) => d.batchId == batchId).toList();
      if (batchEvents.isEmpty) continue;
      for (final batchEvent in batchEvents) {
        final hasNewer = list.any(
          (other) =>
              other.batchId != batchId &&
              comparePoDeposits(other, batchEvent) > 0,
        );
        if (hasNewer) {
          return 'Cannot undo this visit because a newer Post Office deposit was recorded afterward.';
        }
      }
    }
    return null;
  }
}
