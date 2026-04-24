import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
      return t.errors.requiredField(field: 'Account number');
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

  static Result<SavingsAccount, String> create({
    required String accountNumber,
    List<Nominee> nominees = const [],
  }) {
    // Functional validation chain
    final error =
        validateAccountNumber(accountNumber) ??
        (nominees.isNotEmpty ? validateNominees(nominees) : null);

    if (error != null) return Failure(error);

    return Success(
      SavingsAccount(accountNumber: accountNumber.trim(), nominees: nominees),
    );
  }
}
