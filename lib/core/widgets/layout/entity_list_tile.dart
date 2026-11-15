import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/i18n/strings.g.dart';

export 'package:postfolio/core/widgets/expressive/app_group.dart' show AppGroupPosition;
export 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart' show AppAvatarShape;

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

/// One row of an entity list: a shape avatar, a title with supporting content, an optional
/// trailing figure, inline actions and an overflow menu.
///
/// The row is a grouped tile: pass its [position] in the list so a run of rows reads as one
/// container. The page margin belongs to the list, not to the row, so the row's own right
/// edge is where the overflow button ends.
class EntityListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? leadingIcon;
  final String? leadingText;
  final String? leadingSubtext;
  final Color? leadingBackgroundColor;
  final Color? leadingForegroundColor;

  /// Shape of the default leading avatar.
  final AppAvatarShape leadingShape;

  /// A status colour shown as a short bar on the leading edge.
  final Color? indicatorColor;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;

  /// Optional full-width block rendered below the main row (e.g. a primary action button).
  /// It shares the tile's tap surface and horizontal padding.
  final Widget? footer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<EntityAction> actions;
  final bool isSelected;

  /// Where this row sits among its neighbours.
  final AppGroupPosition position;

  const EntityListTile({
    super.key,
    this.leading,
    this.leadingIcon,
    this.leadingText,
    this.leadingSubtext,
    this.leadingBackgroundColor,
    this.leadingForegroundColor,
    this.leadingShape = AppAvatarShape.cookie9,
    this.indicatorColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.onTap,
    this.onLongPress,
    this.actions = const [],
    this.isSelected = false,
    this.position = AppGroupPosition.single,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);

    final inlineActions = actions.where((a) => a.isInline).toList();
    final menuActions = actions.where((a) => !a.isInline).toList();

    final hasActionButtons = inlineActions.isNotEmpty || menuActions.isNotEmpty;
    // Beside a trailing block the title is left with a third of a phone's width, which at
    // large text is five letters. There the trailing block takes a line of its own below.
    final trailingBelow = trailing != null && AppDimensions.isLargeText(context);
    final rightPadding = hasActionButtons
        ? AppDimensions.paddingNone
        : AppDimensions.paddingLg;

    final content = Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingLg,
        right: rightPadding,
        top: AppDimensions.paddingMd,
        bottom: AppDimensions.paddingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, rowConstraints) {
              final trailingMaxWidth = rowConstraints.maxWidth.isFinite
                  ? rowConstraints.maxWidth * (hasActionButtons ? 0.42 : 0.48)
                  : double.infinity;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading ?? _buildLeading(theme, emphasized),
                  AppSpacings.gapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: emphasized.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ?subtitle,
                      ],
                    ),
                  ),
                  if ((trailing != null && !trailingBelow) || hasActionButtons)
                    AppSpacings.gapSm,
                  if (trailing != null && !trailingBelow)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: trailingMaxWidth),
                      child: trailing!,
                    ),
                  for (final action in inlineActions)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: AppDimensions.minTapTarget,
                        minHeight: AppDimensions.minTapTarget,
                        maxWidth: AppDimensions.minTapTarget,
                        maxHeight: AppDimensions.minTapTarget,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
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
                              AppDimensions.minTapTarget,
                              AppDimensions.minTapTarget,
                            ),
                            maximumSize: const Size(
                              AppDimensions.minTapTarget,
                              AppDimensions.minTapTarget,
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
                          child: Text(
                            action.label,
                            style: TextStyle(color: color),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              );
            },
          ),
          if (trailingBelow)
            Padding(
              padding: EdgeInsets.only(
                top: AppDimensions.paddingSm,
                right: hasActionButtons
                    ? AppDimensions.paddingLg
                    : AppDimensions.paddingNone,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          if (footer != null)
            Padding(
              // Align footer's right edge with the 16dp horizontal grid.
              padding: EdgeInsets.only(
                top: AppDimensions.paddingSm,
                right: hasActionButtons
                    ? AppDimensions.paddingLg
                    : AppDimensions.paddingNone,
              ),
              child: footer,
            ),
        ],
      ),
    );

    return AppGroupTile(
      position: position,
      selected: isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
      child: indicatorColor == null
          ? content
          : Stack(
              children: [
                content,
                Positioned(
                  left: 0,
                  top: AppDimensions.paddingMd,
                  bottom: AppDimensions.paddingMd,
                  width: AppDimensions.borderLg,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(AppShapes.extraSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeading(ThemeData theme, TextTheme emphasized) {
    final fgColor =
        leadingForegroundColor ?? theme.colorScheme.onPrimaryContainer;
    final hasSubtext = leadingSubtext != null && leadingSubtext!.isNotEmpty;
    final isSingleChar = leadingText != null && leadingText!.length == 1;
    final textStyle = isSingleChar
        ? emphasized.titleLarge
        : emphasized.titleSmall;

    return AppShapeAvatar(
      size: AppDimensions.avatarMd,
      shape: leadingShape,
      backgroundColor:
          leadingBackgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundColor: fgColor,
      child:
          leadingIcon ??
          (leadingText != null
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingSm),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          leadingText!,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: textStyle?.copyWith(
                            height: hasSubtext ? 1.15 : null,
                            color: fgColor,
                          ),
                        ),
                        if (hasSubtext) ...[
                          AppSpacings.gapXxs,
                          Text(
                            leadingSubtext!,
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                            style: emphasized.labelSmall?.copyWith(
                              fontSize: AppDimensions.fontXs,
                              height: AppDimensions.lineHeightTight,
                              color: fgColor.withValues(
                                alpha: AppDimensions.opacityMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()),
    );
  }
}
