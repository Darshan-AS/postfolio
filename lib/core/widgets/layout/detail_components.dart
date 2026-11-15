import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The heading above a group of rows on a detail screen.
class DetailSectionTitle extends StatelessWidget {
  const DetailSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingSm,
        AppDimensions.paddingLg,
        AppDimensions.paddingSm,
      ),
      child: Text(
        title,
        style: AppTypography.emphasizedOf(context).titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A titled group of detail rows.
///
/// Each child becomes one row of a grouped list (see [AppGroup]); the seams between rows
/// replace divider lines, so callers pass rows only. A [DetailItem] that hides itself
/// because it has no value is left out, so it does not leave an empty row behind.
class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final child in children)
        if (!(child is DetailItem && child.isHidden)) child,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionTitle(title),
        AppGroup(children: rows),
      ],
    );
  }
}

class DetailItem extends StatelessWidget {
  final String label;
  final String? value;
  final String? copyValue;
  final bool hideIfNull;
  final Widget? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DetailItem({
    super.key,
    required this.label,
    this.value,
    this.copyValue,
    this.hideIfNull = false,
    this.icon,
    this.onTap,
    this.trailing,
  });

  /// True when the row has no value and was asked to hide in that case.
  bool get isHidden => hideIfNull && (value == null || value!.isEmpty);

  @override
  Widget build(BuildContext context) {
    if (isHidden) {
      return const SizedBox.shrink();
    }

    final displayValue = (value == null || value!.isEmpty)
        ? t.common.notProvided
        : value!;
    final effectiveCopy = (copyValue != null && copyValue!.trim().isNotEmpty)
        ? copyValue!.trim()
        : null;

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
                  style: AppTypography.emphasizedOf(context).bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (effectiveCopy != null)
            IconButton(
              key: ValueKey('copy_$label'),
              tooltip: t.common.copy,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCopy01,
                size: AppDimensions.iconSm,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: effectiveCopy));
                AppFeedback.showSuccess(context, t.common.copiedToClipboard);
              },
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

/// Stat cards side by side, all as tall as the tallest. At large text a card's title no
/// longer fits half a phone's width, so each card takes a line of its own.
class DetailStatRow extends StatelessWidget {
  const DetailStatRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (AppDimensions.isLargeText(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimensions.paddingSm,
        children: children,
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimensions.paddingLg,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}

/// A headline figure with its name above it. Lay several out with [DetailStatRow].
class DetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const DetailStatCard({
    super.key,
    required this.title,
    required this.value,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Material(
      color: bg,
      shape: AppShapes.rounded(AppShapes.groupOuter),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg.withValues(alpha: 0.8),
              ),
            ),
            AppSpacings.gapSm,
            // Amounts must stay on one line; shrink rather than wrap in a narrow card.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.emphasizedOf(context).headlineSmall?.copyWith(
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A [DetailStatCard] whose figure is a rupee amount.
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
    return DetailStatCard(
      title: title,
      value: amount.toRupeeFormat(),
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final DepositStatus? depositStatus;
  final bool compact;
  final MaturityUrgency urgency;
  final String? relativeTimeText;

  const StatusBadge({
    super.key,
    required this.status,
    this.depositStatus,
    this.compact = false,
    this.urgency = MaturityUrgency.normal,
    this.relativeTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final financial = AppFinancialColors.of(context);
    final isClosed = depositStatus != null
        ? depositStatus == DepositStatus.closed
        : status.toLowerCase() == 'closed';

    final Color bgColor;
    final Color fgColor;

    if (isClosed) {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    } else if (urgency == MaturityUrgency.matured) {
      bgColor = financial.overdue.container;
      fgColor = financial.overdue.onContainer;
    } else if (urgency == MaturityUrgency.maturingSoon) {
      bgColor = financial.warning.container;
      fgColor = financial.warning.onContainer;
    } else {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    }

    final displayText =
        !isClosed &&
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
        borderRadius: BorderRadius.circular(AppShapes.extraExtraLarge),
      ),
      child: Text(
        displayText,
        style: (compact ? emphasized.labelSmall : emphasized.labelMedium)?.copyWith(
          color: fgColor,
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
            theme.colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppShapes.extraLarge),
      ),
      child: Row(
        children: [
          AppShapeAvatar(
            shape: AppAvatarShape.sunny,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedRocket01,
              size: AppDimensions.iconMd,
            ),
          ),
          AppSpacings.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.common.moneyMultiplier,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                Text(
                  doublesInText,
                  style: AppTypography.emphasizedOf(context).titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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
