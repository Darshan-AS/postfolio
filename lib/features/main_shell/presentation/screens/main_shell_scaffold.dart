import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
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
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.paddingLg,
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            return IconButton(
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedLogout01,
                                size: AppDimensions.iconMd,
                              ),
                              onPressed: () {
                                ref.read(authControllerProvider.notifier).signOut();
                              },
                              tooltip: t.auth.signOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
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
