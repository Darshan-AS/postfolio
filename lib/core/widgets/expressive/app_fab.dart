import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_3_expressive/components/extended_fabs/m3e_extended_fabs.dart';
import 'package:material_3_expressive/components/fab_menu/m3e_fab_menu.dart';
import 'package:material_3_expressive/components/floating_action_buttons/m3e_floating_action_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// Joins an [AppExtendedFab] to the list under it (see [AppExtendedFabScrollArea]).
typedef AppExtendedFabController = M3EExtendedFabController;

/// The controller of a screen's [AppExtendedFab], disposed with the screen.
///
/// [resetOn] is what decides the list's content (its search and filters). When it changes
/// the label comes back: the new content starts at its top, or is an empty message that
/// cannot be scrolled to bring the label back.
AppExtendedFabController useAppExtendedFabController({Object? resetOn}) {
  final controller = useMemoized(AppExtendedFabController.new);
  useEffect(() => controller.dispose, [controller]);
  useEffect(() {
    controller.expand();
    return null;
  }, [resetOn]);
  return controller;
}

/// A Material 3 Expressive floating action button with a label: the one main action of a
/// screen.
///
/// The community widget lays its icon and label out in a row that overflows when the label
/// is wider than the window (large text, long translations). Two guards keep it inside:
/// the label stops growing at [_maxLabelTextScale], and if the button is still wider than
/// the window less its margins it is scaled down to fit.
///
/// With a [controller] the button gives up its label while the list is scrolled down and
/// takes it back on the way up. A screen reader gets the whole label either way: the
/// community widget announces its first word only, twice while the label shows.
class AppExtendedFab extends StatelessWidget {
  const AppExtendedFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.controller,
  });

  final String label;
  final AppIconData icon;
  final VoidCallback? onPressed;

  /// From [useAppExtendedFabController], shared with an [AppExtendedFabScrollArea].
  final AppExtendedFabController? controller;

  static const double _maxLabelTextScale = AppDimensions.largeTextScale;

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.sizeOf(context).width - 2 * AppDimensions.pageMargin;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScale,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Semantics(
            container: true,
            button: true,
            enabled: onPressed != null,
            label: label,
            onTap: onPressed,
            excludeSemantics: true,
            child: M3EExtendedFab(
              controller: controller,
              label: label,
              icon: AppIcon(icon, size: AppDimensions.iconMd),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

/// The scrolling content an [AppExtendedFab] floats over. Scrolling it down leaves the
/// button as its icon, so less of the list is covered; scrolling up brings the label back.
///
/// A device set to remove animations keeps the label: the change is a motion.
class AppExtendedFabScrollArea extends StatelessWidget {
  const AppExtendedFabScrollArea({
    super.key,
    required this.controller,
    required this.child,
  });

  final AppExtendedFabController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return NotificationListener<ScrollNotification>(
      // The list's own scrolling only, not a row that scrolls sideways.
      onNotification: (notification) =>
          notification.metrics.axis == Axis.vertical &&
          controller.handleScrollNotification(notification),
      child: child,
    );
  }
}

/// One entry of an [AppFabMenu].
class AppFabMenuAction {
  const AppFabMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;
}

/// A Material 3 Expressive FAB menu: the FAB opens into two to six labelled actions and
/// turns into a close button.
class AppFabMenu extends StatelessWidget {
  const AppFabMenu({
    super.key,
    required this.icon,
    required this.closeIcon,
    required this.actions,
  }) : assert(actions.length >= 2 && actions.length <= 6);

  final AppIconData icon;
  final AppIconData closeIcon;
  final List<AppFabMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    return M3EFabMenu(
      size: M3EFabSize.regular,
      icon: AppIcon(icon, size: AppDimensions.iconMd),
      closeIcon: AppIcon(closeIcon, size: AppDimensions.iconMd),
      items: [
        for (final action in actions)
          M3EFabMenuItem(
            label: action.label,
            icon: AppIcon(action.icon, size: AppDimensions.iconMd),
            onPressed: action.onPressed,
          ),
      ],
    );
  }
}
