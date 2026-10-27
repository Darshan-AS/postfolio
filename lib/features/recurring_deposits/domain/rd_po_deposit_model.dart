import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';

part 'rd_po_deposit_model.freezed.dart';
part 'rd_po_deposit_model.g.dart';

/// Fact: installment [installmentNo] of RD [rdId] was deposited at the Post Office on [depositedOn].
///
/// One row per deposited month (`PRIMARY KEY (rd_id, installment_no)`), so depositing the same
/// month twice is a constraint error rather than a silent overwrite. Reverting a deposit deletes the row.
@freezed
sealed class RDPoDeposit with _$RDPoDeposit {
  const RDPoDeposit._();

  const factory RDPoDeposit({
    required String rdId,
    required int installmentNo,
    @DateOnlyConverter() required DateTime depositedOn,
    String? batchId,
    @TimestampConverter() DateTime? createdAt,
  }) = _RDPoDeposit;

  factory RDPoDeposit.fromJson(Map<String, dynamic> json) =>
      _$RDPoDepositFromJson(json);
}
