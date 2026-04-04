// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nominee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Nominee _$NomineeFromJson(Map<String, dynamic> json) => _Nominee(
  name: json['name'] as String,
  relationship: json['relationship'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$NomineeToJson(_Nominee instance) => <String, dynamic>{
  'name': instance.name,
  'relationship': instance.relationship,
  'phone': instance.phone,
};
