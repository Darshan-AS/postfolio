import 'package:postfolio/core/models/nominee.dart';

abstract interface class BaseDeposit {
  String get id;
  String get accountNo;
  int get termYears;
  int get termMonths;
  double get interestRate;
  String get customerId;
  double get maturityAmount;
  DateTime get maturityDate;
  List<Nominee> get nominees;

  static String? validateAccountNo(String? accountNo) {
    if (accountNo == null || accountNo.trim().isEmpty) {
      return 'Account number is required';
    }
    return null;
  }

  static String? validateAmount(double? amount, String fieldName) {
    if (amount == null) return '$fieldName is required';
    if (amount <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  static String? validateTerm(int years, int months) {
    if (years < 0 || months < 0) return 'Term cannot be negative';
    return null;
  }

  static String? validateDates(DateTime startDate, DateTime maturityDate) {
    if (maturityDate.isBefore(startDate)) {
      return 'Maturity date cannot be before start date';
    }
    return null;
  }
}
