import 'package:material_3_expressive/components/navigation_bar/m3e_navigation_bar.dart';
import 'package:material_3_expressive/components/navigation_rail/m3e_navigation_rail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

/// A top-level destination of the app.
class AppDestination {
  const AppDestination({required this.icon, required this.label});

  final AppIconData icon;
  final String label;
}

/// Icon labels in navigation chrome stop growing at this text scale, as in the official
/// `NavigationBar`: a four-destination bar has no room for 2x labels, and the community
/// widget would otherwise break them mid-word.
const double _maxLabelTextScale = 1.3;

/// The Material 3 Expressive bottom navigation bar for compact windows.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScale,
      child: M3ENavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            M3ENavigationBarDestination(
              icon: AppIcon(destination.icon, size: AppDimensions.iconMd),
              selectedIcon: AppIcon(
                destination.icon,
                size: AppDimensions.iconMd,
                emphasized: true,
              ),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

/// The Material 3 Expressive navigation rail for medium and expanded windows.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.trailing,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Pinned to the bottom of the rail (e.g. sign out).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScale,
      child: M3ENavigationRail(
        type: M3ENavigationRailType.alwaysCollapse,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        trailing: trailing,
        sections: [
          M3ENavigationRailSection(
            destinations: [
              for (final destination in destinations)
                M3ENavigationRailDestination(
                  icon: AppIcon(destination.icon, size: AppDimensions.iconMd),
                  selectedIcon: AppIcon(
                    destination.icon,
                    size: AppDimensions.iconMd,
                    emphasized: true,
                  ),
                  label: destination.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
