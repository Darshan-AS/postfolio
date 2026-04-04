import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class User with _$User {
  const User._(); // Added to allow custom methods/extensions on Freezed models

  const factory User({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

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
    if (!regex.hasMatch(phone.trim())) return 'Invalid phone number (7-15 digits)';
    return null;
  }

  // Smart Factory that enforces validation, returning a Record: (ErrorMessage?, ValidUser?)
  static (String?, User?) create({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return (nameError, null);

    final emailError = validateEmail(email);
    if (emailError != null) return (emailError, null);

    final phoneError = validatePhone(phone);
    if (phoneError != null) return (phoneError, null);

    return (
      null,
      User(
        id: id,
        name: name.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
      )
    );
  }
}
