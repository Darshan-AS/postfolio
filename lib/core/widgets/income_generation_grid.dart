import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DetailAmountCard(
              title: t.projections.lockedPrincipal,
              amount: principal,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacings.gapLg,
            DetailAmountCard(
              title: t.projections.payoutTitle(frequency: payoutFrequency),
              amount: periodicPayout,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              textColor: theme.colorScheme.onTertiaryContainer,
            ),
          ],
        ),
        AppSpacings.gapLg,
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: theme.colorScheme.secondaryContainer),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.projections.lifetimeInterestEarned,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              AppSpacings.gapSm,
              Text(
                totalInterestEarned.toRupeeFormat(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapXs,
              Text(
                t.projections.lifetimeInterestDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
