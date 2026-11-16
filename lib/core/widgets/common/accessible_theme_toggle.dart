import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AccessibleThemeToggle extends ConsumerWidget {
  const AccessibleThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final strings = t.common.theme;

    final options = <({
      AppThemeMode mode,
      String key,
      String label,
      List<List<dynamic>> icon,
    })>[
      (
        mode: AppThemeMode.system,
        key: 'theme_mode_system',
        label: strings.system,
        icon: HugeIcons.strokeRoundedSmartPhone01,
      ),
      (
        mode: AppThemeMode.light,
        key: 'theme_mode_light',
        label: strings.light,
        icon: HugeIcons.strokeRoundedSun03,
      ),
      (
        mode: AppThemeMode.dark,
        key: 'theme_mode_dark',
        label: strings.dark,
        icon: HugeIcons.strokeRoundedMoon02,
      ),
      (
        mode: AppThemeMode.accessibleSystem,
        key: 'theme_mode_accessible',
        label: strings.accessible,
        icon: HugeIcons.strokeRoundedEye,
      ),
    ];

    final activeIcon = switch (activeMode) {
      AppThemeMode.system => HugeIcons.strokeRoundedSmartPhone01,
      AppThemeMode.light => HugeIcons.strokeRoundedSun03,
      AppThemeMode.dark => HugeIcons.strokeRoundedMoon02,
      AppThemeMode.accessibleSystem => HugeIcons.strokeRoundedEye,
    };

    return MenuAnchor(
      menuChildren: [
        for (final opt in options)
          MenuItemButton(
            key: ValueKey(opt.key),
            leadingIcon: HugeIcon(
              icon: opt.icon,
              size: AppDimensions.iconSm,
              color: activeMode == opt.mode
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            trailingIcon: activeMode == opt.mode
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    size: AppDimensions.iconSm,
                    color: scheme.primary,
                  )
                : null,
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(opt.mode);
            },
            child: Text(
              opt.label,
              style: TextStyle(
                fontWeight: activeMode == opt.mode
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const ValueKey('theme_mode_selector_button'),
        isSelected: activeMode != AppThemeMode.system,
        tooltip: t.common.toggleAccessibleTheme,
        style: IconButton.styleFrom(
          backgroundColor: activeMode == AppThemeMode.accessibleSystem
              ? scheme.primaryContainer
              : null,
        ),
        icon: HugeIcon(
          icon: activeIcon,
          size: AppDimensions.iconMd,
          color: activeMode == AppThemeMode.accessibleSystem
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
    );
  }
}
