import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// A centred message for a screen or list that has nothing to show: a large Material shape
/// holding an icon, the message, and an optional action.
///
/// [EmptyStateView] and [ErrorStateView] share this layout; they differ in colour and
/// default icon.
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.shape,
    required this.message,
    this.subtitle,
    required this.badgeColor,
    required this.iconColor,
    this.actionLabel,
    this.actionIcon,
    this.isPrimaryAction = false,
    this.onAction,
  });

  final AppIconData icon;
  final AppAvatarShape shape;
  final String message;
  final String? subtitle;
  final Color badgeColor;
  final Color iconColor;
  final String? actionLabel;
  final AppIconData? actionIcon;
  final bool isPrimaryAction;
  final VoidCallback? onAction;

  static const double _badgeSize = AppDimensions.avatarMd * 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppShapeAvatar(
          size: _badgeSize,
          shape: shape,
          backgroundColor: badgeColor,
          foregroundColor: iconColor,
          child: AppIcon(
            icon,
            size: AppDimensions.iconXl - AppDimensions.paddingSm,
          ),
        ),
        AppSpacings.gapLg,
        Text(
          message,
          textAlign: TextAlign.center,
          style:
              (hasSubtitle
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(
                    color: hasSubtitle
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
        ),
        if (hasSubtitle) ...[
          AppSpacings.gapXs,
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null) ...[
          AppSpacings.gapLg,
          isPrimaryAction
              ? AppButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                )
              : AppButton.tonal(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: MediaQuery.disableAnimationsOf(context)
            ? column
            : column
                  .animate()
                  .fade(
                    duration: AppMotion.effectsSlowDuration,
                    curve: AppMotion.effectsSlowCurve,
                  )
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: AppMotion.spatialDuration,
                    curve: AppMotion.spatialCurve,
                  ),
      ),
    );
  }
}

/// Shown when a list or section has no content, with an optional way out (e.g. clearing
/// filters).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = HugeIcons.strokeRoundedInbox,
    this.actionLabel,
    this.actionIcon,
    this.isPrimaryAction = false,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final AppIconData icon;
  final String? actionLabel;
  final AppIconData? actionIcon;
  final bool isPrimaryAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StateMessage(
      icon: icon,
      shape: AppAvatarShape.cookie12,
      message: message,
      subtitle: subtitle,
      badgeColor: scheme.secondaryContainer,
      iconColor: scheme.onSecondaryContainer,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      isPrimaryAction: isPrimaryAction,
      onAction: onAction,
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StateMessage(
      icon: HugeIcons.strokeRoundedAlert01,
      shape: AppAvatarShape.softBurst,
      message: message,
      badgeColor: scheme.errorContainer,
      iconColor: scheme.onErrorContainer,
      actionLabel: t.common.retry,
      actionIcon: HugeIcons.strokeRoundedRefresh,
      onAction: onRetry,
    );
  }
}
