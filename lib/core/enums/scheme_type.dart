import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum OneTimeSchemeType {
  @JsonValue('timeDeposit')
  timeDeposit(shortName: 'TD'),
  @JsonValue('monthlyIncomeScheme')
  monthlyIncomeScheme(shortName: 'MIS'),
  @JsonValue('nationalSavingsCertificate')
  nationalSavingsCertificate(shortName: 'NSC'),
  @JsonValue('kisanVikasPatra')
  kisanVikasPatra(shortName: 'KVP');

  final String shortName;

  const OneTimeSchemeType({required this.shortName});

  String get displayName {
    switch (this) {
      case OneTimeSchemeType.timeDeposit:
        return t.enums.oneTimeSchemeType.timeDeposit;
      case OneTimeSchemeType.monthlyIncomeScheme:
        return t.enums.oneTimeSchemeType.monthlyIncomeScheme;
      case OneTimeSchemeType.nationalSavingsCertificate:
        return t.enums.oneTimeSchemeType.nationalSavingsCertificate;
      case OneTimeSchemeType.kisanVikasPatra:
        return t.enums.oneTimeSchemeType.kisanVikasPatra;
    }
  }
}

enum RecurringSchemeType {
  @JsonValue('recurringDeposit')
  recurringDeposit;

  String get displayName {
    switch (this) {
      case RecurringSchemeType.recurringDeposit:
        return t.enums.recurringSchemeType.recurringDeposit;
    }
  }
}

extension RecurringSchemeRules on RecurringSchemeType {
  bool get isFixedTenure => true;

  List<int> get allowedTenuresInYears {
    switch (this) {
      case RecurringSchemeType.recurringDeposit:
        return [5];
    }
  }

  int get defaultTenureYears => allowedTenuresInYears.first;
}

extension OneTimeSchemeRules on OneTimeSchemeType {
  bool get isFixedTenure => this != OneTimeSchemeType.kisanVikasPatra;

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

  int get defaultTenureYears => isFixedTenure ? allowedTenuresInYears.first : 9;
}
