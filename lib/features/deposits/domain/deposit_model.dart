import 'package:freezed_annotation/freezed_annotation.dart';

part 'deposit_model.freezed.dart';
part 'deposit_model.g.dart';

@freezed
sealed class Nominee with _$Nominee {
  const factory Nominee({
    required String name,
    required String relationship, // e.g., "Spouse", "Son"
    String? phone, // Optional, useful if the bank needs to contact them
  }) = _Nominee;

  factory Nominee.fromJson(Map<String, dynamic> json) =>
      _$NomineeFromJson(json);
}

@freezed
sealed class Deposit with _$Deposit {
  const factory Deposit({
    required String id,
    required String rowId,
    required String accountNo,
    required double amount,
    required int termYears,
    required int termMonths,
    @Default(0.0) double interestRate,
    required String customerId,
    required String schemeId,
    required double maturityAmount,
    required DateTime depositDate,
    required DateTime maturityDate,
    @Default([]) List<Nominee> nominees, // Embedded List of Nominees
  }) = _Deposit;

  factory Deposit.fromJson(Map<String, dynamic> json) =>
      _$DepositFromJson(json);
}
