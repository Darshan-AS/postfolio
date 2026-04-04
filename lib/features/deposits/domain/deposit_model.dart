import 'package:freezed_annotation/freezed_annotation.dart';

part 'deposit_model.freezed.dart';
part 'deposit_model.g.dart';

@freezed
sealed class Nominee with _$Nominee {
  const Nominee._();

  const factory Nominee({
    required String name,
    required String relationship, // e.g., "Spouse", "Son"
    String? phone, // Optional, useful if the bank needs to contact them
  }) = _Nominee;

  factory Nominee.fromJson(Map<String, dynamic> json) =>
      _$NomineeFromJson(json);

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Nominee name is required';
    return null;
  }

  static String? validateRelationship(String? relation) {
    if (relation == null || relation.trim().isEmpty) return 'Relationship is required';
    return null;
  }

  static (String?, Nominee?) create({
    required String name,
    required String relationship,
    String? phone,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return (nameError, null);

    final relError = validateRelationship(relationship);
    if (relError != null) return (relError, null);

    return (
      null,
      Nominee(
        name: name.trim(),
        relationship: relationship.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      )
    );
  }
}

@freezed
sealed class Deposit with _$Deposit {
  const Deposit._();

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

  static String? validateAccountNo(String? accountNo) {
    if (accountNo == null || accountNo.trim().isEmpty) return 'Account number is required';
    return null;
  }

  static String? validateAmount(double? amount) {
    if (amount == null) return 'Amount is required';
    if (amount <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static (String?, Deposit?) create({
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
    final accountError = validateAccountNo(accountNo);
    if (accountError != null) return (accountError, null);

    final amountError = validateAmount(amount);
    if (amountError != null) return (amountError, null);

    if (termYears < 0 || termMonths < 0) {
      return ('Term cannot be negative', null);
    }

    if (maturityDate.isBefore(depositDate)) {
      return ('Maturity date cannot be before deposit date', null);
    }

    return (
      null,
      Deposit(
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
      )
    );
  }
}
