import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';

part 'rd_transaction_model.freezed.dart';
part 'rd_transaction_model.g.dart';

/// Fact: the customer handed [amount] to the agent on [paidDate].
///
/// A payment is just money. How it is applied (which months, how much of it is default
/// fee) is derived by `RDLedgerProjector` — the Post Office treats installment + fee as one
/// inseparable due amount, so there is nothing for the agent to "split".
///
/// [collectionId] groups several per-account transactions recorded from one household
/// hand-over (future feature; nullable today).
@freezed
sealed class RDTransaction with _$RDTransaction {
  const RDTransaction._();

  const factory RDTransaction({
    required String id,
    required String rdId,
    @TimestampConverter() required DateTime paidDate,
    required double amount,
    required RDPaymentMode paymentMode,
    String? collectionId,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDTransaction;

  factory RDTransaction.fromJson(Map<String, dynamic> json) =>
      _$RDTransactionFromJson(json);
}
