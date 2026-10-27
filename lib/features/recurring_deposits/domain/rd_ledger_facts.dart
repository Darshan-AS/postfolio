import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_waiver_model.dart';
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
    @Default(<RDFeeWaiver>[]) List<RDFeeWaiver> waivers,
  }) = _RDLedgerFacts;

  /// Monotonic token used to detect a stale cached summary.
  int get version =>
      transactions.length * 1000003 + poDeposits.length * 1009 + waivers.length;

  bool get hasTransactions => transactions.isNotEmpty;

  /// Any PO deposit recorded after onboarding (baseline months are implicit, never rows).
  bool get hasPostOnboardingPoDeposits => poDeposits
      .any((d) => d.installmentNo > deposit.initialPaidInstallments);

  /// Financial terms (amount, start date, tenure) are frozen once the ledger has activity.
  bool get isFinancialTermsLocked => hasTransactions || hasPostOnboardingPoDeposits;
}
