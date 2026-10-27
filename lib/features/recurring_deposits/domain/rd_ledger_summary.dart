import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

part 'rd_ledger_summary.freezed.dart';
part 'rd_ledger_summary.g.dart';

/// A month that deviates from the untouched baseline (any payment, deposit or waiver).
///
/// `frozenLateFee` is non-zero only once principal is settled (the fee stops accruing);
/// for still-unpaid months it stays `0` so the reader computes the fee dynamically as of *today*
/// and a cached summary never shows a stale fee.
@freezed
sealed class RDOpenItem with _$RDOpenItem {
  const RDOpenItem._();

  const factory RDOpenItem({
    required int installmentNo,
    @Default(0.0) double paidPrincipal,
    @Default(0.0) double paidFee,
    @Default(0.0) double frozenLateFee,
    @Default(false) bool isWaived,
    @NullableDateOnlyConverter() DateTime? poDepositedOn,
    String? poBatchId,
  }) = _RDOpenItem;

  factory RDOpenItem.fromJson(Map<String, dynamic> json) =>
      _$RDOpenItemFromJson(json);
}

/// Per-RD cache of the projection, sized for the Monthly Hub (one row per RD).
///
/// Not truth — rebuilt from facts after every write and whenever `factsVersion` disagrees
/// with the live fact counts. Anything that can go wrong with it is "stale badge until the
/// next write", never wrong money.
@freezed
sealed class RDLedgerSummary with _$RDLedgerSummary {
  const RDLedgerSummary._();

  const factory RDLedgerSummary({
    required String rdId,
    required int factsVersion,
    @DateOnlyConverter() required DateTime projectedOn,
    @Default(0) int paidThroughNo,
    int? nextDueNo,
    @Default(0.0) double customerCredit,
    @Default(0.0) double cashInHand,
    @Default(0.0) double pocketAdvance,
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
        nextDueNo: deposit.initialPaidInstallments < deposit.totalMonths
            ? deposit.initialPaidInstallments + 1
            : null,
      );

  RDOpenItem? openItemFor(int installmentNo) {
    for (final item in openItems) {
      if (item.installmentNo == installmentNo) return item;
    }
    return null;
  }

  /// Reconstructs the projected installment for [installmentNo] from this summary.
  ///
  /// Uses the same baseline factory as the full projector, so the Hub and the Detail screen
  /// agree on every untouched month by construction.
  RDInstallment installmentFor(
    RecurringDeposit deposit,
    int installmentNo, {
    RDLedgerRules rules = RDLedgerRules.standard,
  }) {
    final base = RDScheduleFactory.baselineInstallment(
      deposit: deposit,
      installmentNo: installmentNo,
      rules: rules,
    );
    final item = openItemFor(installmentNo);
    if (item == null || base.isOpeningBaseline) return base;

    final paid = item.paidPrincipal;
    final status = paid <= 0
        ? RDInstallmentStatus.unpaid
        : (paid >= base.installmentAmount
            ? RDInstallmentStatus.fullyPaid
            : RDInstallmentStatus.partiallyPaid);

    return base.copyWith(
      customerPaidAmount: paid,
      customerStatus: status,
      poStatus: item.poDepositedOn != null ? RDPoStatus.paid : RDPoStatus.unpaid,
      poPaidDate: item.poDepositedOn,
      poBatchId: item.poBatchId,
      lateFee: item.frozenLateFee,
      paidLateFee: item.paidFee,
      isLateFeeWaived: item.isWaived,
    );
  }

  /// Installments strictly before [installmentNo] that still owe principal or fee at [asOf].
  List<RDInstallment> priorOpenInstallments(
    RecurringDeposit deposit,
    int installmentNo,
    DateTime asOf, {
    RDLedgerRules rules = RDLedgerRules.standard,
  }) {
    final result = <RDInstallment>[];
    final firstCandidate = paidThroughNo + 1;
    for (var no = firstCandidate; no < installmentNo; no++) {
      if (no < 1) continue;
      final inst = installmentFor(deposit, no, rules: rules);
      if (!inst.isFullySettled || inst.outstandingLateFeeAt(asOf) > 0) {
        result.add(inst);
      }
    }
    // Months at/after paidThroughNo may still owe a fee even if principal is settled.
    for (final item in openItems) {
      if (item.installmentNo <= paidThroughNo &&
          item.installmentNo < installmentNo &&
          !item.isWaived &&
          item.frozenLateFee > item.paidFee) {
        result.add(installmentFor(deposit, item.installmentNo, rules: rules));
      }
    }
    result.sort((a, b) => a.installmentNo!.compareTo(b.installmentNo!));
    return result;
  }
}
