import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
            vertical: AppDimensions.paddingSm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingSm,
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                size: AppDimensions.iconMd,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: icon!,
            ),
            AppSpacings.gapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacings.gapXs,
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailAmountCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isExpanded;

  const DetailAmountCard({
    super.key,
    required this.title,
    required this.amount,
    this.backgroundColor,
    this.textColor,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = textColor ?? theme.colorScheme.onPrimaryContainer;

    Widget card = Card(
      elevation: 0,
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg.withValues(alpha: 0.8),
              ),
            ),
            AppSpacings.gapSm,
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    return isExpanded ? Expanded(child: card) : card;
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isClosed = status.toLowerCase() == 'closed';
    final isMatured = status.toLowerCase() == 'matured';

    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isClosed
        ? colorScheme.errorContainer
        : (isMatured
              ? colorScheme.tertiaryContainer
              : colorScheme.primaryContainer);
    final fgColor = isClosed
        ? colorScheme.onErrorContainer
        : (isMatured
              ? colorScheme.onTertiaryContainer
              : colorScheme.onPrimaryContainer);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSm,
              vertical: AppDimensions.paddingXs,
            )
          : const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingXs,
            ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          compact ? AppDimensions.radiusMd : AppDimensions.radiusLg,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 10 : null,
          letterSpacing: compact ? 0.2 : 0.5,
        ),
      ),
    );
  }
}

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
              title: "Total Invested",
              amount: totalInvested,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacings.gapMd,
            Icon(Icons.add, color: theme.colorScheme.outline),
            AppSpacings.gapMd,
            DetailAmountCard(
              title: "Est. Interest",
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
          title: "Total Return (Maturity)",
          amount: maturityAmount,
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          isExpanded: false,
        ),
      ],
    );
  }
}

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
              title: "Locked Principal",
              amount: principal,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacings.gapLg,
            DetailAmountCard(
              title: "$payoutFrequency Payout",
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
                "Lifetime Interest Earned",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              AppSpacings.gapSm,
              Text(
                '₹${totalInterestEarned.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapXs,
              Text(
                "Over the full term, before returning the principal.",
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

class KvpMultiplierBanner extends StatelessWidget {
  final String doublesInText;

  const KvpMultiplierBanner({super.key, required this.doublesInText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingXxl),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: AppDimensions.iconMd,
            ),
          ),
          AppSpacings.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Money Multiplier",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  doublesInText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
