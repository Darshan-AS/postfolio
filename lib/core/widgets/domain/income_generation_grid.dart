import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/domain/projection_summary.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The projection of a deposit that pays interest out: the locked principal, the payout it
/// yields each period, and the interest earned over the full term as the outcome.
class IncomeGenerationGrid extends StatelessWidget {
  final double principal;
  final double periodicPayout;
  final String payoutFrequency;
  final double totalInterestEarned;

  const IncomeGenerationGrid({
    super.key,
    required this.principal,
    required this.periodicPayout,
    required this.payoutFrequency,
    required this.totalInterestEarned,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ProjectionSummary(
      lines: [
        ProjectionLine(label: t.projections.lockedPrincipal, amount: principal),
        // The payout is what the holder receives; it keeps its own accent.
        ProjectionLine(
          label: t.projections.payoutTitle(frequency: payoutFrequency),
          amount: periodicPayout,
          color: scheme.tertiaryContainer,
          onColor: scheme.onTertiaryContainer,
        ),
      ],
      resultLabel: t.projections.lifetimeInterestEarned,
      resultAmount: totalInterestEarned,
      resultDescription: t.projections.lifetimeInterestDescription,
    );
  }
}
