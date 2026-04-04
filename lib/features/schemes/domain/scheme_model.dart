import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheme_model.freezed.dart';
part 'scheme_model.g.dart';

@freezed
abstract class Scheme with _$Scheme {
  const factory Scheme({
    required String id,
    required String name,
    required bool isVariableTerm,
    @Default(0) int termYears,
    @Default(0) int termMonths,
    @Default(0.0) double baseInterestRate,
  }) = _Scheme;

  factory Scheme.fromJson(Map<String, dynamic> json) => _$SchemeFromJson(json);
}
