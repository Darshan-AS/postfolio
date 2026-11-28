import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart'
    show EntityAction;
import 'package:postfolio/core/widgets/expressive/app_menu.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/layout/entity_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

export 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart'
    show AppAvatarShape;
export 'package:postfolio/core/widgets/layout/entity_list_tile.dart'
    show EntityAction;

class EntityDetailScaffold extends StatelessWidget {
  final String appBarTitle;
  final VoidCallback onEdit;
  final Future<String?> Function() onDelete;
  final String deleteDialogTitle;
  final String deleteDialogContent;
  final Widget header;
  final List<Widget> body;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;

  /// Actions of the overflow menu, listed above Delete with their labels.
  final List<EntityAction> menuActions;

  /// Reloads what the screen shows. When set, the body can be pulled down to refresh.
  final Future<void> Function()? onRefresh;

  /// Whether [body] is built from a record that is still loading, while [header] already
  /// shows the real entity (from its row in a list). The body is drawn as a placeholder
  /// and the header as it is.
  final bool bodyLoading;

  const EntityDetailScaffold({
    super.key,
    required this.appBarTitle,
    required this.onEdit,
    required this.onDelete,
    required this.deleteDialogTitle,
    required this.deleteDialogContent,
    required this.header,
    required this.body,
    this.onBack,
    this.floatingActionButton,
    this.menuActions = const [],
    this.onRefresh,
    this.bodyLoading = false,
  });

  void _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialogs.confirmDelete(
      context,
      title: deleteDialogTitle,
      content: deleteDialogContent,
    );

    if (confirmed != true || !context.mounted) return;

    final error = await onDelete();
    if (!context.mounted) return;

    if (error == null) {
      if (onBack != null) {
        onBack!();
      } else {
        Navigator.of(context).maybePop();
      }
    } else {
      AppFeedback.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack?.call();
      },
      child: Scaffold(
        appBar: _buildAppBar(theme, context),
        body: SelectionArea(child: _buildBody(context, theme)),
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      title: AppBarTitle(appBarTitle),
      leading: onBack != null
          ? BackButton(onPressed: onBack)
          : null, // Let Scaffold handle default
      actions: [
        IconButton.filledTonal(
          // See FormAppBar: inside an app bar the tonal variant needs its foreground set
          // explicitly.
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          tooltip: t.common.edit,
          icon: const AppIcon(
            HugeIcons.strokeRoundedEdit02,
            size: AppDimensions.iconMd,
          ),
          onPressed: onEdit,
        ),
        AppMenu(
          entries: [
            for (final action in menuActions)
              AppMenuEntry(
                label: action.label,
                icon: action.icon,
                onPressed: action.onTap,
              ),
            AppMenuEntry(
              label: t.common.delete,
              icon: const AppIcon(
                HugeIcons.strokeRoundedDelete02,
                size: AppDimensions.iconSm,
              ),
              isDestructive: true,
              onPressed: () => _confirmDelete(context),
            ),
          ],
          anchorBuilder: (context, open) => IconButton(
            key: const ValueKey('entity_detail_more_button'),
            tooltip: t.common.moreOptions,
            icon: const AppIcon(
              HugeIcons.strokeRoundedMoreVertical,
              size: AppDimensions.iconMd,
            ),
            onPressed: open,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingXs),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final header = this.header;
    // The sections wait, with the rest of the head, for the parts that travel to it: from
    // a row low on the screen those parts would cross the sections as they fade in.
    final heroTag = header is EntityDetailHeader ? header.heroTag : null;
    final items = <Widget>[
      header,
      AppSpacings.gapXl,
      for (final section in body)
        EntityHeroFollower(
          tag: heroTag,
          child: bodyLoading
              ? Skeletonizer(enabled: true, child: section)
              : section,
        ),
    ];
    final animatedItems = disableAnimations
        ? items
        : items
              .animate(interval: AppAnimations.stagger)
              .fade(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
              )
              .slideY(
                begin: AppAnimations.slideOffset,
                end: 0,
                duration: AppAnimations.medium,
                curve: AppAnimations.spatialCurve,
              );

    final onRefresh = this.onRefresh;
    final list = ListView(
      // A short screen must still be draggable for the pull to start.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pageMargin,
        AppDimensions.paddingSm,
        AppDimensions.pageMargin,
        floatingActionButton != null
            ? AppDimensions.listBottomPaddingFAB
            : AppDimensions.paddingLg,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxFormWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: animatedItems,
            ),
          ),
        ),
      ],
    );

    return onRefresh == null
        ? list
        : AppRefreshIndicator(onRefresh: onRefresh, child: list);
  }
}

/// The head of a detail screen: a Material shape with the entity's initial or code beside
/// its name, with an optional supporting line, badge, block and actions.
///
/// It is one row, not a centred hero. A screen's worth of avatar and headline pushed what
/// the screen is opened for (the next due amount, the contact details) past the middle of
/// a phone.
class EntityDetailHeader extends StatelessWidget {
  final Widget? avatarChild;
  final String? avatarText;
  final String? avatarSubtext;
  final Color? avatarBackgroundColor;
  final Color? avatarForegroundColor;
  final AppAvatarShape avatarShape;
  final AppAvatarShape? avatarOpensFrom;
  final String title;

  /// Under the title, beside the avatar. At large text it takes the full width under the
  /// avatar's row instead: beside the avatar a phone number or a scheme name breaks in two.
  final Widget? subtitle;

  /// At the end of the title's row; under the subtitle at large text.
  final Widget? badge;

  /// A full-width block under the avatar's row, e.g. a progress summary.
  final Widget? footer;
  final List<Widget> bottomActions;

  /// Identifies the entity and the row that opened the screen (`EntityHero.tagFrom`). The
  /// avatar and the title travel here from that row; a part of the [subtitle] that the
  /// row shows too wraps itself in an [EntityHero]. Everything else in the header, and
  /// the sections under it, wait for them to land ([EntityHeroFollower]). Null while the
  /// header shows a placeholder, and when no row opened the screen.
  final Object? heroTag;

  const EntityDetailHeader({
    super.key,
    this.avatarChild,
    this.avatarText,
    this.avatarSubtext,
    this.avatarBackgroundColor,
    this.avatarForegroundColor,
    this.avatarShape = AppAvatarShape.cookie9,
    this.avatarOpensFrom,
    required this.title,
    this.subtitle,
    this.badge,
    this.footer,
    this.bottomActions = const [],
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);
    // At large text only the title stays beside the avatar; the rest needs the width.
    final stacked = AppDimensions.isLargeText(context);
    final titleText = EntityHero(
      tag: heroTag,
      part: EntityHeroPart.title,
      child: Text(title, style: emphasized.titleLarge),
    );
    // The parts the row does not show wait for the ones that travel from it.
    Widget? waiting(Widget? part) =>
        part == null ? null : EntityHeroFollower(tag: heroTag, child: part);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EntityHero(
              tag: heroTag,
              part: EntityHeroPart.avatar,
              child: _buildAvatar(theme),
            ),
            AppSpacings.gapLg,
            Expanded(
              child: stacked
                  // Aligned, so the title's box is as wide as the title and no wider.
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: titleText,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [titleText, ?waiting(subtitle)],
                    ),
            ),
            if (badge != null && !stacked) ...[
              AppSpacings.gapSm,
              ?waiting(badge),
            ],
          ],
        ),
        if (stacked)
          for (final line in [waiting(subtitle), waiting(badge)].nonNulls) ...[
            AppSpacings.gapXs,
            Align(alignment: AlignmentDirectional.centerStart, child: line),
          ],
        if (footer != null) ...[AppSpacings.gapMd, ?waiting(footer)],
        if (bottomActions.isNotEmpty) ...[
          AppSpacings.gapMd,
          ?waiting(
            Wrap(
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingSm,
              children: bottomActions,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final text = avatarText;
    if (avatarChild == null && text != null) {
      return EntityAvatar(
        text: text,
        subtext: avatarSubtext,
        shape: avatarShape,
        opensFrom: avatarOpensFrom,
        backgroundColor: avatarBackgroundColor,
        foregroundColor: avatarForegroundColor,
        prominence: 1,
      );
    }
    return AppShapeAvatar(
      size: AppDimensions.avatarLg,
      shape: avatarShape,
      opensFrom: avatarOpensFrom,
      backgroundColor:
          avatarBackgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundColor:
          avatarForegroundColor ?? theme.colorScheme.onPrimaryContainer,
      child: avatarChild ?? const SizedBox.shrink(),
    );
  }
}
