import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';

part 'rd_installment_model.freezed.dart';
part 'rd_installment_model.g.dart';

/// A single month of an RD schedule **as projected from facts** — a passbook line.
///
/// Read model only: every field is derived by `RDLedgerProjector`; nothing here is written
/// to the database. The customer owes one number per month, [dueAmount] =
/// installment + default fee − fee absorbed by the agent.
@freezed
sealed class RDInstallment with _$RDInstallment {
  const RDInstallment._();

  const factory RDInstallment({
    required String id,
    required String rdId,
    required int installmentNo,
    @TimestampConverter() required DateTime installmentDate,
    @TimestampConverter() required DateTime dueDate,
    required double installmentAmount,
    @Default(false) bool isOpeningBaseline,

    /// Default fee the **customer** owes for this month: fixed on the day they finished
    /// paying it (or the PO deposit date if that came first); accrues until then.
    @Default(0.0) double lateFee,

    /// Default fee the **Post Office** charges for this month: fixed at the deposit date once
    /// deposited, otherwise estimated as of the projection date. May exceed [lateFee] when the
    /// agent deposits later than the customer paid — that gap is the agent's delay cost.
    @Default(0.0) double poLateFee,

    /// Portion of [lateFee] the agent chose to pay from pocket.
    @Default(0.0) double absorbedFee,

    /// Customer money applied to this month (toward [dueAmount]).
    @Default(0.0) double customerPaidAmount,

    /// Set when the month has been deposited at the Post Office.
    @NullableDateOnlyConverter() DateTime? poDepositedOn,
    String? poBatchId,
  }) = _RDInstallment;

  factory RDInstallment.fromJson(Map<String, dynamic> json) =>
      _$RDInstallmentFromJson(json);

  static const _rules = RDLedgerRules.standard;

  /// What the customer must pay for this month.
  double get dueAmount =>
      Money.round(installmentAmount + lateFee - absorbedFee);

  /// Fee the agent bears because they deposited later than the customer paid.
  double get agentDelayCost =>
      Money.round((poLateFee - lateFee).clamp(0.0, double.infinity));

  /// Total the PO charges/will charge for this month.
  double get poDueAmount => Money.round(installmentAmount + poLateFee);

  /// Customer-side fee still owed on this month.
  double get customerFeeDue =>
      Money.round((lateFee - absorbedFee).clamp(0.0, double.infinity));

  /// Remaining customer balance on this month.
  double get outstandingAmount =>
      Money.round((dueAmount - customerPaidAmount).clamp(0.0, double.infinity));

  /// Customer has covered the full due amount.
  bool get isCustomerSettled =>
      Money.toPaise(customerPaidAmount) >= Money.toPaise(dueAmount);

  /// Some, but not all, of the due amount has been paid.
  bool get isPartiallyPaid =>
      !isCustomerSettled && Money.toPaise(customerPaidAmount) > 0;

  bool get isPoDeposited => poDepositedOn != null;

  /// The agent fronted this month at the PO and the customer still owes on it.
  bool get isFrontedByAgent => isPoDeposited && !isCustomerSettled && !isOpeningBaseline;

  /// Completely done: customer paid and PO deposited.
  bool get isFullySettled => isCustomerSettled && isPoDeposited;

  /// Collected in full but not yet at the PO.
  bool get isReadyForPo => isCustomerSettled && !isPoDeposited;

  /// Whether this month is in default on calendar day [evaluationDate].
  /// Deposited months are never overdue; paying on the due date itself is never late.
  bool isOverdueAt(DateTime evaluationDate) {
    if (isPoDeposited || isCustomerSettled) return false;
    return _rules.isInDefault(dueDate, evaluationDate);
  }

  bool isDueOn(DateTime evaluationDate) =>
      evaluationDate.toDateOnly() == dueDate.toDateOnly();

  int overdueDaysAt(DateTime evaluationDate) {
    final diff = evaluationDate.toDateOnly().difference(dueDate.toDateOnly()).inDays;
    return diff > 0 ? diff : 0;
  }

  int daysUntilDueAt(DateTime evaluationDate) {
    final diff = dueDate.toDateOnly().difference(evaluationDate.toDateOnly()).inDays;
    return diff > 0 ? diff : 0;
  }

  int defaultedMonthsAt(DateTime evaluationDate) =>
      _rules.defaultedMonths(dueDate, evaluationDate);

  /// The single source of truth for how this month is labelled and coloured.
  RDInstallmentDisplayStatus displayStatusAt(DateTime evaluationDate) {
    if (isOpeningBaseline) return RDInstallmentDisplayStatus.baseline;
    if (isPoDeposited) {
      return isCustomerSettled
          ? RDInstallmentDisplayStatus.settled
          : RDInstallmentDisplayStatus.frontedByAgent;
    }
    if (isCustomerSettled) return RDInstallmentDisplayStatus.collectedPendingPo;
    if (isPartiallyPaid) return RDInstallmentDisplayStatus.partiallyPaid;
    if (isOverdueAt(evaluationDate)) return RDInstallmentDisplayStatus.overdue;
    if (isDueOn(evaluationDate)) return RDInstallmentDisplayStatus.dueToday;
    return RDInstallmentDisplayStatus.upcoming;
  }
}
