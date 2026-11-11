import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
  final List<Widget> customActions;

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
    this.customActions = const [],
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
      title: Text(appBarTitle),
      leading: onBack != null
          ? BackButton(onPressed: onBack)
          : null, // Let Scaffold handle default
      actions: [
        ...customActions,
        IconButton(
          tooltip: t.common.edit,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedEdit02,
            size: AppDimensions.iconMd,
          ),
          onPressed: onEdit,
        ),
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              key: const ValueKey('entity_detail_delete_item'),
              leadingIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: AppDimensions.iconSm,
                color: theme.colorScheme.error,
              ),
              onPressed: () => _confirmDelete(context),
              child: Text(
                t.common.delete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
          builder: (context, controller, _) => IconButton(
            key: const ValueKey('entity_detail_more_button'),
            tooltip: t.common.moreOptions,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[header, AppSpacings.gapXxl, ...body];
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
                curve: AppAnimations.defaultCurve,
              );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingLg,
        AppDimensions.paddingLg,
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
  }
}

class EntityDetailHeader extends StatelessWidget {
  final Widget? avatarChild;
  final String? avatarText;
  final String? avatarSubtext;
  final Color? avatarBackgroundColor;
  final Color? avatarForegroundColor;
  final String title;
  final Widget? subtitle;
  final Widget? badge;
  final List<Widget> bottomActions;

  const EntityDetailHeader({
    super.key,
    this.avatarChild,
    this.avatarText,
    this.avatarSubtext,
    this.avatarBackgroundColor,
    this.avatarForegroundColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.bottomActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          _buildAvatar(theme),
          AppSpacings.gapLg,
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[AppSpacings.gapSm, subtitle!],
          if (badge != null) ...[AppSpacings.gapMd, badge!],
          if (bottomActions.isNotEmpty) ...[
            AppSpacings.gapLg,
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppDimensions.paddingSm,
              runSpacing: AppDimensions.paddingSm,
              children: bottomActions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final fgColor =
        avatarForegroundColor ?? theme.colorScheme.onPrimaryContainer;
    final hasSubtext = avatarSubtext != null && avatarSubtext!.isNotEmpty;

    return CircleAvatar(
      radius: AppDimensions.radiusDetailAvatar,
      backgroundColor:
          avatarBackgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundColor: fgColor,
      child:
          avatarChild ??
          (avatarText != null
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          avatarText!,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: hasSubtext
                                ? AppDimensions.lineHeightTight
                                : null,
                            color: fgColor,
                          ),
                        ),
                        if (hasSubtext) ...[
                          AppSpacings.gapXs,
                          Text(
                            avatarSubtext!,
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
              : null),
    );
  }
}
