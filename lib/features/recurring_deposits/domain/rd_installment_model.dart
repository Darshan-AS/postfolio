import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/timestamp_converter.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';

part 'rd_installment_model.freezed.dart';
part 'rd_installment_model.g.dart';

@freezed
abstract class RDInstallment with _$RDInstallment {
  const RDInstallment._();

  const factory RDInstallment({
    required String id,
    required String rdId,
    @TimestampConverter() required DateTime installmentDate,
    @TimestampConverter() required DateTime dueDate,
    required double installmentAmount,
    @Default(0.0) double customerPaidAmount,
    @Default(RDInstallmentStatus.unpaid) RDInstallmentStatus customerStatus,
    @Default(RDPoStatus.unpaid) RDPoStatus poStatus,
    @TimestampConverter() DateTime? poPaidDate,
    @Default(0.0) double lateFee,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _RDInstallment;

  factory RDInstallment.fromJson(Map<String, dynamic> json) =>
      _$RDInstallmentFromJson(json);

  /// Computes remaining balance due to fully cover installment + late fee.
  double get outstandingAmount =>
      (installmentAmount + lateFee - customerPaidAmount).clamp(0.0, double.infinity);

  /// Determine if this installment is currently overdue based on due date.
  bool isOverdueAt(DateTime evaluationDate) {
    if (customerStatus == RDInstallmentStatus.fullyPaid) return false;
    return evaluationDate.isAfter(dueDate);
  }

  /// Calculates the number of defaulted calendar months at an evaluation date.
  int defaultedMonthsAt(DateTime evaluationDate) {
    if (!evaluationDate.isAfter(dueDate)) return 0;
    final months = (evaluationDate.year - dueDate.year) * 12 +
        (evaluationDate.month - dueDate.month);
    return months < 1 ? 1 : months;
  }

  /// Helper to calculate 1% per defaulted month according to Post Office rules.
  double computeExpectedLateFee(DateTime evaluationDate) {
    final months = defaultedMonthsAt(evaluationDate);
    if (months <= 0) return 0.0;
    return (installmentAmount * 0.01 * months).ceilToDouble();
  }
}
