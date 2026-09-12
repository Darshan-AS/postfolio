import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';

part 'rd_monthly_operation_item.freezed.dart';

@freezed
abstract class RDMonthlyOperationItem with _$RDMonthlyOperationItem {
  const RDMonthlyOperationItem._();

  const factory RDMonthlyOperationItem({
    required RecurringDeposit deposit,
    required RDInstallment installment,
    @Default(0) int priorOverdueCount,
    @Default(0.0) double priorOverdueAmount,
    @Default(0.0) double priorOverdueFee,
  }) = _RDMonthlyOperationItem;

  /// Total default fee owed across current installment and any prior overdue installments.
  double totalDefaultFee(DateTime now) {
    if (isUpcoming(now)) return 0.0;
    final currentFee = installment.outstandingLateFeeAt(now);
    return priorOverdueFee + currentFee;
  }

  /// Whether this installment is overdue evaluated at [now].
  bool isOverdue(DateTime now) => installment.isOverdueAt(now);

  /// Whether customer has paid the installment, but it has not yet been deposited to the Post Office.
  bool get isReadyForPo =>
      installment.isInstallmentPaid && installment.poStatus != RDPoStatus.paid;

  /// Whether agent has advanced payment to Post Office from pocket, but customer has not yet paid.
  bool get isPoAdvanced =>
      !installment.isInstallmentPaid && installment.poStatus == RDPoStatus.paid;

  /// Whether Post Office deposit is complete (either from customer funds or agent advance).
  bool get isPoPaid => installment.poStatus == RDPoStatus.paid;

  /// Whether this installment can be deposited to the Post Office (not yet deposited).
  bool get canDepositToPo => installment.poStatus != RDPoStatus.paid;

  /// Whether this installment's Post Office deposit can be reverted (already deposited).
  bool get canRevertPo => installment.poStatus == RDPoStatus.paid;

  /// Installment sequence number (1 to 60) relative to deposit start date.
  int get installmentNumber {
    final diffYears = installment.installmentDate.year - deposit.startDate.year;
    final diffMonths =
        installment.installmentDate.month - deposit.startDate.month;
    final num = diffYears * 12 + diffMonths + 1;
    return num > 0 ? num : 1;
  }

  /// Whether installment principal is paid and PO is deposited, but a default fee remains unresolved.
  bool get isFeePending =>
      installment.isInstallmentPaid &&
      isPoPaid &&
      !installment.isLateFeeResolved;

  /// Whether both customer has paid, Post Office deposit is complete, and any default fees are resolved.
  bool get isSettled =>
      installment.isInstallmentPaid &&
      installment.poStatus == RDPoStatus.paid &&
      installment.isLateFeeResolved;

  /// Whether customer payment is pending (unpaid principal, partial principal, or unresolved default fee).
  bool get isCustomerPending => !installment.isInstallmentPaid || isFeePending;

  /// Total payable amount at [now] for this specific installment (outstanding principal + dynamic late fee if overdue).
  double totalPayable(DateTime now) => installment.outstandingAmountAt(now);

  /// Total outstanding amount to bring this account completely up to date (prior arrears + this month's payable).
  double totalOutstandingPayable(DateTime now) =>
      priorOverdueAmount + totalPayable(now);

  /// Whether this account has any overdue debt (either carryover arrears from prior months or this month is overdue).
  /// In future months, installments are upcoming and not overdue.
  bool hasOverdueDebt(DateTime now) =>
      !isUpcoming(now) &&
      (priorOverdueCount > 0 || (isOverdue(now) && isCustomerPending));

  /// Whether this installment is upcoming in a future month relative to [now].
  bool isUpcoming(DateTime now) {
    final currentMonthStart = DateTime(now.year, now.month);
    final targetMonthStart = DateTime(
      installment.installmentDate.year,
      installment.installmentDate.month,
    );
    return targetMonthStart.isAfter(currentMonthStart);
  }

  /// Whether any default fee exists for this item (pending, paid, or waived).
  /// Hidden when there is no default fee at all.
  bool hasDefaultFee(DateTime now) {
    if (isUpcoming(now)) return false;
    return installment.isLateFeeWaived ||
        installment.paidLateFee > 0 ||
        totalDefaultFee(now) > 0 ||
        installment.lateFee > 0;
  }
}
