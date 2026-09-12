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
    @Default(0.0) double installmentAmount,
    @Default(0.0) double lateFeeAmount,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDTransaction;

  factory RDTransaction.fromJson(Map<String, dynamic> json) =>
      _$RDTransactionFromJson(json);

  /// Effective component allocated to base installment principal.
  /// Defaults to total [amount] if both split components are 0.0 (backward compatibility).
  double get effectiveInstallmentAmount =>
      (installmentAmount == 0.0 && lateFeeAmount == 0.0) ? amount : installmentAmount;

  /// Effective component allocated to default late fees.
  double get effectiveLateFeeAmount => lateFeeAmount;
}
