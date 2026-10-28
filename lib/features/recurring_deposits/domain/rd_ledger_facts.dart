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

  /// Financial terms (amount, start date, tenure, baseline) freeze once the ledger has activity.
  bool get isFinancialTermsLocked => hasTransactions || hasPoDeposits;

  /// PO deposit events in the order the Post Office applied them.
  List<RDPoDeposit> get poDepositsInOrder => [...poDeposits]..sort(_poOrder);

  /// The only PO event that may be undone.
  RDPoDeposit? get latestPoDeposit =>
      poDeposits.isEmpty ? null : poDepositsInOrder.last;

  static int _poOrder(RDPoDeposit a, RDPoDeposit b) {
    final byDay = a.depositedOn.compareTo(b.depositedOn);
    if (byDay != 0) return byDay;
    if (a.createdAt != null && b.createdAt != null) {
      final byCreated = a.createdAt!.compareTo(b.createdAt!);
      if (byCreated != 0) return byCreated;
    }
    return a.id.compareTo(b.id);
  }
}
