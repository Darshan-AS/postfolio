import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/nominee.dart';

part 'savings_account.freezed.dart';
part 'savings_account.g.dart';

@freezed
sealed class SavingsAccount with _$SavingsAccount {
  const SavingsAccount._();

  const factory SavingsAccount({
    required String accountNumber,
    @Default([]) List<Nominee> nominees,
  }) = _SavingsAccount;

  factory SavingsAccount.fromJson(Map<String, dynamic> json) =>
      _$SavingsAccountFromJson(json);

  static String? validateAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.trim().isEmpty) {
      return 'Account number is required';
    }
    return null;
  }

  static String? validateNominees(List<Nominee> nominees) {
    if (nominees.isEmpty) return null; // Valid if empty

    double totalPercentage = 0;
    for (final n in nominees) {
      totalPercentage += n.percentage;
    }
    if (totalPercentage != 100.0) {
      return 'Total nominee percentage must be exactly 100%';
    }
    return null;
  }

  static (String?, SavingsAccount?) create({
    required String accountNumber,
    List<Nominee> nominees = const [],
  }) {
    final accError = validateAccountNumber(accountNumber);
    if (accError != null) return (accError, null);

    if (nominees.isNotEmpty) {
      final nomError = validateNominees(nominees);
      if (nomError != null) return (nomError, null);
    }

    return (
      null,
      SavingsAccount(accountNumber: accountNumber.trim(), nominees: nominees),
    );
  }
}
