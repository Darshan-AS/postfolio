import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';

part 'rd_installment_model.freezed.dart';
part 'rd_installment_model.g.dart';

/// A single month of an RD schedule **as projected from facts**.
///
/// This is a read model: every monetary and status field is derived by `RDLedgerProjector`
/// from transactions, PO deposits and waivers. It is never written to the database.
@freezed
sealed class RDInstallment with _$RDInstallment {
  const RDInstallment._();

  const factory RDInstallment({
    required String id,
    required String rdId,
    int? installmentNo,
    @TimestampConverter() required DateTime installmentDate,
    @TimestampConverter() required DateTime dueDate,
    required double installmentAmount,
    @Default(false) bool isOpeningBaseline,
    @Default(0.0) double customerPaidAmount,
    @Default(RDInstallmentStatus.unpaid) RDInstallmentStatus customerStatus,
    @Default(RDPoStatus.unpaid) RDPoStatus poStatus,
    @TimestampConverter() DateTime? poPaidDate,
    String? poBatchId,
    @Default(0.0) double lateFee,
    @Default(0.0) double paidLateFee,
    @Default(false) bool isLateFeeWaived,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDInstallment;

  factory RDInstallment.fromJson(Map<String, dynamic> json) =>
      _$RDInstallmentFromJson(json);

  static const _rules = RDLedgerRules.standard;

  /// Effective late fee considering any fee waiver.
  double get effectiveLateFee => isLateFeeWaived ? 0.0 : lateFee;

  /// Late fee at [evaluationDate]: the projected (frozen-at-settlement) fee when present,
  /// otherwise the statutory fee accrued up to [evaluationDate] for a still-unpaid month.
  double dynamicLateFeeAt(DateTime evaluationDate) {
    if (isLateFeeWaived) return 0.0;
    if (lateFee > 0.0) return lateFee;
    if (isInstallmentPaid) return 0.0;
    return computeExpectedLateFee(evaluationDate);
  }

  /// Remaining unpaid principal balance for this installment.
  double get outstandingPrincipal =>
      Money.round((installmentAmount - customerPaidAmount).clamp(0.0, double.infinity));

  /// Remaining unpaid late fee owed by customer.
  double get outstandingLateFee => isLateFeeWaived
      ? 0.0
      : Money.round((lateFee - paidLateFee).clamp(0.0, double.infinity));

  /// Outstanding late fee owed by customer at [evaluationDate].
  double outstandingLateFeeAt(DateTime evaluationDate) {
    if (isLateFeeWaived) return 0.0;
    final totalFee = dynamicLateFeeAt(evaluationDate);
    return Money.round((totalFee - paidLateFee).clamp(0.0, double.infinity));
  }

  /// Computes remaining total balance due (principal + outstanding late fee).
  double get outstandingAmount => outstandingPrincipal + outstandingLateFee;

  /// Remaining total balance due at [evaluationDate].
  double outstandingAmountAt(DateTime evaluationDate) =>
      outstandingPrincipal + outstandingLateFeeAt(evaluationDate);

  /// Whether the customer has fully covered the base installment amount.
  bool get isInstallmentPaid =>
      Money.toPaise(customerPaidAmount) >= Money.toPaise(installmentAmount);

  /// Whether any principal has been paid without covering the full installment.
  bool get isPartiallyPaid =>
      !isInstallmentPaid && Money.toPaise(customerPaidAmount) > 0;

  /// Whether the late fee is fully resolved (either waived, 0, or fully paid).
  bool get isLateFeeResolved =>
      isLateFeeWaived ||
      Money.isZero(lateFee) ||
      Money.toPaise(paidLateFee) >= Money.toPaise(lateFee);

  /// Whether this installment is completely settled (both principal and late fee).
  bool get isFullySettled => isInstallmentPaid && isLateFeeResolved;

  /// Whether the Post Office deposit has been made for this month.
  bool get isPoDeposited => poStatus == RDPoStatus.paid;

  /// Whether this installment is in default on calendar day [evaluationDate].
  /// Paying on the due date itself is never late.
  bool isOverdueAt(DateTime evaluationDate) {
    if (isInstallmentPaid) return false;
    return _rules.isInDefault(dueDate, evaluationDate);
  }

  /// Whether [evaluationDate] falls on the due date (calendar-day comparison).
  bool isDueOn(DateTime evaluationDate) =>
      evaluationDate.toDateOnly() == dueDate.toDateOnly();

  /// Whole days past the due date at [evaluationDate] (0 when not overdue).
  int overdueDaysAt(DateTime evaluationDate) {
    final diff = evaluationDate.toDateOnly().difference(dueDate.toDateOnly()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Whole days until the due date at [evaluationDate] (0 when due today or past).
  int daysUntilDueAt(DateTime evaluationDate) {
    final diff = dueDate.toDateOnly().difference(evaluationDate.toDateOnly()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Number of defaulted calendar months at [evaluationDate].
  int defaultedMonthsAt(DateTime evaluationDate) =>
      _rules.defaultedMonths(dueDate, evaluationDate);

  /// Statutory default fee accrued by [evaluationDate] for an unpaid month.
  double computeExpectedLateFee(DateTime evaluationDate) =>
      _rules.defaultFeeFor(installmentAmount, defaultedMonthsAt(evaluationDate));

  /// The single source of truth for how this month should be labelled and coloured.
  RDInstallmentDisplayStatus displayStatusAt(DateTime evaluationDate) {
    if (isOpeningBaseline) return RDInstallmentDisplayStatus.baseline;

    final feeOutstanding = outstandingLateFeeAt(evaluationDate) > 0;

    if (isInstallmentPaid) {
      if (!isPoDeposited) return RDInstallmentDisplayStatus.collectedPendingPo;
      return feeOutstanding
          ? RDInstallmentDisplayStatus.feePending
          : RDInstallmentDisplayStatus.settled;
    }

    if (isPoDeposited) return RDInstallmentDisplayStatus.pocketAdvanced;
    if (isPartiallyPaid) return RDInstallmentDisplayStatus.partiallyPaid;
    if (isOverdueAt(evaluationDate)) return RDInstallmentDisplayStatus.overdue;
    if (isDueOn(evaluationDate)) return RDInstallmentDisplayStatus.dueToday;
    return RDInstallmentDisplayStatus.upcoming;
  }
}
