import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/i18n/strings.g.dart';

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
            ),
            label: t.nav.dashboard,
          ),
          NavigationDestination(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01),
            label: t.nav.oneTimeDeposits,
          ),
          NavigationDestination(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedTransaction,
            ),
            label: t.nav.recurringDeposits,
          ),
          NavigationDestination(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple),
            label: t.nav.customers,
          ),
        ],
      ),
    );
  }
}
