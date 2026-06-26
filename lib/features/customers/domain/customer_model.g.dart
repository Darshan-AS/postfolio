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
  cifNumber: json['cif_number'] as String?,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  aadhaarNumber: json['aadhaar_number'] as String?,
  panNumber: json['pan_number'] as String?,
  savingsAccount: json['savings_account'] == null
      ? null
      : SavingsAccount.fromJson(
          json['savings_account'] as Map<String, dynamic>,
        ),
  notes: json['notes'] as String?,
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  updatedAt: const TimestampConverter().fromJson(json['updated_at']),
  migrationSource: json['migration_source'] as String?,
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'cif_number': instance.cifNumber,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'aadhaar_number': instance.aadhaarNumber,
  'pan_number': instance.panNumber,
  'savings_account': instance.savingsAccount?.toJson(),
  'notes': instance.notes,
  'created_at': ?const TimestampConverter().toJson(instance.createdAt),
  'updated_at': ?const TimestampConverter().toJson(instance.updatedAt),
  'migration_source': ?instance.migrationSource,
};
