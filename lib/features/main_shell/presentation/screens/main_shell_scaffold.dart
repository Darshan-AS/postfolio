import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.breakpointTablet) {
          // Tablet / Desktop layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDashboardSquare01,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(t.nav.dashboard),
                    ),
                    NavigationRailDestination(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedInvoice01,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(t.nav.oneTimeDeposits),
                    ),
                    NavigationRailDestination(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTransaction,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(t.nav.recurringDeposits),
                    ),
                    NavigationRailDestination(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserMultiple,
                        size: AppDimensions.iconMd,
                      ),
                      label: Text(t.nav.customers),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            destinations: [
              NavigationDestination(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDashboardSquare01,
                  size: AppDimensions.iconMd,
                ),
                label: t.nav.dashboard,
              ),
              NavigationDestination(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  size: AppDimensions.iconMd,
                ),
                label: t.nav.oneTimeDeposits,
              ),
              NavigationDestination(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTransaction,
                  size: AppDimensions.iconMd,
                ),
                label: t.nav.recurringDeposits,
              ),
              NavigationDestination(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserMultiple,
                  size: AppDimensions.iconMd,
                ),
                label: t.nav.customers,
              ),
            ],
          ),
        );
      },
    );
  }
}
