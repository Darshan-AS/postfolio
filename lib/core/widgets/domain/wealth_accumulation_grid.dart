import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/domain/projection_summary.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The projection of a deposit that grows to maturity, laid out as a sum:
/// total invested, plus the estimated interest, equals the total return.
class WealthAccumulationGrid extends StatelessWidget {
  final double totalInvested;
  final double projectedInterest;
  final double maturityAmount;

  /// Set when [totalInvested] is the amount on the deposit's row (a one-time deposit's
  /// principal): it travels here from the row that opened the screen.
  final Object? investedHeroTag;

  const WealthAccumulationGrid({
    super.key,
    required this.totalInvested,
    required this.projectedInterest,
    required this.maturityAmount,
    this.investedHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    return ProjectionSummary(
      lines: [
        ProjectionLine(
          label: t.projections.totalInvested,
          amount: totalInvested,
          heroTag: investedHeroTag,
        ),
        ProjectionLine(
          label: t.projections.estInterest,
          amount: projectedInterest,
          sign: HugeIcons.strokeRoundedPlusSign,
        ),
      ],
      resultLabel: t.projections.totalReturnMaturity,
      resultAmount: maturityAmount,
      resultSign: HugeIcons.strokeRoundedEqualSign,
    );
  }
}
