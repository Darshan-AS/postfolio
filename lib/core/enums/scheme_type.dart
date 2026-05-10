import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

@JsonEnum()
enum OneTimeSchemeType {
  timeDeposit(shortName: 'TD'),
  monthlyIncomeScheme(shortName: 'MIS'),
  nationalSavingsCertificate(shortName: 'NSC'),
  kisanVikasPatra(shortName: 'KVP');

  final String shortName;

  const OneTimeSchemeType({required this.shortName});

  String get displayName => t.enums.oneTimeSchemeType[name] ?? name;
}

enum TenureInputType { singleFixed, fixedOptions, derived }

@JsonEnum()
enum RecurringSchemeType {
  recurringDeposit;

  String get displayName => t.enums.recurringSchemeType[name] ?? name;
}

extension RecurringSchemeRules on RecurringSchemeType {
  TenureInputType get tenureInputType => TenureInputType.singleFixed;

  List<int> get allowedTenuresInYears {
    switch (this) {
      case RecurringSchemeType.recurringDeposit:
        return [5];
    }
  }

  int get defaultTenureYears => allowedTenuresInYears.first;
}

extension OneTimeSchemeRules on OneTimeSchemeType {
  TenureInputType get tenureInputType {
    switch (this) {
      case OneTimeSchemeType.timeDeposit:
        return TenureInputType.fixedOptions;
      case OneTimeSchemeType.monthlyIncomeScheme:
      case OneTimeSchemeType.nationalSavingsCertificate:
        return TenureInputType.singleFixed;
      case OneTimeSchemeType.kisanVikasPatra:
        return TenureInputType.derived;
    }
  }

  List<int> get allowedTenuresInYears {
    switch (this) {
      case OneTimeSchemeType.timeDeposit:
        return [1, 2, 3, 5];
      case OneTimeSchemeType.monthlyIncomeScheme:
      case OneTimeSchemeType.nationalSavingsCertificate:
        return [5];
      case OneTimeSchemeType.kisanVikasPatra:
        return []; // Custom inputs used
    }
  }

  int get defaultTenureYears => tenureInputType == TenureInputType.derived ? 9 : allowedTenuresInYears.first;
}
