import 'package:freezed_annotation/freezed_annotation.dart';

enum OneTimeSchemeType {
  @JsonValue('timeDeposit')
  timeDeposit(displayName: 'Time Deposit (TD)', shortName: 'TD'),
  @JsonValue('monthlyIncomeScheme')
  monthlyIncomeScheme(
    displayName: 'Monthly Income Scheme (MIS)',
    shortName: 'MIS',
  ),
  @JsonValue('nationalSavingsCertificate')
  nationalSavingsCertificate(
    displayName: 'National Savings Certificate (NSC)',
    shortName: 'NSC',
  ),
  @JsonValue('kisanVikasPatra')
  kisanVikasPatra(displayName: 'Kisan Vikas Patra (KVP)', shortName: 'KVP');

  final String displayName;
  final String shortName;

  const OneTimeSchemeType({required this.displayName, required this.shortName});
}

enum RecurringSchemeType {
  @JsonValue('recurringDeposit')
  recurringDeposit(displayName: 'Recurring Deposit (RD)');

  final String displayName;

  const RecurringSchemeType({required this.displayName});
}
