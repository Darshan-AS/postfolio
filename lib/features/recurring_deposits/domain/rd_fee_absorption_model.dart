import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';

part 'rd_fee_absorption_model.freezed.dart';
part 'rd_fee_absorption_model.g.dart';

/// Fact: the agent paid [amount] of installment [installmentNo]'s default fee from their own
/// pocket instead of collecting it from the customer.
///
/// The Post Office still receives the full fee; absorption only changes who bore it, so it
/// reduces what the customer owes and shows up in the agent's float. One row per month.
@freezed
sealed class RDFeeAbsorption with _$RDFeeAbsorption {
  const RDFeeAbsorption._();

  const factory RDFeeAbsorption({
    required String rdId,
    required int installmentNo,
    required double amount,
    @DateOnlyConverter() required DateTime absorbedOn,
    String? note,
    @TimestampConverter() DateTime? createdAt,
  }) = _RDFeeAbsorption;

  factory RDFeeAbsorption.fromJson(Map<String, dynamic> json) =>
      _$RDFeeAbsorptionFromJson(json);
}
