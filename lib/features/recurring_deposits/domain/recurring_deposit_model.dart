import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:postfolio/features/deposits/domain/deposit_model.dart';

part 'recurring_deposit_model.freezed.dart';
part 'recurring_deposit_model.g.dart';

@freezed
sealed class RecurringDeposit with _$RecurringDeposit {
  const RecurringDeposit._();

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

  static String? validateAccountNo(String? accountNo) {
    if (accountNo == null || accountNo.trim().isEmpty) return 'Account number is required';
    return null;
  }

  static String? validateInstallmentAmount(double? amount) {
    if (amount == null) return 'Installment amount is required';
    if (amount <= 0) return 'Installment amount must be greater than 0';
    return null;
  }

  static (String?, RecurringDeposit?) create({
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
    List<Nominee> nominees = const [],
  }) {
    final accountError = validateAccountNo(accountNo);
    if (accountError != null) return (accountError, null);

    final amountError = validateInstallmentAmount(installmentAmount);
    if (amountError != null) return (amountError, null);

    if (termYears < 0 || termMonths < 0) {
      return ('Term cannot be negative', null);
    }

    if (maturityDate.isBefore(startDate)) {
      return ('Maturity date cannot be before start date', null);
    }

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
        schemeId: schemeId,
        maturityAmount: maturityAmount,
        startDate: startDate,
        maturityDate: maturityDate,
        nominees: List.unmodifiable(nominees),
      )
    );
  }
}
