import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AccessibleThemeToggle extends ConsumerWidget {
  const AccessibleThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccessibleTheme =
        ref.watch(themeModeProvider) == AppThemeMode.accessibleSystem;
    return IconButton(
      isSelected: isAccessibleTheme,
      icon: Icon(
        Icons.contrast,
        size: AppDimensions.iconMd,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        Icons.contrast,
        size: AppDimensions.iconMd,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isAccessibleTheme
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleAccessibleTheme();
      },
      tooltip: t.common.toggleAccessibleTheme,
    );
  }
}
