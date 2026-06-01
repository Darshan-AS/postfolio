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
    String? note,
  }) = IncomeGeneration;

  // Shared Getters
  @override
  double get totalInvested => switch (this) {
    WealthAccumulation p => p.totalInvested,
    IncomeGeneration p => p.totalInvested,
  };

  @override
  double get maturityAmount => switch (this) {
    WealthAccumulation p => p.maturityAmount,
    IncomeGeneration p => p.maturityAmount,
  };

  @override
  double get totalInterestEarned => switch (this) {
    WealthAccumulation p => p.totalInterestEarned,
    IncomeGeneration p => p.totalInterestEarned,
  };

  @override
  DateTime get maturityDate => switch (this) {
    WealthAccumulation p => p.maturityDate,
    IncomeGeneration p => p.maturityDate,
  };
}
