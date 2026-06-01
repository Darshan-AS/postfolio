import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
  final String? value;
  final bool hideIfNull;
  final Widget? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DetailItem({
    super.key,
    required this.label,
    this.value,
    this.hideIfNull = false,
    this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (hideIfNull && (value == null || value!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final displayValue = (value == null || value!.isEmpty)
        ? t.common.notProvided
        : value!;

    Widget content = Padding(
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
                  displayValue,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
          if (onTap != null && trailing == null)
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: AppDimensions.iconMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }

    return content;
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
              amount.toRupeeFormat(),
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
  final MaturityUrgency urgency;
  final String? relativeTimeText;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.urgency = MaturityUrgency.normal,
    this.relativeTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color fgColor;

    if (urgency == MaturityUrgency.matured) {
      bgColor = colorScheme.errorContainer;
      fgColor = colorScheme.onErrorContainer;
    } else if (urgency == MaturityUrgency.maturingSoon) {
      bgColor = colorScheme.tertiaryContainer;
      fgColor = colorScheme.onTertiaryContainer;
    } else if (status.toLowerCase() == 'closed') {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    } else {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    }

    final displayText =
        (urgency == MaturityUrgency.maturingSoon ||
                urgency == MaturityUrgency.matured) &&
            relativeTimeText != null
        ? relativeTimeText!
        : status;

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
        displayText.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.bold,
          letterSpacing: compact
              ? AppDimensions.letterSpacingSm
              : AppDimensions.letterSpacingMd,
        ),
      ),
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
