enum OneTimeSchemeType {
  timeDeposit(displayName: 'Time Deposit (TD)'),
  monthlyIncomeScheme(displayName: 'Monthly Income Scheme (MIS)'),
  nationalSavingsCertificate(displayName: 'National Savings Certificate (NSC)'),
  kisanVikasPatra(displayName: 'Kisan Vikas Patra (KVP)');

  final String displayName;

  const OneTimeSchemeType({required this.displayName});
}

enum RecurringSchemeType {
  recurringDeposit(displayName: 'Recurring Deposit (RD)');

  final String displayName;

  const RecurringSchemeType({required this.displayName});
}
