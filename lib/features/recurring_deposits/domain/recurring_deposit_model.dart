import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/utils/result.dart';

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
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedAutoDebitAccountNo,
    @Default([]) List<Nominee> nominees,
    @Default(DepositStatus.active) DepositStatus status,
  }) = _RecurringDeposit;

  factory RecurringDeposit.fromJson(Map<String, dynamic> json) =>
      _$RecurringDepositFromJson(json);

  // --- Domain Validation Rules ---

  static String? validateAccountNo(String? accountNo) =>
      BaseDeposit.validateAccountNo(accountNo);

  static String? validateAmount(double? amount, String fieldName) =>
      BaseDeposit.validateAmount(amount, fieldName);

  static String? validateTerm(int years, int months) =>
      BaseDeposit.validateTerm(years, months);

  static String? validateDates(DateTime startDate, DateTime maturityDate) =>
      BaseDeposit.validateDates(startDate, maturityDate);

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
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedAutoDebitAccountNo,
    List<Nominee> nominees = const [],
    DepositStatus status = DepositStatus.active,
  }) {
    final validationError = BaseDeposit.validateAccountNo(accountNo) ??
        BaseDeposit.validateAmount(installmentAmount, 'Installment amount') ??
        BaseDeposit.validateTerm(termYears, termMonths) ??
        BaseDeposit.validateDates(startDate, maturityDate);

    if (validationError != null) return Failure(validationError);

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
        maturityAmount: maturityAmount,
        startDate: startDate,
        maturityDate: maturityDate,
        linkedAutoDebitAccountNo: linkedAutoDebitAccountNo?.trim(),
        nominees: List.unmodifiable(nominees),
        status: status,
      ),
    );
  }
}
