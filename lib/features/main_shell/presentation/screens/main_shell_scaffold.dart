import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/profile/presentation/widgets/agent_avatar.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/routing/app_router.dart';

class MainShellScaffold extends ConsumerWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(BuildContext context, int index) {
    if (index == navigationShell.currentIndex) {
      // If already on this tab, go to the root of the branch
      // to provide "pop to root" behavior declaratively.
      switch (index) {
        case 0:
          const DashboardRoute().go(context);
        case 1:
          const OneTimeDepositsRoute().go(context);
        case 2:
          const RecurringDepositsRoute().go(context);
        case 3:
          const CustomersRoute().go(context);
      }
    } else {
      navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accounts two or more months behind, from the one-row-per-account summary cache.
    final arrears = ref.watch(
      globalAgentFloatProvider.select((float) => float.arrearsAccounts),
    );

    final destinations = [
      AppDestination(
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        label: t.nav.dashboard,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
        label: t.nav.oneTimeDeposits,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedTransaction,
        label: t.nav.recurringDeposits,
        badgeCount: arrears > 0 ? arrears : null,
        badgeSemanticLabel: arrears > 0
            ? t.nav.recurringDepositsInArrears(n: arrears)
            : null,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedUserMultiple,
        label: t.nav.customers,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.breakpointTablet) {
          // Tablet / Desktop layout: rail carries Settings + Avatar, so ShellAppBar omits it.
          return Scaffold(
            body: Row(
              children: [
                AppNavigationRail(
                  destinations: destinations,
                  selectedIndex: navigationShell.currentIndex,
                  onSelected: (index) => _goBranch(context, index),
                  trailing: Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.paddingLg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: const ValueKey('rail_settings_button'),
                          tooltip: t.settings.title,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            size: AppDimensions.iconMd,
                          ),
                          onPressed: () => const SettingsRoute().push(context),
                        ),
                        AppSpacings.gapSm,
                        const AgentAvatarButton(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ShellLayoutScope(
                    hasRail: true,
                    child: navigationShell,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppNavigationBar(
            destinations: destinations,
            selectedIndex: navigationShell.currentIndex,
            onSelected: (index) => _goBranch(context, index),
          ),
        );
      },
    );
  }
}
