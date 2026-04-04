// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavingsAccount _$SavingsAccountFromJson(Map<String, dynamic> json) =>
    _SavingsAccount(
      accountNumber: json['accountNumber'] as String,
      nominee: json['nominee'] == null
          ? null
          : Nominee.fromJson(json['nominee'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SavingsAccountToJson(_SavingsAccount instance) =>
    <String, dynamic>{
      'accountNumber': instance.accountNumber,
      'nominee': instance.nominee,
    };
