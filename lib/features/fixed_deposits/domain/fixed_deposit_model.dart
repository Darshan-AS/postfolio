import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';

part 'fixed_deposit_model.freezed.dart';
part 'fixed_deposit_model.g.dart';

@freezed
sealed class FixedDeposit with _$FixedDeposit implements BaseDeposit {
  const FixedDeposit._();

  const factory FixedDeposit({
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
  }) = _FixedDeposit;

  factory FixedDeposit.fromJson(Map<String, dynamic> json) =>
      _$FixedDepositFromJson(json);

  static (String?, FixedDeposit?) create({
    required String id,
    required String rowId,
    required String accountNo,
    required double amount,
    required int termYears,
    required int termMonths,
    double interestRate = 0.0,
    required String customerId,
    required String schemeId,
    required double maturityAmount,
    required DateTime depositDate,
    required DateTime maturityDate,
    List<Nominee> nominees = const [],
  }) {
    final accountError = BaseDeposit.validateAccountNo(accountNo);
    if (accountError != null) return (accountError, null);

    final amountError = BaseDeposit.validateAmount(amount, 'Amount');
    if (amountError != null) return (amountError, null);

    final termError = BaseDeposit.validateTerm(termYears, termMonths);
    if (termError != null) return (termError, null);

    final dateError = BaseDeposit.validateDates(depositDate, maturityDate);
    if (dateError != null) return (dateError, null);

    return (
      null,
      FixedDeposit(
        id: id,
        rowId: rowId,
        accountNo: accountNo.trim(),
        amount: amount,
        termYears: termYears,
        termMonths: termMonths,
        interestRate: interestRate,
        customerId: customerId,
        schemeId: schemeId,
        maturityAmount: maturityAmount,
        depositDate: depositDate,
        maturityDate: maturityDate,
        nominees: List.unmodifiable(nominees),
      ),
    );
  }
}
