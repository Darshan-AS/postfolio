import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';

part 'rd_ledger_projection.freezed.dart';

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

  List<RDInstallment> get customerPending =>
      installments.where((i) => !i.isCustomerSettled && !i.isOpeningBaseline).toList(growable: false);

  /// Months past due that the customer has not settled.
  List<RDInstallment> get arrears => installments
      .where((i) => !i.isOpeningBaseline && !i.isCustomerSettled && i.dueDate.isBefore(asOf))
      .toList(growable: false);

  double get totalCollected =>
      installments.fold(0.0, (s, i) => s + (i.isOpeningBaseline ? 0 : i.customerPaidAmount));
}
