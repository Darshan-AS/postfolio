import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            size: AppDimensions.iconMd,
          ),
          onPressed: () {},
        ),
        title: Text(t.nav.dashboard),
        actions: [
          Consumer(
            builder: (context, ref, child) {
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
            },
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: t.auth.signOut,
          ),
        ],
      ),
      body: const SizedBox.shrink(),
    );
  }
}
