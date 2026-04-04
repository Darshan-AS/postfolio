import 'package:freezed_annotation/freezed_annotation.dart';

enum OneTimeSchemeType {
  @JsonValue('timeDeposit')
  timeDeposit(displayName: 'Time Deposit (TD)'),
  @JsonValue('monthlyIncomeScheme')
  monthlyIncomeScheme(displayName: 'Monthly Income Scheme (MIS)'),
  @JsonValue('nationalSavingsCertificate')
  nationalSavingsCertificate(displayName: 'National Savings Certificate (NSC)'),
  @JsonValue('kisanVikasPatra')
  kisanVikasPatra(displayName: 'Kisan Vikas Patra (KVP)');

  final String displayName;

  const OneTimeSchemeType({required this.displayName});
}

enum RecurringSchemeType {
  @JsonValue('recurringDeposit')
  recurringDeposit(displayName: 'Recurring Deposit (RD)');

  final String displayName;

  const RecurringSchemeType({required this.displayName});
}
