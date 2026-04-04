// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_deposit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FixedDeposit _$FixedDepositFromJson(Map<String, dynamic> json) =>
    _FixedDeposit(
      id: json['id'] as String,
      rowId: json['rowId'] as String,
      accountNo: json['accountNo'] as String,
      amount: (json['amount'] as num).toDouble(),
      termYears: (json['termYears'] as num).toInt(),
      termMonths: (json['termMonths'] as num).toInt(),
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customerId'] as String,
      schemeId: json['schemeId'] as String,
      maturityAmount: (json['maturityAmount'] as num).toDouble(),
      depositDate: DateTime.parse(json['depositDate'] as String),
      maturityDate: DateTime.parse(json['maturityDate'] as String),
      nominees:
          (json['nominees'] as List<dynamic>?)
              ?.map((e) => Nominee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FixedDepositToJson(_FixedDeposit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rowId': instance.rowId,
      'accountNo': instance.accountNo,
      'amount': instance.amount,
      'termYears': instance.termYears,
      'termMonths': instance.termMonths,
      'interestRate': instance.interestRate,
      'customerId': instance.customerId,
      'schemeId': instance.schemeId,
      'maturityAmount': instance.maturityAmount,
      'depositDate': instance.depositDate.toIso8601String(),
      'maturityDate': instance.maturityDate.toIso8601String(),
      'nominees': instance.nominees,
    };
