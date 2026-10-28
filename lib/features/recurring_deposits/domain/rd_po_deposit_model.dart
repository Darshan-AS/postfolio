import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';

part 'rd_po_deposit_model.freezed.dart';
part 'rd_po_deposit_model.g.dart';

/// Fact: on [depositedOn] the agent deposited the **next** [installmentCount] installments of
/// RD [rdId] at the Post Office (plus their default fee), exactly as the DOP agent portal
/// records it — a count, never specific months.
///
/// The projector assigns events to months sequentially in `(depositedOn, createdAt, id)` order.
/// Because the Post Office ledger is sequential, only the latest event can be undone.
///
/// [amount] is the total handed to the counter (installments + fee) and is what agent
/// commission will later be computed from. [batchId] reserves the link to a future
/// lot/C-number feature.
@freezed
sealed class RDPoDeposit with _$RDPoDeposit {
  const RDPoDeposit._();

  const factory RDPoDeposit({
    required String id,
    required String rdId,
    @DateOnlyConverter() required DateTime depositedOn,
    required int installmentCount,
    @Default(0.0) double feePaid,
    @Default(0.0) double amount,
    String? batchId,
    @TimestampConverter() DateTime? createdAt,
  }) = _RDPoDeposit;

  factory RDPoDeposit.fromJson(Map<String, dynamic> json) =>
      _$RDPoDepositFromJson(json);
}
