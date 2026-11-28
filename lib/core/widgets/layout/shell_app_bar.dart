import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';
import 'package:postfolio/features/profile/presentation/widgets/agent_avatar.dart';

/// Informs [ShellAppBar] whether an enclosing navigation rail already displays the
/// account/settings controls so tablet and desktop layouts do not duplicate the avatar.
class ShellLayoutScope extends InheritedWidget {
  const ShellLayoutScope({
    super.key,
    required this.hasRail,
    required super.child,
  });

  final bool hasRail;

  static bool hasRailOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellLayoutScope>()?.hasRail ??
      false;

  @override
  bool updateShouldNotify(ShellLayoutScope oldWidget) =>
      hasRail != oldWidget.hasRail;
}

/// App bar of the four top-level destinations: the destination's title, the screen's own
/// actions, then the trailing agent avatar on compact screens (which opens Settings & Profile).
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
    final showAvatar = !ShellLayoutScope.hasRailOf(context);
    final hasTrailingContent =
        showAvatar || (actions != null && actions!.isNotEmpty);

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
        ...?actions,
        if (showAvatar) const AgentAvatarButton(),
        // The 32dp avatar sits 8dp inside its 48dp button, so 8dp here ends its outer
        // edge on the 16dp page margin, where the title starts on the other side.
        if (hasTrailingContent) const SizedBox(width: AppDimensions.paddingSm),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
