import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:postfolio/features/deposits/domain/deposit_model.dart';

part 'recurring_deposit_model.freezed.dart';
part 'recurring_deposit_model.g.dart';

@freezed
class RecurringDeposit with _$RecurringDeposit {
  const factory RecurringDeposit({
    required String id,
    required String accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    required String schemeId,
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    @Default([]) List<Nominee> nominees, // Embedded List of Nominees
  }) = _RecurringDeposit;

  factory RecurringDeposit.fromJson(Map<String, dynamic> json) =>
      _$RecurringDepositFromJson(json);
}
