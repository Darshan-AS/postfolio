// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_deposit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OneTimeDeposit _$OneTimeDepositFromJson(Map<String, dynamic> json) =>
    _OneTimeDeposit(
      id: json['id'] as String,
      rowId: json['rowId'] as String,
      accountNo: json['accountNo'] as String,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      termYears: (json['termYears'] as num).toInt(),
      termMonths: (json['termMonths'] as num).toInt(),
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customerId'] as String,
      schemeType: $enumDecode(_$OneTimeSchemeTypeEnumMap, json['schemeType']),
      maturityAmount: (json['maturityAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      maturityDate: DateTime.parse(json['maturityDate'] as String),
      linkedSavingsAccountNo: json['linkedSavingsAccountNo'] as String?,
      nominees:
          (json['nominees'] as List<dynamic>?)
              ?.map((e) => Nominee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OneTimeDepositToJson(_OneTimeDeposit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rowId': instance.rowId,
      'accountNo': instance.accountNo,
      'principalAmount': instance.principalAmount,
      'termYears': instance.termYears,
      'termMonths': instance.termMonths,
      'interestRate': instance.interestRate,
      'customerId': instance.customerId,
      'schemeType': _$OneTimeSchemeTypeEnumMap[instance.schemeType]!,
      'maturityAmount': instance.maturityAmount,
      'startDate': instance.startDate.toIso8601String(),
      'maturityDate': instance.maturityDate.toIso8601String(),
      'linkedSavingsAccountNo': instance.linkedSavingsAccountNo,
      'nominees': instance.nominees,
    };

const _$OneTimeSchemeTypeEnumMap = {
  OneTimeSchemeType.timeDeposit: 'timeDeposit',
  OneTimeSchemeType.monthlyIncomeScheme: 'monthlyIncomeScheme',
  OneTimeSchemeType.nationalSavingsCertificate: 'nationalSavingsCertificate',
  OneTimeSchemeType.kisanVikasPatra: 'kisanVikasPatra',
};
