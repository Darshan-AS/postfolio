import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'rd_ledger_summary.freezed.dart';
part 'rd_ledger_summary.g.dart';

/// A post-onboarding month with any activity (payment, PO deposit or absorbed fee).
/// Untouched months are reconstructed from the baseline + a dynamic fee.
@freezed
sealed class RDOpenItem with _$RDOpenItem {
  const RDOpenItem._();

  const factory RDOpenItem({
    required int installmentNo,
    @Default(0.0) double paid,
    /// Customer fee; authoritative once [isSettled], otherwise recomputed dynamically.
    @Default(0.0) double customerFee,
    @Default(false) bool isSettled,
    /// PO fee fixed at the deposit date; `0` while undeposited (computed dynamically).
    @Default(0.0) double poFee,
    @Default(0.0) double absorbedFee,
    @NullableDateOnlyConverter() DateTime? poDepositedOn,
    String? poBatchId,
  }) = _RDOpenItem;

  factory RDOpenItem.fromJson(Map<String, dynamic> json) =>
      _$RDOpenItemFromJson(json);
}

/// Per-RD cache of the projection, sized for the Monthly Hub (one row per RD).
///
/// Not truth — rebuilt from facts after every write. Anything that can go wrong with it is
/// "stale badge until the next write", never wrong money.
@freezed
sealed class RDLedgerSummary with _$RDLedgerSummary {
  const RDLedgerSummary._();

  const factory RDLedgerSummary({
    required String rdId,
    required int factsVersion,
    @DateOnlyConverter() required DateTime projectedOn,
    /// Last month (1-based) the customer has fully paid, counting consecutively from #1.
    @Default(0) int paidThroughNo,
    /// Last month deposited at the Post Office (always consecutive from #1).
    @Default(0) int depositedThroughNo,
    int? nextDueNo,
    @Default(0.0) double customerCredit,
    @Default(0.0) double openingReceivableLeft,
    /// Everything the customer currently owes the agent (opening receivable + fronted months
    /// + overdue undeposited months), net of credit.
    @Default(0.0) double owedByCustomer,
    /// Money the agent has fronted at the PO and not yet recovered from the customer.
    @Default(0.0) double receivable,
    @Default(0.0) double cashInHandCash,
    @Default(0.0) double cashInHandDigital,
    @Default(0.0) double absorbedTotal,
    /// Extra PO fee the agent bears for depositing later than the customer paid.
    @Default(0.0) double delayCostTotal,
    /// Months past their due date on which the customer has not settled.
    @Default(0) int arrearsCount,
    @Default(<RDOpenItem>[]) List<RDOpenItem> openItems,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDLedgerSummary;

  factory RDLedgerSummary.fromJson(Map<String, dynamic> json) =>
      _$RDLedgerSummaryFromJson(json);

  /// Untouched summary for an RD with no ledger activity.
  factory RDLedgerSummary.pristine(RecurringDeposit deposit, DateTime asOf) =>
      RDLedgerSummary(
        rdId: deposit.id,
        factsVersion: 0,
        projectedOn: asOf.toDateOnly(),
        paidThroughNo: deposit.initialPaidInstallments,
        depositedThroughNo: deposit.initialPaidInstallments,
        nextDueNo: deposit.initialPaidInstallments < deposit.totalMonths
            ? deposit.initialPaidInstallments + 1
            : null,
        openingReceivableLeft: deposit.openingReceivable,
        owedByCustomer: deposit.openingReceivable,
        receivable: deposit.openingReceivable,
      );

  double get cashInHand => Money.round(cashInHandCash + cashInHandDigital);

  /// Months collected in full but not yet deposited (contiguous after [depositedThroughNo]).
  int get readyForPoCount =>
      paidThroughNo > depositedThroughNo ? paidThroughNo - depositedThroughNo : 0;

  RDOpenItem? openItemFor(int installmentNo) {
    for (final item in openItems) {
      if (item.installmentNo == installmentNo) return item;
    }
    return null;
  }

  /// Reconstructs the projected month [installmentNo] as of [asOf] from this summary,
  /// using the same baseline factory and fee rule as the full projector.
  RDInstallment installmentFor(
    RecurringDeposit deposit,
    int installmentNo,
    DateTime asOf, {
    RDLedgerRules rules = RDLedgerRules.standard,
  }) {
    final base = RDScheduleFactory.baselineInstallment(
      deposit: deposit,
      installmentNo: installmentNo,
      rules: rules,
    );
    if (base.isOpeningBaseline) return base;

    final item = openItemFor(installmentNo);
    final deposited = item?.poDepositedOn;
    double feeAt(DateTime d) => rules.defaultFeeFor(
        base.installmentAmount, rules.defaultedMonths(base.dueDate, d));

    final poFee = deposited != null ? item!.poFee : feeAt(asOf);
    final customerFee = (item?.isSettled ?? false)
        ? item!.customerFee
        : feeAt(deposited ?? asOf);

    return base.copyWith(
      lateFee: customerFee,
      poLateFee: poFee,
      absorbedFee: item?.absorbedFee ?? 0.0,
      customerPaidAmount: item?.paid ?? 0.0,
      poDepositedOn: deposited,
      poBatchId: item?.poBatchId,
    );
  }

  /// Months strictly before [installmentNo] that the customer still owes on at [asOf].
  List<RDInstallment> priorOpenInstallments(
    RecurringDeposit deposit,
    int installmentNo,
    DateTime asOf, {
    RDLedgerRules rules = RDLedgerRules.standard,
  }) {
    final result = <RDInstallment>[];
    for (var no = paidThroughNo + 1; no < installmentNo; no++) {
      if (no <= deposit.initialPaidInstallments) continue;
      final inst = installmentFor(deposit, no, asOf, rules: rules);
      if (!inst.isCustomerSettled) result.add(inst);
    }
    return result;
  }
}
