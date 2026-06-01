import 'package:flutter/material.dart';
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
            Icon(Icons.add, color: theme.colorScheme.outline),
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
          child: Icon(
            Icons.arrow_downward_rounded,
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
