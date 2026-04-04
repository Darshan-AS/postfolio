// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_deposit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringDeposit _$RecurringDepositFromJson(Map<String, dynamic> json) =>
    _RecurringDeposit(
      id: json['id'] as String,
      accountNo: json['accountNo'] as String,
      installmentAmount: (json['installmentAmount'] as num).toDouble(),
      termYears: (json['termYears'] as num).toInt(),
      termMonths: (json['termMonths'] as num).toInt(),
      interestRate: (json['interestRate'] as num).toDouble(),
      customerId: json['customerId'] as String,
      schemeId: json['schemeId'] as String,
      maturityAmount: (json['maturityAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      maturityDate: DateTime.parse(json['maturityDate'] as String),
      nominees:
          (json['nominees'] as List<dynamic>?)
              ?.map((e) => Nominee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RecurringDepositToJson(_RecurringDeposit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountNo': instance.accountNo,
      'installmentAmount': instance.installmentAmount,
      'termYears': instance.termYears,
      'termMonths': instance.termMonths,
      'interestRate': instance.interestRate,
      'customerId': instance.customerId,
      'schemeId': instance.schemeId,
      'maturityAmount': instance.maturityAmount,
      'startDate': instance.startDate.toIso8601String(),
      'maturityDate': instance.maturityDate.toIso8601String(),
      'nominees': instance.nominees,
    };
