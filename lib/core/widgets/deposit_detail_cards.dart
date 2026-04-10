import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';

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
            borderRadius: BorderRadius.circular(16),
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
  final IconData? icon;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                const SizedBox(height: 2),
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

  const DetailAmountCard({
    super.key,
    required this.title,
    required this.amount,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Expanded(
      child: Card(
        elevation: 0,
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fg.withOpacity(0.8),
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
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
