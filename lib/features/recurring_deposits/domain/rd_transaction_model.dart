import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';

part 'rd_transaction_model.freezed.dart';
part 'rd_transaction_model.g.dart';

@freezed
abstract class RDTransaction with _$RDTransaction {
  const RDTransaction._();

  const factory RDTransaction({
    required String id,
    required String rdId,
    @TimestampConverter() required DateTime paidDate,
    required double amount,
    required RDPaymentMode paymentMode,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDTransaction;

  factory RDTransaction.fromJson(Map<String, dynamic> json) =>
      _$RDTransactionFromJson(json);
}
