import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
    required DateTime startDate,
    String? linkedSavingsAccountNo,
    @Default([]) List<Nominee> nominees,
    @Default(DepositStatus.active) DepositStatus status,
  }) = _OneTimeDeposit;

  @override
  InvestmentProjection get projection => ProjectionCalculator.calculateOneTimeDeposit(
    schemeType: schemeType,
    principalAmount: principalAmount,
    interestRate: interestRate,
    startDate: startDate,
    termYears: termYears,
  );

  @override
  double get maturityAmount => projection.maturityAmount;

  @override
  DateTime get maturityDate => projection.maturityDate;

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
    startDate: DateTime.now(),
  );

  // --- Domain Validation Rules ---

  static String? validateAccountNo(String? accountNo) =>
      BaseDeposit.validateAccountNo(accountNo);

  static String? validateAmount(double? amount, String fieldName) =>
      BaseDeposit.validateAmount(amount, fieldName);

  static String? validateTerm(int years, int months) =>
      BaseDeposit.validateTerm(years, months);

  static Result<OneTimeDeposit, String> create({
    required String id,
    required String accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    double interestRate = 0.0,
    required String customerId,
    required OneTimeSchemeType schemeType,
    required DateTime startDate,
    String? linkedSavingsAccountNo,
    List<Nominee> nominees = const [],
    DepositStatus status = DepositStatus.active,
  }) {
    final validationError =
        BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(principalAmount, 'Principal Amount') ??
        BaseDeposit.validateTerm(termYears, termMonths);

    if (validationError != null) return Failure(validationError);

    if (schemeType.isFixedTenure) {
      if (!schemeType.allowedTenuresInYears.contains(termYears)) {
        return Failure(t.errors.invalidTenure(years: termYears, scheme: schemeType.displayName));
      }
      if (termMonths != 0) {
        return Failure(t.errors.fixedTenureNoMonths);
      }
    }

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
        startDate: startDate,
        linkedSavingsAccountNo: linkedSavingsAccountNo?.trim(),
        nominees: List.unmodifiable(nominees),
        status: status,
      ),
    );
  }
}
