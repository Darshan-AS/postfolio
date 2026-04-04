import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/savings_account.dart';

part 'customer_model.freezed.dart';
part 'customer_model.g.dart';

@freezed
sealed class Customer with _$Customer {
  const Customer._(); // Added to allow custom methods/extensions on Freezed models

  const factory Customer({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? cifNumber,
    DateTime? dateOfBirth,
    String? aadhaarNumber,
    String? panNumber,
    SavingsAccount? savingsAccount,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

  // --- Domain Validation Rules ---

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Name is required';
    if (name.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null; // Optional field
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email.trim())) return 'Invalid email format';
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null; // Optional field
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(phone.trim())) {
      return 'Invalid phone number (7-15 digits)';
    }
    return null;
  }

  // Smart Factory that enforces validation, returning a Record: (ErrorMessage?, ValidUser?)
  static (String?, Customer?) create({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? cifNumber,
    DateTime? dateOfBirth,
    String? aadhaarNumber,
    String? panNumber,
    String? savingsAccountNumber,
    String? savingsNomineeName,
    String? savingsNomineeRelationship,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return (nameError, null);

    final emailError = validateEmail(email);
    if (emailError != null) return (emailError, null);

    final phoneError = validatePhone(phone);
    if (phoneError != null) return (phoneError, null);

    SavingsAccount? savingsAccount;
    if (savingsAccountNumber != null && savingsAccountNumber.trim().isNotEmpty) {
      final (accErr, acc) = SavingsAccount.create(
        accountNumber: savingsAccountNumber,
        nomineeName: savingsNomineeName,
        nomineeRelationship: savingsNomineeRelationship,
      );
      if (accErr != null) return (accErr, null);
      savingsAccount = acc;
    } else if ((savingsNomineeName != null && savingsNomineeName.trim().isNotEmpty) ||
        (savingsNomineeRelationship != null &&
            savingsNomineeRelationship.trim().isNotEmpty)) {
      return ('Savings Account Number is required to add a nominee', null);
    }

    return (
      null,
      Customer(
        id: id,
        name: name.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        cifNumber: cifNumber?.trim().isEmpty == true ? null : cifNumber?.trim(),
        dateOfBirth: dateOfBirth,
        aadhaarNumber: aadhaarNumber?.trim().isEmpty == true ? null : aadhaarNumber?.trim(),
        panNumber: panNumber?.trim().isEmpty == true ? null : panNumber?.trim(),
        savingsAccount: savingsAccount,
      ),
    );
  }
}
