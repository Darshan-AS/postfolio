import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'nominee.freezed.dart';
part 'nominee.g.dart';

@JsonEnum(fieldRename: FieldRename.pascal)
enum NomineeRelationship {
  husband,
  wife,
  son,
  daughter,
  father,
  mother,
  brother,
  sister,
  grandfather,
  grandmother,
  grandson,
  granddaughter,
  fatherInLaw,
  motherInLaw,
  sonInLaw,
  daughterInLaw,
  brotherInLaw,
  sisterInLaw,
  nephew,
  niece,
  uncle,
  aunt,
  cousin,
  other;

  String get displayName => t.enums.nomineeRelationship[name] ?? name;
}

@freezed
sealed class Nominee with _$Nominee {
  const Nominee._();

  const factory Nominee({
    required String name,
    required NomineeRelationship relationship,
    String? customRelationship,
    required double percentage, // e.g., 50.0 for 50%
  }) = _Nominee;

  factory Nominee.fromJson(Map<String, dynamic> json) =>
      _$NomineeFromJson(json);

  String get displayRelationship => relationship == NomineeRelationship.other
      ? (customRelationship ?? t.enums.nomineeRelationship['other']!)
      : relationship.displayName;

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Nominee name is required';
    return null;
  }

  static String? validateCustomRelationship(
      NomineeRelationship relationship, String? customRelation) {
    if (relationship == NomineeRelationship.other) {
      if (customRelation == null || customRelation.trim().isEmpty) {
        return 'Custom relationship is required';
      }
    }
    return null;
  }

  static String? validatePercentage(double? percentage) {
    if (percentage == null) return 'Percentage is required';
    if (percentage <= 0 || percentage > 100) {
      return 'Percentage must be between 0 and 100';
    }
    return null;
  }

  static Result<Nominee, String> create({
    required String name,
    required NomineeRelationship relationship,
    String? customRelationship,
    required double percentage,
  }) {
    final error =
        validateName(name) ??
        validateCustomRelationship(relationship, customRelationship) ??
        validatePercentage(percentage);

    if (error != null) return Failure(error);

    return Success(
      Nominee(
        name: name.trim(),
        relationship: relationship,
        customRelationship: relationship == NomineeRelationship.other
            ? customRelationship?.trim()
            : null,
        percentage: percentage,
      ),
    );
  }
}
