// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavingsAccount _$SavingsAccountFromJson(Map<String, dynamic> json) =>
    _SavingsAccount(
      accountNumber: json['accountNumber'] as String,
      nominees:
          (json['nominees'] as List<dynamic>?)
              ?.map((e) => Nominee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SavingsAccountToJson(_SavingsAccount instance) =>
    <String, dynamic>{
      'accountNumber': instance.accountNumber,
      'nominees': instance.nominees,
    };
