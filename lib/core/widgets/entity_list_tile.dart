import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum EntityActionType { edit, delete, call, whatsapp, sms, location }

class EntityAction {
  final EntityActionType type;
  final String label;
  final Widget icon;

  final VoidCallback onTap;
  final bool isDestructive;
  final bool isInline;

  const EntityAction({
    required this.type,
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
      type: EntityActionType.edit,
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
      type: EntityActionType.delete,
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

    return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: AppDimensions.paddingSm,
          ),
          onTap: onTap,
          leading: CircleAvatar(
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
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              trailing != null ? trailing! : const SizedBox.shrink(),
              for (final action in inlineActions)
                IconButton(
                  icon: action.icon,
                  iconSize: AppDimensions.iconMd,
                  tooltip: action.label,
                  color: action.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  onPressed: action.onTap,
                ),
              if (menuActions.isNotEmpty)
                PopupMenuButton<EntityAction>(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreVertical,
                    size: AppDimensions.iconMd,
                  ),
                  iconSize: AppDimensions.iconMd,
                  tooltip: t.common.moreOptions,
                  onSelected: (action) => action.onTap(),
                  itemBuilder: (context) => menuActions.map((action) {
                    final color = action.isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface;

                    return PopupMenuItem(
                      value: action,
                      child: Row(
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              color: color,
                              size: AppDimensions.iconMd,
                            ),
                            child: action.icon,
                          ),
                          AppSpacings.gapSm,
                          Text(
                            action.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        )
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
}
