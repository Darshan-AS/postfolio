// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_deposit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringDeposit _$RecurringDepositFromJson(Map<String, dynamic> json) =>
    _RecurringDeposit(
      id: json['id'] as String,
      serialNo: json['serial_no'] as String?,
      accountNo: json['account_no'] as String?,
      installmentAmount: (json['installment_amount'] as num).toDouble(),
      termYears: (json['term_years'] as num).toInt(),
      termMonths: (json['term_months'] as num).toInt(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      customerId: json['customer_id'] as String,
      schemeType: $enumDecode(
        _$RecurringSchemeTypeEnumMap,
        json['scheme_type'],
      ),
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

Map<String, dynamic> _$RecurringDepositToJson(_RecurringDeposit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serial_no': instance.serialNo,
      'account_no': instance.accountNo,
      'installment_amount': instance.installmentAmount,
      'term_years': instance.termYears,
      'term_months': instance.termMonths,
      'interest_rate': instance.interestRate,
      'customer_id': instance.customerId,
      'scheme_type': _$RecurringSchemeTypeEnumMap[instance.schemeType]!,
      'start_date': instance.startDate.toIso8601String(),
      'nominees': instance.nominees.map((e) => e.toJson()).toList(),
      'status': _$DepositStatusEnumMap[instance.status]!,
      'created_at': ?const TimestampConverter().toJson(instance.createdAt),
      'updated_at': ?const TimestampConverter().toJson(instance.updatedAt),
      'migration_source': ?instance.migrationSource,
    };

const _$RecurringSchemeTypeEnumMap = {
  RecurringSchemeType.recurringDeposit: 'recurringDeposit',
};

const _$DepositStatusEnumMap = {
  DepositStatus.active: 'active',
  DepositStatus.closed: 'closed',
};
