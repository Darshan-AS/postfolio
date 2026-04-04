import 'package:freezed_annotation/freezed_annotation.dart';

part 'nominee.freezed.dart';
part 'nominee.g.dart';

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
    if (relation == null || relation.trim().isEmpty) {
      return 'Relationship is required';
    }
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
      ),
    );
  }
}
