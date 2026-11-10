import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'rd_monthly_operation_item.freezed.dart';

/// One row of the Monthly Hub: an account's installment for the selected month plus the
/// account-level counters the agent needs to act on it. Built from `RDLedgerSummary`.
@freezed
sealed class RDMonthlyOperationItem with _$RDMonthlyOperationItem {
  const RDMonthlyOperationItem._();

  const factory RDMonthlyOperationItem({
    required RecurringDeposit deposit,
    required RDInstallment installment,
    required RDLedgerSummary summary,
    /// Months before this one the customer still owes on (arrears carried into this month).
    @Default(<RDInstallment>[]) List<RDInstallment> priorOpen,
    @Default(true) bool hasSummary,
  }) = _RDMonthlyOperationItem;

  int get installmentNumber => installment.installmentNo;

  RDInstallmentDisplayStatus displayStatus(DateTime now) =>
      installment.displayStatusAt(now);

  bool get isSettled => installment.isFullySettled;
  bool get isReadyForPo => installment.isReadyForPo;
  bool get isFrontedByAgent => installment.isFrontedByAgent;
  bool get isCustomerPending => !installment.isCustomerSettled && !installment.isOpeningBaseline;
  bool isOverdue(DateTime now) => installment.isOverdueAt(now);

  int get priorOverdueCount => priorOpen.length;
  double get priorOverdueAmount => priorOpen.fold(0.0, (s, p) => s + p.outstandingAmount);
  bool get hasPriorArrears => priorOpen.isNotEmpty;

  /// What the customer must pay to bring the account up to date through this month.
  double get totalOutstanding =>
      priorOverdueAmount + installment.outstandingAmount + summary.openingReceivableLeft;

  /// Fee component of [totalOutstanding] (informational).
  double get totalFeeDue =>
      priorOpen.fold(0.0, (s, p) => s + p.customerFeeDue) + installment.customerFeeDue;

  bool hasOverdueDebt(DateTime now) =>
      hasPriorArrears || (installment.isOverdueAt(now) && isCustomerPending);

  bool isUpcoming(DateTime now) {
    final m = DateTime(now.year, now.month);
    final t = DateTime(installment.installmentDate.year, installment.installmentDate.month);
    return t.isAfter(m);
  }

  /// Whether this account falls into the 1st-to-15th India Post statutory deadline window.
  bool get isFirstHalfDue => installment.dueDate.day <= 15;

  /// Number of contiguous months that can be deposited on the next PO visit.
  int get readyForPoCount => summary.readyForPoCount;

  /// Can deposit something at the PO: ready months, or front this month from pocket.
  bool get canDepositToPo =>
      !installment.isOpeningBaseline && !installment.isPoDeposited;

  /// Can undo the latest PO event only if this month is the most recently deposited one.
  bool get isLatestDeposited =>
      installment.isPoDeposited &&
      !installment.isOpeningBaseline &&
      installment.installmentNo == summary.depositedThroughNo;

  /// Prefilled payment amount when logging a customer payment from the Monthly Hub.
  double get initialPaymentAmount => totalOutstanding;
}
