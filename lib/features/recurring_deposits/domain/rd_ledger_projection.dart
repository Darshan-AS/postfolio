import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_payment_allocation_model.dart';

part 'rd_ledger_projection.freezed.dart';

/// Immutable output of `RDLedgerProjector.project` — everything the UI needs for one RD,
/// computed once from facts.
@freezed
sealed class RDLedgerProjection with _$RDLedgerProjection {
  const RDLedgerProjection._();

  const factory RDLedgerProjection({
    required DateTime asOf,
    required List<RDInstallment> installments,
    required Map<String, List<RDPaymentAllocation>> allocationsByTransaction,
    required double customerCredit,
    required RDLedgerSummary summary,
    @Default(<String>[]) List<String> warnings,
  }) = _RDLedgerProjection;

  RDInstallment? byNo(int installmentNo) =>
      installmentNo >= 1 && installmentNo <= installments.length
          ? installments[installmentNo - 1]
          : null;

  /// First month that still owes principal or fee, or null when fully settled.
  RDInstallment? get nextDue =>
      summary.nextDueNo == null ? null : byNo(summary.nextDueNo!);

  /// Months whose principal is collected but not yet deposited at the PO.
  List<RDInstallment> get readyForPo => installments
      .where((i) => i.isInstallmentPaid && !i.isPoDeposited)
      .toList(growable: false);

  /// Months the customer still owes on at [asOf].
  List<RDInstallment> get customerPending => installments
      .where((i) => !i.isInstallmentPaid || i.outstandingLateFeeAt(asOf) > 0)
      .toList(growable: false);

  double get totalCollected => installments.fold(
      0.0, (s, i) => s + i.customerPaidAmount + i.paidLateFee);

  double get totalArrears => installments
      .where((i) => i.isOverdueAt(asOf))
      .fold(0.0, (s, i) => s + i.outstandingAmountAt(asOf));
}
