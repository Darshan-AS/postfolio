import 'package:freezed_annotation/freezed_annotation.dart';

part 'postal_scheme_terms.freezed.dart';

/// Immutable value object representing the official Post Office interest rate
/// and tenure for a scheme on a given investment start date.
@freezed
sealed class PostalSchemeTerms with _$PostalSchemeTerms {
  const PostalSchemeTerms._();

  const factory PostalSchemeTerms({
    required double interestRate,
    required int termYears,
    @Default(0) int termMonths,
  }) = _PostalSchemeTerms;

  int get totalMonths => (termYears * 12) + termMonths;
}
