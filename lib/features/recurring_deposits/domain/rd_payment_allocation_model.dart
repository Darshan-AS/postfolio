import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';

part 'rd_payment_allocation_model.freezed.dart';
part 'rd_payment_allocation_model.g.dart';

@freezed
abstract class RDPaymentAllocation with _$RDPaymentAllocation {
  const RDPaymentAllocation._();

  const factory RDPaymentAllocation({
    required String id,
    required String transactionId,
    required String rdId,
    required int installmentNo,
    @Default(0.0) double principalAmount,
    @Default(0.0) double lateFeeAmount,
    @TimestampConverter() DateTime? createdAt,
  }) = _RDPaymentAllocation;

  factory RDPaymentAllocation.fromJson(Map<String, dynamic> json) =>
      _$RDPaymentAllocationFromJson(json);

  double get totalAllocated => principalAmount + lateFeeAmount;
}
