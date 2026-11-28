import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/payout_frequency.dart';

part 'investment_projection.freezed.dart';

@freezed
sealed class InvestmentProjection with _$InvestmentProjection {
  const InvestmentProjection._();

  /// Projection for schemes that compound and return everything at maturity
  /// (e.g., RD, NSC, KVP)
  const factory InvestmentProjection.wealthAccumulation({
    required double totalInvested,
    required double maturityAmount,
    required double totalInterestEarned,
    required DateTime maturityDate,
    @Default(0.0) double interestRate,
    @Default(0) int termYears,
    @Default(0) int termMonths,
    String? note,
  }) = WealthAccumulation;

  /// Projection for schemes that provide periodic payouts and return principal at maturity
  /// (e.g., MIS, TD)
  const factory InvestmentProjection.incomeGeneration({
    required double totalInvested,
    required double maturityAmount,
    required double totalInterestEarned,
    required DateTime maturityDate,
    required double periodicPayoutAmount,
    required PayoutFrequency payoutFrequency,
    @Default(0.0) double interestRate,
    @Default(0) int termYears,
    @Default(0) int termMonths,
    String? note,
  }) = IncomeGeneration;
}
