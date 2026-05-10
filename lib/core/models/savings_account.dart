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

  static Result<SavingsAccount, String> create({
    required String accountNumber,
    List<Nominee> nominees = const [],
  }) {
    // Functional validation chain
    final error =
        validateAccountNumber(accountNumber) ??
        (nominees.isNotEmpty ? Nominee.validateNominees(nominees) : null);

    if (error != null) return Failure(error);

    return Success(
      SavingsAccount(accountNumber: accountNumber.trim(), nominees: nominees),
    );
  }
}
