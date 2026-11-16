import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/i18n/strings.g.dart';

class WealthAccumulationGrid extends StatelessWidget {
  final double totalInvested;
  final double projectedInterest;
  final double maturityAmount;

  const WealthAccumulationGrid({
    super.key,
    required this.totalInvested,
    required this.projectedInterest,
    required this.maturityAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DetailAmountCard(
              title: t.projections.totalInvested,
              amount: totalInvested,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacings.gapMd,
            HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: AppDimensions.iconSm,
              color: theme.colorScheme.outline,
            ),
            AppSpacings.gapMd,
            DetailAmountCard(
              title: t.projections.estInterest,
              amount: projectedInterest,
              backgroundColor: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.5,
              ),
              textColor: theme.colorScheme.onSecondaryContainer,
            ),
          ],
        ),
        AppSpacings.gapSm,
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingXs,
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowDown01,
            size: AppDimensions.iconMd,
            color: theme.colorScheme.outline,
          ),
        ),
        AppSpacings.gapSm,
        DetailAmountCard(
          title: t.projections.totalReturnMaturity,
          amount: maturityAmount,
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          isExpanded: false,
        ),
      ],
    );
  }
}
