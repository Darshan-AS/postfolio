import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'recurring_deposit_model.freezed.dart';
part 'recurring_deposit_model.g.dart';

@freezed
sealed class RecurringDeposit with _$RecurringDeposit implements BaseDeposit {
  const RecurringDeposit._();

  const factory RecurringDeposit({
    required String id,
    required String serialNo,
    required String accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    required RecurringSchemeType schemeType,
    required DateTime startDate,
    String? linkedAutoDebitAccountNo,
    @Default([]) List<Nominee> nominees,
    @Default(DepositStatus.active) DepositStatus status,
  }) = _RecurringDeposit;

  @override
  InvestmentProjection get projection => ProjectionCalculator.calculateRD(
    monthlyInstallment: installmentAmount,
    interestRate: interestRate,
    startDate: startDate,
    termYears: termYears,
    termMonths: termMonths,
  );

  @override
  double get maturityAmount => projection.maturityAmount;

  @override
  DateTime get maturityDate => projection.maturityDate;

  factory RecurringDeposit.fromJson(Map<String, dynamic> json) =>
      _$RecurringDepositFromJson(json);

  static RecurringDeposit get dummy => RecurringDeposit(
    id: 'dummy',
    serialNo: 'RD12345',
    accountNo: 'Loading...',
    installmentAmount: 1000.0,
    termYears: 5,
    termMonths: 0,
    interestRate: 5.8,
    customerId: 'Loading Dummy Name...',
    schemeType: RecurringSchemeType.recurringDeposit,
    startDate: DateTime.now(),
  );

  // --- Domain Validation Rules ---

  static String? validateAccountNo(String? accountNo) =>
      BaseDeposit.validateAccountNo(accountNo);

  static String? validateAmount(double? amount, String fieldName) =>
      BaseDeposit.validateAmount(amount, fieldName);

  static String? validateTerm(int years, int months) =>
      BaseDeposit.validateTerm(years, months);

  static Result<RecurringDeposit, String> create({
    required String id,
    required String serialNo,
    required String accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    required RecurringSchemeType schemeType,
    required DateTime startDate,
    String? linkedAutoDebitAccountNo,
    List<Nominee> nominees = const [],
    DepositStatus status = DepositStatus.active,
  }) {
    final validationError =
        BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(installmentAmount, 'Installment amount') ??
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
      RecurringDeposit(
        id: id,
        serialNo: serialNo.trim(),
        accountNo: accountNo.trim(),
        installmentAmount: installmentAmount,
        termYears: termYears,
        termMonths: termMonths,
        interestRate: interestRate,
        customerId: customerId,
        schemeType: schemeType,
        startDate: startDate,
        linkedAutoDebitAccountNo: linkedAutoDebitAccountNo?.trim(),
        nominees: List.unmodifiable(nominees),
        status: status,
      ),
    );
  }
}
