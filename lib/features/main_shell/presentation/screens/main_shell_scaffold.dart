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
  }
}
