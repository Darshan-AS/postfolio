import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheme_model.freezed.dart';
part 'scheme_model.g.dart';

@freezed
sealed class Scheme with _$Scheme {
  const Scheme._();

  const factory Scheme({
    required String id,
    required String name,
    required bool isVariableTerm,
    @Default(0) int termYears,
    @Default(0) int termMonths,
    @Default(0.0) double baseInterestRate,
  }) = _Scheme;

  factory Scheme.fromJson(Map<String, dynamic> json) => _$SchemeFromJson(json);

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Scheme name is required';
    if (name.trim().length < 2) {
      return 'Scheme name must be at least 2 characters';
    }
    return null;
  }

  static String? validateTerm(
    bool isVariableTerm,
    int termYears,
    int termMonths,
  ) {
    if (!isVariableTerm && termYears == 0 && termMonths == 0) {
      return 'Fixed term schemes must specify a term greater than 0';
    }
    if (termYears < 0 || termMonths < 0) return 'Term cannot be negative';
    return null;
  }

  static String? validateInterestRate(double? rate) {
    if (rate == null) return 'Interest rate is required';
    if (rate < 0 || rate > 100) {
      return 'Interest rate must be between 0 and 100';
    }
    return null;
  }

  static (String?, Scheme?) create({
    required String id,
    required String name,
    required bool isVariableTerm,
    int termYears = 0,
    int termMonths = 0,
    double baseInterestRate = 0.0,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return (nameError, null);

    final termError = validateTerm(isVariableTerm, termYears, termMonths);
    if (termError != null) return (termError, null);

    final rateError = validateInterestRate(baseInterestRate);
    if (rateError != null) return (rateError, null);

    return (
      null,
      Scheme(
        id: id,
        name: name.trim(),
        isVariableTerm: isVariableTerm,
        termYears: termYears,
        termMonths: termMonths,
        baseInterestRate: baseInterestRate,
      ),
    );
  }
}
