// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scheme _$SchemeFromJson(Map<String, dynamic> json) => _Scheme(
  id: json['id'] as String,
  name: json['name'] as String,
  isVariableTerm: json['isVariableTerm'] as bool,
  termYears: (json['termYears'] as num?)?.toInt() ?? 0,
  termMonths: (json['termMonths'] as num?)?.toInt() ?? 0,
  baseInterestRate: (json['baseInterestRate'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$SchemeToJson(_Scheme instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'isVariableTerm': instance.isVariableTerm,
  'termYears': instance.termYears,
  'termMonths': instance.termMonths,
  'baseInterestRate': instance.baseInterestRate,
};
