import 'dart:math';

import 'package:postfolio/core/enums/payout_frequency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';

/// Pure utility class to calculate investment projections based on Post Office formulas.
class ProjectionCalculator {
  const ProjectionCalculator._();

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
    final totalMonths = (termYears * 12) + termMonths;

    // RD Compounding Formula: M = sum(P * (1 + r/400)^t_i)
    // t_i is the time in quarters the i-th deposit stays in the account
    final maturityAmount = List.generate(
      totalMonths,
      (index) {
        // totalMonths - index gives us months remaining for this deposit (from totalMonths down to 1)
        final quarters = (totalMonths - index) / 3.0;
        return monthlyInstallment * pow(1 + (interestRate / 400), quarters);
      },
    ).fold<double>(0.0, (sum, value) => sum + value);

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
    // Annual Payout: P * [ (1 + r/400)^4 - 1 ]
    final annualPayout = principal * (pow(1 + (interestRate / 400), 4) - 1);
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
    // Monthly Payout: P * (r/1200)
    final monthlyPayout = principal * (interestRate / 1200);
    final totalMonths = termYears * 12;
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
    // Maturity Amount: P * (1 + r/100)^5
    final maturityAmount = principal * pow(1 + (interestRate / 100), termYears);
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

    // Time to double: 2 = (1 + r/100)^t => t = ln(2) / ln(1 + r/100)
    final timeInYears = log(2) / log(1 + (interestRate / 100));
    final timeInMonths = (timeInYears * 12).round();

    final maturityDate = DateTime(
      startDate.year,
      startDate.month + timeInMonths,
      startDate.day,
    );

    return InvestmentProjection.wealthAccumulation(
      totalInvested: principal,
      maturityAmount: maturityAmount,
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
    );
  }

  /// Helper to route One Time Deposits to the correct calculation
  static InvestmentProjection calculateOneTimeDeposit({
    required OneTimeSchemeType schemeType,
    required double principalAmount,
    required double interestRate,
    required DateTime startDate,
    required int termYears,
  }) {
    switch (schemeType) {
      case OneTimeSchemeType.timeDeposit:
        return calculateTD(
          principal: principalAmount,
          interestRate: interestRate,
          startDate: startDate,
          termYears: termYears,
        );
      case OneTimeSchemeType.monthlyIncomeScheme:
        return calculateMIS(
          principal: principalAmount,
          interestRate: interestRate,
          startDate: startDate,
          termYears: termYears,
        );
      case OneTimeSchemeType.nationalSavingsCertificate:
        return calculateNSC(
          principal: principalAmount,
          interestRate: interestRate,
          startDate: startDate,
          termYears: termYears,
        );
      case OneTimeSchemeType.kisanVikasPatra:
        return calculateKVP(
          principal: principalAmount,
          interestRate: interestRate,
          startDate: startDate,
        );
    }
  }
}
