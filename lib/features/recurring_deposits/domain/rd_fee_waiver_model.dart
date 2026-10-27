import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';

part 'rd_fee_waiver_model.freezed.dart';
part 'rd_fee_waiver_model.g.dart';

/// Fact: the agent forgave the default fee on installment [installmentNo] of RD [rdId].
///
/// Waivers are discretionary decisions, so they are stored as facts rather than derived.
/// Un-waiving deletes the row.
@freezed
sealed class RDFeeWaiver with _$RDFeeWaiver {
  const RDFeeWaiver._();

  const factory RDFeeWaiver({
    required String rdId,
    required int installmentNo,
    @DateOnlyConverter() required DateTime waivedOn,
    String? note,
    @TimestampConverter() DateTime? createdAt,
  }) = _RDFeeWaiver;

  factory RDFeeWaiver.fromJson(Map<String, dynamic> json) =>
      _$RDFeeWaiverFromJson(json);
}
