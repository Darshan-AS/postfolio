// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_deposit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OneTimeDeposit _$OneTimeDepositFromJson(Map<String, dynamic> json) =>
    _OneTimeDeposit(
      id: json['id'] as String,
      accountNo: json['account_no'] as String?,
      principalAmount: (json['principal_amount'] as num).toDouble(),
      termYears: (json['term_years'] as num).toInt(),
      termMonths: (json['term_months'] as num).toInt(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      customerId: json['customer_id'] as String,
      schemeType: $enumDecode(_$OneTimeSchemeTypeEnumMap, json['scheme_type']),
      startDate: DateTime.parse(json['start_date'] as String),
      nominees:
          (json['nominees'] as List<dynamic>?)
              ?.map((e) => Nominee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status:
          $enumDecodeNullable(_$DepositStatusEnumMap, json['status']) ??
          DepositStatus.active,
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      migrationSource: json['migration_source'] as String?,
    );

Map<String, dynamic> _$OneTimeDepositToJson(_OneTimeDeposit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_no': instance.accountNo,
      'principal_amount': instance.principalAmount,
      'term_years': instance.termYears,
      'term_months': instance.termMonths,
      'interest_rate': instance.interestRate,
      'customer_id': instance.customerId,
      'scheme_type': _$OneTimeSchemeTypeEnumMap[instance.schemeType]!,
      'start_date': instance.startDate.toIso8601String(),
      'nominees': instance.nominees.map((e) => e.toJson()).toList(),
      'status': _$DepositStatusEnumMap[instance.status]!,
      'created_at': ?const TimestampConverter().toJson(instance.createdAt),
      'updated_at': ?const TimestampConverter().toJson(instance.updatedAt),
      'migration_source': ?instance.migrationSource,
    };

const _$OneTimeSchemeTypeEnumMap = {
  OneTimeSchemeType.timeDeposit: 'timeDeposit',
  OneTimeSchemeType.monthlyIncomeScheme: 'monthlyIncomeScheme',
  OneTimeSchemeType.nationalSavingsCertificate: 'nationalSavingsCertificate',
  OneTimeSchemeType.kisanVikasPatra: 'kisanVikasPatra',
};

const _$DepositStatusEnumMap = {
  DepositStatus.active: 'active',
  DepositStatus.closed: 'closed',
};
