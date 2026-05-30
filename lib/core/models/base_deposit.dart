import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/i18n/strings.g.dart';

abstract interface class BaseDeposit {
  String get id;
  String get accountNo;
  int get termYears;
  int get termMonths;
  double get interestRate;
  String get customerId;
  DateTime get startDate;
  InvestmentProjection get projection;
  double get maturityAmount;
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

  static String? validateInterestRate(double? rate, String fieldName) {
    if (rate == null) return t.errors.requiredField(field: fieldName);
    if (rate <= 0) return t.errors.greaterThanZero(field: fieldName);
    if (rate > 100) {
      return t.errors.invalidInterestRate;
    }
    return null;
  }
}

extension BaseDepositMaturityUrgency on BaseDeposit {
  MaturityUrgency get maturityUrgency {
    if (status == DepositStatus.closed) {
      return MaturityUrgency.closed;
    }

    // Check if maturing within 30 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maturity = DateTime(
      maturityDate.year,
      maturityDate.month,
      maturityDate.day,
    );
    final daysUntilMaturity = maturity.difference(today).inDays;

    if (daysUntilMaturity >= 0 && daysUntilMaturity <= 30) {
      return MaturityUrgency.maturingSoon;
    }

    // If it's past maturity date
    if (daysUntilMaturity < 0 || status == DepositStatus.matured) {
      return MaturityUrgency.overdue;
    }

    return MaturityUrgency.normal;
  }

  String get maturityRelativeTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maturity = DateTime(
      maturityDate.year,
      maturityDate.month,
      maturityDate.day,
    );
    final daysUntilMaturity = maturity.difference(today).inDays;

    if (daysUntilMaturity == 0) {
      return t.enums.maturityRelativeTime.maturingToday;
    } else if (daysUntilMaturity > 0) {
      return t.enums.maturityRelativeTime.maturingIn(days: daysUntilMaturity);
    } else {
      return t.enums.maturityRelativeTime.maturedAgo(days: daysUntilMaturity.abs());
    }
  }
}
