import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class EntityAction {
  final String label;
  final Widget icon;

  final VoidCallback onTap;
  final bool isDestructive;
  final bool isInline;

  const EntityAction({
    required this.label,
    required this.icon,

    required this.onTap,
    this.isDestructive = false,
    this.isInline = false,
  });

  factory EntityAction.edit({
    required VoidCallback onTap,
    bool isInline = false,
  }) {
    return EntityAction(
      label: t.common.edit,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedEdit02,
        size: AppDimensions.iconMd,
      ),
      onTap: onTap,
      isInline: isInline,
    );
  }

  factory EntityAction.delete({required VoidCallback onTap}) {
    return EntityAction(
      label: t.common.delete,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedDelete02,
        size: AppDimensions.iconMd,
      ),
      onTap: onTap,
      isDestructive: true,
    );
  }
}

class EntityListTile extends StatelessWidget {
  final Widget? leadingIcon;
  final String? leadingText;
  final Color? leadingBackgroundColor;
  final Color? leadingForegroundColor;
  final Color? indicatorColor;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<EntityAction> actions;

  const EntityListTile({
    super.key,
    this.leadingIcon,
    this.leadingText,
    this.leadingBackgroundColor,
    this.leadingForegroundColor,
    this.indicatorColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final inlineActions = actions.where((a) => a.isInline).toList();
    final menuActions = actions.where((a) => !a.isInline).toList();

    final hasActionButtons = inlineActions.isNotEmpty || menuActions.isNotEmpty;
    final rightPadding = hasActionButtons
        ? AppDimensions.paddingNone
        : AppDimensions.paddingLg;

    Widget tile = InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.paddingLg,
          right: rightPadding,
          top: AppDimensions.paddingMd,
          bottom: AppDimensions.paddingMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLeading(theme),
            AppSpacings.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ?subtitle,
                ],
              ),
            ),
            if (trailing != null || hasActionButtons) AppSpacings.gapSm,
            ?trailing,
            if (trailing != null && hasActionButtons) AppSpacings.gapXs,
            for (final action in inlineActions)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.actionButtonSize,
                  minHeight: AppDimensions.actionButtonSize,
                  maxWidth: AppDimensions.actionButtonSize,
                  maxHeight: AppDimensions.actionButtonSize,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: action.icon,
                iconSize: AppDimensions.iconMd,
                tooltip: action.label,
                color: action.isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                onPressed: action.onTap,
              ),
            if (menuActions.isNotEmpty)
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMoreVertical,
                      size: AppDimensions.iconMd,
                    ),
                    iconSize: AppDimensions.iconMd,
                    tooltip: t.common.moreOptions,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(
                        AppDimensions.actionButtonSize,
                        AppDimensions.actionButtonSize,
                      ),
                      maximumSize: const Size(
                        AppDimensions.actionButtonSize,
                        AppDimensions.actionButtonSize,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                menuChildren: menuActions.map((action) {
                  final color = action.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface;

                  return MenuItemButton(
                    onPressed: action.onTap,
                    leadingIcon: IconTheme(
                      data: IconThemeData(
                        color: color,
                        size: AppDimensions.iconMd,
                      ),
                      child: action.icon,
                    ),
                    child: Text(action.label, style: TextStyle(color: color)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );

    if (indicatorColor != null) {
      tile = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: indicatorColor!,
              width: AppDimensions.borderLg,
            ),
          ),
        ),
        child: tile,
      );
    }

    return tile
        .animate()
        .fade(duration: AppAnimations.medium, curve: AppAnimations.defaultCurve)
        .slideY(
          begin: AppAnimations.slideOffset,
          end: 0,
          duration: AppAnimations.medium,
          curve: AppAnimations.defaultCurve,
        )
        .shimmer(
          duration: AppAnimations.slow,
          color: theme.colorScheme.surfaceTint.withValues(alpha: 0.1),
        );
  }

  Widget _buildLeading(ThemeData theme) {
    return CircleAvatar(
      radius: AppDimensions.radiusXxl,
      backgroundColor:
          leadingBackgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundColor:
          leadingForegroundColor ?? theme.colorScheme.onPrimaryContainer,
      child:
          leadingIcon ??
          (leadingText != null
              ? Text(
                  leadingText!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        leadingForegroundColor ??
                        theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null),
    );
  }
}
