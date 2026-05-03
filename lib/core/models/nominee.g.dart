// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nominee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Nominee _$NomineeFromJson(Map<String, dynamic> json) => _Nominee(
  name: json['name'] as String,
  relationship: $enumDecode(_$NomineeRelationshipEnumMap, json['relationship']),
  customRelationship: json['customRelationship'] as String?,
  percentage: (json['percentage'] as num).toDouble(),
);

Map<String, dynamic> _$NomineeToJson(_Nominee instance) => <String, dynamic>{
  'name': instance.name,
  'relationship': _$NomineeRelationshipEnumMap[instance.relationship]!,
  'customRelationship': instance.customRelationship,
  'percentage': instance.percentage,
};

const _$NomineeRelationshipEnumMap = {
  NomineeRelationship.husband: 'Husband',
  NomineeRelationship.wife: 'Wife',
  NomineeRelationship.son: 'Son',
  NomineeRelationship.daughter: 'Daughter',
  NomineeRelationship.father: 'Father',
  NomineeRelationship.mother: 'Mother',
  NomineeRelationship.brother: 'Brother',
  NomineeRelationship.sister: 'Sister',
  NomineeRelationship.grandfather: 'Grandfather',
  NomineeRelationship.grandmother: 'Grandmother',
  NomineeRelationship.grandson: 'Grandson',
  NomineeRelationship.granddaughter: 'Granddaughter',
  NomineeRelationship.fatherInLaw: 'FatherInLaw',
  NomineeRelationship.motherInLaw: 'MotherInLaw',
  NomineeRelationship.sonInLaw: 'SonInLaw',
  NomineeRelationship.daughterInLaw: 'DaughterInLaw',
  NomineeRelationship.brotherInLaw: 'BrotherInLaw',
  NomineeRelationship.sisterInLaw: 'SisterInLaw',
  NomineeRelationship.nephew: 'Nephew',
  NomineeRelationship.niece: 'Niece',
  NomineeRelationship.uncle: 'Uncle',
  NomineeRelationship.aunt: 'Aunt',
  NomineeRelationship.cousin: 'Cousin',
  NomineeRelationship.other: 'Other',
};
