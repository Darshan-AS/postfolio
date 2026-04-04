import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/nominee.dart';

part 'savings_account.freezed.dart';
part 'savings_account.g.dart';

@freezed
sealed class SavingsAccount with _$SavingsAccount {
  const SavingsAccount._();

  const factory SavingsAccount({
    required String accountNumber,
    Nominee? nominee,
  }) = _SavingsAccount;

  factory SavingsAccount.fromJson(Map<String, dynamic> json) =>
      _$SavingsAccountFromJson(json);

  static String? validateAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.trim().isEmpty) {
      return 'Account number is required';
    }
    return null;
  }

  static (String?, SavingsAccount?) create({
    required String accountNumber,
    String? nomineeName,
    String? nomineeRelationship,
  }) {
    final accError = validateAccountNumber(accountNumber);
    if (accError != null) return (accError, null);

    Nominee? nominee;
    final hasNomineeName =
        nomineeName != null && nomineeName.trim().isNotEmpty;
    final hasNomineeRel =
        nomineeRelationship != null && nomineeRelationship.trim().isNotEmpty;

    if (hasNomineeName || hasNomineeRel) {
      final (nomError, nom) = Nominee.create(
        name: nomineeName ?? '',
        relationship: nomineeRelationship ?? '',
      );
      if (nomError != null) return (nomError, null);
      nominee = nom;
    }

    return (
      null,
      SavingsAccount(
        accountNumber: accountNumber.trim(),
        nominee: nominee,
      ),
    );
  }
}
