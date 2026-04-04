import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';

part 'recurring_deposit_model.freezed.dart';
part 'recurring_deposit_model.g.dart';

@freezed
sealed class RecurringDeposit with _$RecurringDeposit implements BaseDeposit {
  const RecurringDeposit._();

  const factory RecurringDeposit({
    required String id,
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
  }) = _RecurringDeposit;

  factory RecurringDeposit.fromJson(Map<String, dynamic> json) =>
      _$RecurringDepositFromJson(json);

  static (String?, RecurringDeposit?) create({
    required String id,
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
  }) {
    final accountError = BaseDeposit.validateAccountNo(accountNo);
    if (accountError != null) return (accountError, null);

    final amountError = BaseDeposit.validateAmount(
      installmentAmount,
      'Installment amount',
    );
    if (amountError != null) return (amountError, null);

    final termError = BaseDeposit.validateTerm(termYears, termMonths);
    if (termError != null) return (termError, null);

    final dateError = BaseDeposit.validateDates(startDate, maturityDate);
    if (dateError != null) return (dateError, null);

    return (
      null,
      RecurringDeposit(
        id: id,
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
      ),
    );
  }
}
