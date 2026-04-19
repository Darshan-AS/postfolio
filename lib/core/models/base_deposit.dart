import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/i18n/strings.g.dart';

abstract interface class BaseDeposit {
  String get id;
  String get accountNo;
  int get termYears;
  int get termMonths;
  double get interestRate;
  String get customerId;
  double get maturityAmount;
  DateTime get startDate;
  DateTime get maturityDate;
  List<Nominee> get nominees;
  DepositStatus get status;

  static String? validateAccountNo(String? accountNo) {
    if (accountNo == null || accountNo.trim().isEmpty) {
      return t.errors.requiredField(field: 'Account number');
    }
    return null;
  }

  static String? validateAmount(double? amount, String fieldName) {
    if (amount == null) return t.errors.requiredField(field: fieldName);
    if (amount <= 0) return t.errors.greaterThanZero(field: fieldName);
    return null;
  }

  static String? validateTerm(int years, int months) {
    if (years < 0 || months < 0) return t.errors.negativeTerm;
    return null;
  }

  static String? validateDates(DateTime startDate, DateTime maturityDate) {
    if (maturityDate.isBefore(startDate)) {
      return t.errors.invalidMaturityDate;
    }
    return null;
  }
}
