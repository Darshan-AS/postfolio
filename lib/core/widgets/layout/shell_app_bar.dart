import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/accessible_theme_toggle.dart';

class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const ShellAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedMenu01,
          size: AppDimensions.iconMd,
        ),
        onPressed: () {},
      ),
      title: Text(title),
      actions: [
        const AccessibleThemeToggle(),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
