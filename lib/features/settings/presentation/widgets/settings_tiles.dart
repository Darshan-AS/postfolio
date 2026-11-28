import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/start_tab.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

typedef SettingsTileBuilder = Widget Function(AppGroupPosition position);

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.itemBuilders});

  final List<SettingsTileBuilder> itemBuilders;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itemBuilders.length; i++) ...[
          if (i > 0) const SizedBox(height: AppShapes.groupGap),
          itemBuilders[i](AppGroupPosition.at(i, itemBuilders.length)),
        ],
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.position,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final AppGroupPosition position;
  final List<List<dynamic>> icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasTrailingButton = trailing != null && !showChevron;

    return AppGroupTile(
      position: position,
      onTap: onTap,
      child: MetaData(
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.rowMinHeight,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppDimensions.paddingLg,
              end: hasTrailingButton
                  ? AppDimensions.paddingXs
                  : AppDimensions.paddingLg,
              top: AppDimensions.paddingMd,
              bottom: AppDimensions.paddingMd,
            ),
            child: Row(
              children: [
                AppIcon(
                  icon,
                  size: AppDimensions.iconMd,
                  color: scheme.onSurfaceVariant,
                ),
                AppSpacings.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.emphasizedOf(context).bodyLarge,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        AppSpacings.gapXxs,
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[AppSpacings.gapSm, trailing!],
                if (showChevron && trailing == null) ...[
                  AppSpacings.gapSm,
                  AppIcon(
                    HugeIcons.strokeRoundedArrowRight01,
                    size: AppDimensions.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.position,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AppGroupPosition position;
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onChanged != null;

    return MergeSemantics(
      child: AppGroupTile(
        position: position,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: MetaData(
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.rowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppDimensions.paddingLg,
                end: AppDimensions.paddingMd,
                top: AppDimensions.paddingMd,
                bottom: AppDimensions.paddingMd,
              ),
              child: Row(
                children: [
                  AppIcon(
                    icon,
                    size: AppDimensions.iconMd,
                    color: enabled
                        ? scheme.onSurfaceVariant
                        : scheme.onSurfaceVariant.withValues(
                            alpha: AppDimensions.opacityDisabled,
                          ),
                  ),
                  AppSpacings.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.emphasizedOf(context).bodyLarge
                              ?.copyWith(
                                color: enabled
                                    ? scheme.onSurface
                                    : scheme.onSurface.withValues(
                                        alpha: AppDimensions.opacityDisabled,
                                      ),
                              ),
                        ),
                        AppSpacings.gapXxs,
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacings.gapSm,
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StartTabOptionTile extends StatelessWidget {
  const StartTabOptionTile({
    super.key,
    required this.tab,
    required this.selected,
    required this.position,
    required this.onTap,
  });

  final AppStartTab tab;
  final bool selected;
  final AppGroupPosition position;
  final VoidCallback onTap;

  List<List<dynamic>> get _icon => switch (tab) {
    AppStartTab.customers => HugeIcons.strokeRoundedUserMultiple,
    AppStartTab.dashboard => HugeIcons.strokeRoundedDashboardSquare01,
    AppStartTab.oneTimeDeposits => HugeIcons.strokeRoundedMoneyReceiveSquare,
    AppStartTab.recurringDeposits => HugeIcons.strokeRoundedTransaction,
    AppStartTab.monthlyHub => HugeIcons.strokeRoundedCalendar03,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppGroupTile(
      position: position,
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        child: Row(
          children: [
            AppIcon(
              _icon,
              size: AppDimensions.iconMd,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
            AppSpacings.gapMd,
            Expanded(
              child: Text(
                tab.displayName,
                style: AppTypography.emphasizedOf(context).bodyLarge?.copyWith(
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
            if (selected)
              AppIcon(
                HugeIcons.strokeRoundedTick02,
                size: AppDimensions.iconMd,
                color: scheme.onSecondaryContainer,
              ),
          ],
        ),
      ),
    );
  }
}
