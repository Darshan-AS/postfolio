import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/accessible_theme_toggle.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';

/// App bar of the four top-level destinations: the destination's title, the theme switcher,
/// then the screen's own actions.
class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  /// Shown in place of the [title] text, for a destination whose bar holds a control that
  /// names what is on screen (the Recurring tab's view switch). The navigation bar already
  /// names the destination; [title] is still what a screen reader calls the control.
  final Widget? titleControl;
  final List<Widget>? actions;

  const ShellAppBar({
    super.key,
    required this.title,
    this.titleControl,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: titleControl == null
          ? AppBarTitle(title)
          : Semantics(
              container: true,
              label: title,
              // Chrome of a fixed height: its labels stop growing where the navigation
              // bar's do, and the control shrinks rather than push the actions out.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: AppDimensions.largeTextScale,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: titleControl,
                ),
              ),
            ),
      actions: [
        const AccessibleThemeToggle(),
        ...?actions,
        // An icon is 12dp inside its 48dp button, so 4dp here ends the last icon on the
        // page margin, where the title starts on the other side. The detail screens' bar
        // does the same.
        const SizedBox(width: AppDimensions.paddingXs),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
