import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/utils/result.dart';

part 'one_time_deposit_model.freezed.dart';
part 'one_time_deposit_model.g.dart';

@freezed
sealed class OneTimeDeposit with _$OneTimeDeposit implements BaseDeposit {
  const OneTimeDeposit._();

  const factory OneTimeDeposit({
    required String id,
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
    @Default(DepositStatus.active) DepositStatus status,
  }) = _OneTimeDeposit;

  factory OneTimeDeposit.fromJson(Map<String, dynamic> json) =>
      _$OneTimeDepositFromJson(json);

  static OneTimeDeposit get dummy => OneTimeDeposit(
    id: 'dummy',
    accountNo: 'Loading...',
    principalAmount: 10000.0,
    termYears: 5,
    termMonths: 0,
    customerId: 'Loading Dummy Name...',
    schemeType: OneTimeSchemeType.timeDeposit,
    maturityAmount: 15000.0,
    startDate: DateTime.now(),
    maturityDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );

  // --- Domain Validation Rules ---

  static String? validateAccountNo(String? accountNo) =>
      BaseDeposit.validateAccountNo(accountNo);

  static String? validateAmount(double? amount, String fieldName) =>
      BaseDeposit.validateAmount(amount, fieldName);

  static String? validateTerm(int years, int months) =>
      BaseDeposit.validateTerm(years, months);

  static String? validateDates(DateTime startDate, DateTime maturityDate) =>
      BaseDeposit.validateDates(startDate, maturityDate);

  static Result<OneTimeDeposit, String> create({
    required String id,
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
    DepositStatus status = DepositStatus.active,
  }) {
    final validationError =
        BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(principalAmount, 'Principal Amount') ??
        BaseDeposit.validateTerm(termYears, termMonths) ??
        BaseDeposit.validateDates(startDate, maturityDate);

    if (validationError != null) return Failure(validationError);

    return Success(
      OneTimeDeposit(
        id: id,
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
        status: status,
      ),
    );
  }
}
