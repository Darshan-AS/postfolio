import 'dart:math';

import 'package:postfolio/core/enums/payout_frequency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';

/// Pure utility class to calculate investment projections based on Post Office formulas.
class ProjectionCalculator {
  const ProjectionCalculator._();

  static const int _monthsInYear = 12;
  static const int _monthsInQuarter = 3;
  static const int _quartersInYear = 4;
  static const double _percentageDivisor = 100.0;

  /// Calculate projection for Recurring Deposit (RD)
  /// Compounding Frequency: Quarterly.
  static InvestmentProjection calculateRD({
    required double monthlyInstallment,
    required double interestRate,
    required DateTime startDate,
    required int termYears,
    required int termMonths,
    int defaultedMonths = 0,
  }) {
    final totalMonths = (termYears * _monthsInYear) + termMonths;
    final decimalInterestRate = interestRate / _percentageDivisor;
    final quarterlyInterestRate = decimalInterestRate / _quartersInYear;

    // RD Compounding Formula: M = sum(P * (1 + r/n)^(n*t_i))
    // t_i is the time in quarters the i-th deposit stays in the account
    final maturityAmount =
        List.generate(totalMonths, (index) {
          // totalMonths - index gives us months remaining for this deposit
          final monthsRemaining = totalMonths - index;
          final quartersRemaining = monthsRemaining / _monthsInQuarter;
          return monthlyInstallment *
              pow(1 + quarterlyInterestRate, quartersRemaining);
        }).fold<double>(
          0.0,
          (accumulatedTotal, installmentMaturity) =>
              accumulatedTotal + installmentMaturity,
        );

    final totalInvested = monthlyInstallment * totalMonths;
    final totalInterestEarned = maturityAmount - totalInvested;

    // RD maturity date is extended by defaults
    final maturityDate = DateTime(
      startDate.year,
      startDate.month + totalMonths + defaultedMonths,
      startDate.day,
    );

    return InvestmentProjection.wealthAccumulation(
      totalInvested: totalInvested,
      maturityAmount: maturityAmount,
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
    );
  }

  /// Calculate projection for Time Deposit (TD)
  /// Compounding Frequency: Quarterly, paid annually.
  static InvestmentProjection calculateTD({
    required double principal,
    required double interestRate,
    required DateTime startDate,
    required int termYears,
  }) {
    final decimalInterestRate = interestRate / _percentageDivisor;
    final quarterlyInterestRate = decimalInterestRate / _quartersInYear;

    // Annual Payout: P * [ (1 + r/n)^n - 1 ]
    final annualPayout =
        principal * (pow(1 + quarterlyInterestRate, _quartersInYear) - 1);
    final totalInterestEarned = annualPayout * termYears;

    final maturityDate = DateTime(
      startDate.year + termYears,
      startDate.month,
      startDate.day,
    );

    return InvestmentProjection.incomeGeneration(
      totalInvested: principal,
      maturityAmount: principal, // Principal is returned at maturity
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
      periodicPayoutAmount: annualPayout,
      payoutFrequency: PayoutFrequency.annually,
    );
  }

  /// Calculate projection for Monthly Income Scheme (MIS)
  /// Interest Type: Simple interest, paid monthly.
  static InvestmentProjection calculateMIS({
    required double principal,
    required double interestRate,
    required DateTime startDate,
    int termYears = 5, // MIS is typically fixed to 5 years
  }) {
    final decimalInterestRate = interestRate / _percentageDivisor;

    // Monthly Payout: P * (r / 12)
    final monthlyPayout = principal * (decimalInterestRate / _monthsInYear);
    final totalMonths = termYears * _monthsInYear;
    final totalInterestEarned = monthlyPayout * totalMonths;

    final maturityDate = DateTime(
      startDate.year + termYears,
      startDate.month,
      startDate.day,
    );

    return InvestmentProjection.incomeGeneration(
      totalInvested: principal,
      maturityAmount: principal, // Principal is returned at maturity
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
      periodicPayoutAmount: monthlyPayout,
      payoutFrequency: PayoutFrequency.monthly,
    );
  }

  /// Calculate projection for National Savings Certificate (NSC)
  /// Compounding Frequency: Annually.
  static InvestmentProjection calculateNSC({
    required double principal,
    required double interestRate,
    required DateTime startDate,
    int termYears = 5, // NSC is typically fixed to 5 years
  }) {
    final decimalInterestRate = interestRate / _percentageDivisor;

    // Maturity Amount: P * (1 + r)^t
    final maturityAmount = principal * pow(1 + decimalInterestRate, termYears);
    final totalInterestEarned = maturityAmount - principal;

    final maturityDate = DateTime(
      startDate.year + termYears,
      startDate.month,
      startDate.day,
    );

    return InvestmentProjection.wealthAccumulation(
      totalInvested: principal,
      maturityAmount: maturityAmount,
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
    );
  }

  /// Calculate projection for Kisan Vikas Patra (KVP)
  /// Maturity: Dynamic based on interest rate (Strictly doubles).
  static InvestmentProjection calculateKVP({
    required double principal,
    required double interestRate,
    required DateTime startDate,
  }) {
    // Principal strictly doubles
    final maturityAmount = principal * 2;
    final totalInterestEarned = principal;

    int timeInMonths = calculateKvpTermMonths(interestRate);

    final maturityDate = DateTime(
      startDate.year,
      startDate.month + timeInMonths,
      startDate.day,
    );

    final years = timeInMonths ~/ _monthsInYear;
    final months = timeInMonths % _monthsInYear;
    final durationNote = timeInMonths > 0
        ? '$years Years & $months Months'
        : null;

    return InvestmentProjection.wealthAccumulation(
      totalInvested: principal,
      maturityAmount: maturityAmount,
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
      note: durationNote,
    );
  }

  /// Calculates the time in months it takes to double at a given interest rate.
  static int calculateKvpTermMonths(double interestRate) {
    if (interestRate <= 0) return 0;
    final decimalInterestRate = interestRate / _percentageDivisor;
    final timeInYears = log(2) / log(1 + decimalInterestRate);
    return (timeInYears * _monthsInYear).round();
  }

  /// Helper to route One Time Deposits to the correct calculation
  static InvestmentProjection calculateOneTimeDeposit({
    required OneTimeSchemeType schemeType,
    required double principalAmount,
    required double interestRate,
    required DateTime startDate,
    required int termYears,
  }) => switch (schemeType) {
    OneTimeSchemeType.timeDeposit => calculateTD(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
    ),
    OneTimeSchemeType.monthlyIncomeScheme => calculateMIS(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
    ),
    OneTimeSchemeType.nationalSavingsCertificate => calculateNSC(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
    ),
    OneTimeSchemeType.kisanVikasPatra => calculateKVP(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
    ),
  };
}
