import 'package:material_3_expressive/components/extended_fabs/m3e_extended_fabs.dart';
import 'package:material_3_expressive/components/fab_menu/m3e_fab_menu.dart';
import 'package:material_3_expressive/components/floating_action_buttons/m3e_floating_action_buttons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// A Material 3 Expressive floating action button with a label: the one main action of a
/// screen.
///
/// The community widget lays its icon and label out in a row that overflows when the label
/// is wider than the window (large text, long translations). Two guards keep it inside:
/// the label stops growing at [_maxLabelTextScale], and if the button is still wider than
/// the window less its margins it is scaled down to fit.
class AppExtendedFab extends StatelessWidget {
  const AppExtendedFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final AppIconData icon;
  final VoidCallback? onPressed;

  static const double _maxLabelTextScale = 1.3;

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
          child: M3EExtendedFab(
            label: label,
            icon: AppIcon(icon, size: AppDimensions.iconMd),
            onPressed: onPressed,
          ),
        ),
      ),
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
