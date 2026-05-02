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
  }) = _WealthAccumulation;

  /// Projection for schemes that provide periodic payouts and return principal at maturity
  /// (e.g., MIS, TD)
  const factory InvestmentProjection.incomeGeneration({
    required double totalInvested,
    required double maturityAmount,
    required double totalInterestEarned,
    required DateTime maturityDate,
    required double periodicPayoutAmount,
    required PayoutFrequency payoutFrequency,
  }) = _IncomeGeneration;

  // Shared Getters
  @override
  double get totalInvested => map(
        wealthAccumulation: (p) => p.totalInvested,
        incomeGeneration: (p) => p.totalInvested,
      );

  @override
  double get maturityAmount => map(
        wealthAccumulation: (p) => p.maturityAmount,
        incomeGeneration: (p) => p.maturityAmount,
      );

  @override
  double get totalInterestEarned => map(
        wealthAccumulation: (p) => p.totalInterestEarned,
        incomeGeneration: (p) => p.totalInterestEarned,
      );

  @override
  DateTime get maturityDate => map(
        wealthAccumulation: (p) => p.maturityDate,
        incomeGeneration: (p) => p.maturityDate,
      );
}
