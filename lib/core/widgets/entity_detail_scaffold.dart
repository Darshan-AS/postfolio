import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';

class EntityDetailScaffold extends StatelessWidget {
  final String appBarTitle;
  final VoidCallback onEdit;
  final Future<String?> Function() onDelete;
  final String deleteDialogTitle;
  final String deleteDialogContent;
  final Widget header;
  final List<Widget> body;

  const EntityDetailScaffold({
    super.key,
    required this.appBarTitle,
    required this.onEdit,
    required this.onDelete,
    required this.deleteDialogTitle,
    required this.deleteDialogContent,
    required this.header,
    required this.body,
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
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: AppDimensions.iconMd,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: AppDimensions.iconMd,
            ),
            color: theme.colorScheme.error,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        children: [header, AppSpacings.gapXxl, ...body]
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
            )
            .shimmer(
              duration: AppAnimations.slow,
              color: theme.colorScheme.surfaceTint.withValues(alpha: 0.1),
            ),
      ),
    );
  }
}

class EntityDetailHeader extends StatelessWidget {
  final Widget avatarChild;
  final Color? avatarBackgroundColor;
  final Color? avatarForegroundColor;
  final String title;
  final Widget? subtitle;
  final Widget? badge;
  final List<Widget> bottomActions;

  const EntityDetailHeader({
    super.key,
    required this.avatarChild,
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
          CircleAvatar(
            radius: AppDimensions.iconXl * 1.5,
            backgroundColor:
                avatarBackgroundColor ?? theme.colorScheme.primaryContainer,
            foregroundColor:
                avatarForegroundColor ?? theme.colorScheme.onPrimaryContainer,
            child: avatarChild,
          ),
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
}
