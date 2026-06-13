// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  cifNumber: json['cifNumber'] as String?,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  aadhaarNumber: json['aadhaarNumber'] as String?,
  panNumber: json['panNumber'] as String?,
  savingsAccount: json['savingsAccount'] == null
      ? null
      : SavingsAccount.fromJson(json['savingsAccount'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
  migrationSource: json['migrationSource'] as String?,
  isDeleted: json['isDeleted'] as bool? ?? false,
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'cifNumber': instance.cifNumber,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
  'aadhaarNumber': instance.aadhaarNumber,
  'panNumber': instance.panNumber,
  'savingsAccount': instance.savingsAccount?.toJson(),
  'notes': instance.notes,
  'createdAt': ?const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': ?const TimestampConverter().toJson(instance.updatedAt),
  'migrationSource': ?instance.migrationSource,
  'isDeleted': instance.isDeleted,
};
