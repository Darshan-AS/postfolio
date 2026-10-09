import 'dart:math';

import 'package:postfolio/core/enums/payout_frequency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';

/// Pure utility class to calculate investment projections based on Post Office formulas.
class ProjectionCalculator {
  const ProjectionCalculator._();

  static const int _monthsInYear = 12;
  static const int _monthsInQuarter = 3;
  static const int _quartersInYear = 4;
  static const double _percentageDivisor = 100.0;
  static const PostalRateService _postalRateService = PostalRateService();

  /// Calculate projection for Recurring Deposit (RD)
  /// Compounding Frequency: Quarterly.
  static InvestmentProjection calculateRD({
    required double monthlyInstallment,
    required DateTime startDate,
    double? interestRate,
    int? termYears,
    int? termMonths,
    int defaultedMonths = 0,
    PostalRateService postalRateService = _postalRateService,
  }) {
    final postalTerms = postalRateService.resolveRecurringSchemeTerms(
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: startDate,
    );
    final resolvedRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;
    final resolvedYears = (termYears != null && termYears > 0)
        ? termYears
        : postalTerms.termYears;
    final resolvedMonths = termMonths ?? postalTerms.termMonths;

    final totalMonths = (resolvedYears * _monthsInYear) + resolvedMonths;
    final decimalInterestRate = resolvedRate / _percentageDivisor;
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
      interestRate: resolvedRate,
      termYears: resolvedYears,
      termMonths: resolvedMonths,
    );
  }

  /// Calculate projection for Time Deposit (TD)
  /// Compounding Frequency: Quarterly, paid annually.
  static InvestmentProjection calculateTD({
    required double principal,
    required DateTime startDate,
    required int termYears,
    double? interestRate,
    PostalRateService postalRateService = _postalRateService,
  }) {
    final postalTerms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: OneTimeSchemeType.timeDeposit,
      startDate: startDate,
      tdTenureYears: termYears,
    );
    final resolvedRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;

    final decimalInterestRate = resolvedRate / _percentageDivisor;
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
      interestRate: resolvedRate,
      termYears: termYears,
    );
  }

  /// Calculate projection for Monthly Income Scheme (MIS)
  /// Interest Type: Simple interest, paid monthly.
  static InvestmentProjection calculateMIS({
    required double principal,
    required DateTime startDate,
    double? interestRate,
    int? termYears,
    PostalRateService postalRateService = _postalRateService,
  }) {
    final postalTerms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: OneTimeSchemeType.monthlyIncomeScheme,
      startDate: startDate,
    );
    final resolvedRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;
    final resolvedYears = (termYears != null && termYears > 0)
        ? termYears
        : postalTerms.termYears;

    final decimalInterestRate = resolvedRate / _percentageDivisor;

    // Monthly Payout: P * (r / 12)
    final monthlyPayout = principal * (decimalInterestRate / _monthsInYear);
    final totalMonths = resolvedYears * _monthsInYear;
    final totalInterestEarned = monthlyPayout * totalMonths;

    final maturityDate = DateTime(
      startDate.year + resolvedYears,
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
      interestRate: resolvedRate,
      termYears: resolvedYears,
    );
  }

  /// Calculate projection for National Savings Certificate (NSC)
  /// Compounding Frequency: Annually.
  static InvestmentProjection calculateNSC({
    required double principal,
    required DateTime startDate,
    double? interestRate,
    int? termYears,
    PostalRateService postalRateService = _postalRateService,
  }) {
    final postalTerms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: OneTimeSchemeType.nationalSavingsCertificate,
      startDate: startDate,
    );
    final resolvedRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;
    final resolvedYears = (termYears != null && termYears > 0)
        ? termYears
        : postalTerms.termYears;

    final decimalInterestRate = resolvedRate / _percentageDivisor;

    // Maturity Amount: P * (1 + r)^t
    final maturityAmount =
        principal * pow(1 + decimalInterestRate, resolvedYears);
    final totalInterestEarned = maturityAmount - principal;

    final maturityDate = DateTime(
      startDate.year + resolvedYears,
      startDate.month,
      startDate.day,
    );

    return InvestmentProjection.wealthAccumulation(
      totalInvested: principal,
      maturityAmount: maturityAmount,
      totalInterestEarned: totalInterestEarned,
      maturityDate: maturityDate,
      interestRate: resolvedRate,
      termYears: resolvedYears,
    );
  }

  /// Calculate projection for Kisan Vikas Patra (KVP)
  /// Maturity: Dynamic based on Post Office circular schedule or interest rate (Strictly doubles).
  static InvestmentProjection calculateKVP({
    required double principal,
    required DateTime startDate,
    double? interestRate,
    int? termYears,
    int? termMonths,
    PostalRateService postalRateService = _postalRateService,
  }) {
    final postalTerms = postalRateService.resolveOneTimeSchemeTerms(
      schemeType: OneTimeSchemeType.kisanVikasPatra,
      startDate: startDate,
    );
    final resolvedRate = (interestRate != null && interestRate > 0)
        ? interestRate
        : postalTerms.interestRate;

    // Principal strictly doubles
    final maturityAmount = principal * 2;
    final totalInterestEarned = principal;

    final providedMonths =
        ((termYears ?? 0) * _monthsInYear) + (termMonths ?? 0);
    final timeInMonths = providedMonths > 0
        ? providedMonths
        : postalRateService.calculateKvpTermMonths(
            resolvedRate,
            startDate: startDate,
          );

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
      interestRate: resolvedRate,
      termYears: years,
      termMonths: months,
      note: durationNote,
    );
  }

  /// Calculates the official Post Office KVP doubling tenure in months.
  static int calculateKvpTermMonths(
    double interestRate, {
    DateTime? startDate,
    PostalRateService postalRateService = _postalRateService,
  }) {
    return postalRateService.calculateKvpTermMonths(
      interestRate,
      startDate: startDate,
    );
  }

  /// Helper to route One Time Deposits to the correct calculation
  static InvestmentProjection calculateOneTimeDeposit({
    required OneTimeSchemeType schemeType,
    required double principalAmount,
    required DateTime startDate,
    double? interestRate,
    int? termYears,
    int? termMonths,
    PostalRateService postalRateService = _postalRateService,
  }) => switch (schemeType) {
    OneTimeSchemeType.timeDeposit => calculateTD(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears ?? OneTimeSchemeType.timeDeposit.defaultTenureYears,
      postalRateService: postalRateService,
    ),
    OneTimeSchemeType.monthlyIncomeScheme => calculateMIS(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
      postalRateService: postalRateService,
    ),
    OneTimeSchemeType.nationalSavingsCertificate => calculateNSC(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
      postalRateService: postalRateService,
    ),
    OneTimeSchemeType.kisanVikasPatra => calculateKVP(
      principal: principalAmount,
      interestRate: interestRate,
      startDate: startDate,
      termYears: termYears,
      termMonths: termMonths,
      postalRateService: postalRateService,
    ),
  };
}
