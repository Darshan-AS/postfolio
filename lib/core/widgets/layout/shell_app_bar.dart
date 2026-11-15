import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/accessible_theme_toggle.dart';

/// App bar of the four top-level destinations: the destination's title, the theme switcher,
/// then the screen's own actions.
class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const ShellAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      actions: [
        const AccessibleThemeToggle(),
        ...?actions,
        const SizedBox(width: AppDimensions.paddingSm),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
