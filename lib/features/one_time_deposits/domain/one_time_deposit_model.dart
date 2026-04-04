import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';

part 'one_time_deposit_model.freezed.dart';
part 'one_time_deposit_model.g.dart';

@freezed
sealed class OneTimeDeposit with _$OneTimeDeposit implements BaseDeposit {
  const OneTimeDeposit._();

  const factory OneTimeDeposit({
    required String id,
    required String rowId,
    required String accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    @Default(0.0) double interestRate,
    required String customerId,
    required OneTimeSchemeType schemeType,
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedSavingsAccountNo,
    @Default([]) List<Nominee> nominees,
  }) = _OneTimeDeposit;

  factory OneTimeDeposit.fromJson(Map<String, dynamic> json) =>
      _$OneTimeDepositFromJson(json);

  static (String?, OneTimeDeposit?) create({
    required String id,
    required String rowId,
    required String accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    double interestRate = 0.0,
    required String customerId,
    required OneTimeSchemeType schemeType,
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedSavingsAccountNo,
    List<Nominee> nominees = const [],
  }) {
    final accountError = BaseDeposit.validateAccountNo(accountNo);
    if (accountError != null) return (accountError, null);

    final amountError = BaseDeposit.validateAmount(
      principalAmount,
      'Principal Amount',
    );
    if (amountError != null) return (amountError, null);

    final termError = BaseDeposit.validateTerm(termYears, termMonths);
    if (termError != null) return (termError, null);

    final dateError = BaseDeposit.validateDates(startDate, maturityDate);
    if (dateError != null) return (dateError, null);

    return (
      null,
      OneTimeDeposit(
        id: id,
        rowId: rowId,
        accountNo: accountNo.trim(),
        principalAmount: principalAmount,
        termYears: termYears,
        termMonths: termMonths,
        interestRate: interestRate,
        customerId: customerId,
        schemeType: schemeType,
        maturityAmount: maturityAmount,
        startDate: startDate,
        maturityDate: maturityDate,
        linkedSavingsAccountNo: linkedSavingsAccountNo?.trim(),
        nominees: List.unmodifiable(nominees),
      ),
    );
  }
}
