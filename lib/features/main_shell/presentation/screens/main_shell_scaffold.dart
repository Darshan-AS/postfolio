import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/widgets/common/demo_banner.dart';
import 'package:postfolio/core/widgets/common/local_backend_banner.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/admin/presentation/widgets/admin_agent_picker_sheet.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
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
    final isDemoMode = ref.watch(demoModeProvider);
    final hasTopBanner =
        isDemoMode || ref.watch(localBackendBannerVisibleProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final showSwitchAccount = isAdmin && !isDemoMode;
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

    // Use a Builder so that any MediaQuery modifications grab the data
    // from INSIDE the Scaffold, after the Scaffold has already handled
    // the keyboard viewInsets. Using the outer context bypasses the Scaffold's
    // inset consumption, causing "Double Inset" layout bugs.
    Widget shellContent = Builder(
      builder: (innerContext) {
        if (hasTopBanner) {
          return MediaQuery.removePadding(
            context: innerContext,
            removeTop: true,
            child: navigationShell,
          );
        }
        return navigationShell;
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.breakpointTablet) {
          // Tablet / Desktop layout
          return Scaffold(
            body: Column(
              children: [
                const DemoBanner(),
                const LocalBackendBanner(),
                Expanded(
                  child: Row(
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
                              if (showSwitchAccount) ...[
                                IconButton(
                                  key: const ValueKey(
                                    'admin_switch_account_button',
                                  ),
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedUserSwitch,
                                    size: AppDimensions.iconMd,
                                  ),
                                  onPressed: () =>
                                      AdminAgentPickerSheet.show(context),
                                  tooltip: t.admin.switchAccount,
                                ),
                                AppSpacings.gapSm,
                              ],
                              IconButton(
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedLogout01,
                                  size: AppDimensions.iconMd,
                                ),
                                onPressed: () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .signOut();
                                },
                                tooltip: t.auth.signOut,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: shellContent),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          body: Column(
            children: [
              const DemoBanner(),
              const LocalBackendBanner(),
              Expanded(child: shellContent),
            ],
          ),
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
