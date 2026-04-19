import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

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

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  // --- Domain Validation Rules ---

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return t.errors.requiredField(field: 'Name');
    }
    if (name.trim().length < 2) {
      return t.errors.minLength(field: 'Name', count: 2);
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null; // Optional field
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email.trim())) return t.errors.invalidEmail;
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null; // Optional field
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(phone.trim())) {
      return t.errors.invalidPhone;
    }
    return null;
  }

  // Smart Factory that enforces validation, returning a Result for pure functional error handling
  static Result<Customer, String> create({
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
    List<Nominee>? savingsNominees,
  }) {
    // Pure helper to sanitize optional strings
    String? clean(String? s) => s?.trim().isEmpty == true ? null : s?.trim();

    // 1. Evaluate all base validations using a null-coalescing chain for fail-fast execution
    final validationError = validateName(name) ??
        validateEmail(email) ??
        validatePhone(phone) ??
        (clean(savingsAccountNumber) == null && (savingsNominees?.isNotEmpty ?? false)
            ? t.errors.sbAccountRequiredForNominee
            : null);

    if (validationError != null) return Failure(validationError);

    // 2. Handle nested entities using pattern matching on the Result type
    SavingsAccount? savingsAccount;
    if (clean(savingsAccountNumber) != null) {
      final accResult = SavingsAccount.create(
        accountNumber: savingsAccountNumber!,
        nominees: savingsNominees ?? const [],
      );

      switch (accResult) {
        case Failure(error: final err):
          return Failure(err);
        case Success(value: final acc):
          savingsAccount = acc;
      }
    }

    // 3. Construct and return the sanitized, immutable object
    return Success(
      Customer(
        id: id,
        name: name.trim(),
        email: clean(email),
        phone: clean(phone),
        address: clean(address),
        cifNumber: clean(cifNumber),
        dateOfBirth: dateOfBirth,
        aadhaarNumber: clean(aadhaarNumber),
        panNumber: clean(panNumber),
        savingsAccount: savingsAccount,
      ),
    );
  }
}
