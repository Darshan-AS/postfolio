import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/main_shell/presentation/screens/main_shell_scaffold.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_form_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/core/routing/app_routes.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.customers,
    routes: $appRoutes,
  );
}

@TypedStatefulShellRoute<MainShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<DashboardBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<DashboardRoute>(path: AppRoutes.dashboard),
      ],
    ),
    TypedStatefulShellBranch<DepositsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<OneTimeDepositsRoute>(
          path: AppRoutes.deposits,
          routes: [
            TypedGoRoute<OneTimeDepositCreateRoute>(path: AppRoutes.newRoute),
            TypedGoRoute<OneTimeDepositDetailRoute>(
              path: AppRoutes.depositIdParam,
              routes: [
                TypedGoRoute<OneTimeDepositEditRoute>(path: AppRoutes.editRoute),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<RdBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<RecurringDepositsRoute>(
          path: AppRoutes.rd,
          routes: [
            TypedGoRoute<RecurringDepositCreateRoute>(path: AppRoutes.newRoute),
            TypedGoRoute<RecurringDepositDetailRoute>(
              path: AppRoutes.depositIdParam,
              routes: [
                TypedGoRoute<RecurringDepositEditRoute>(path: AppRoutes.editRoute),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CustomersBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CustomersRoute>(
          path: AppRoutes.customers,
          routes: [
            TypedGoRoute<CustomerCreateRoute>(path: AppRoutes.newRoute),
            TypedGoRoute<CustomerDetailRoute>(
              path: AppRoutes.customerIdParam,
              routes: [
                TypedGoRoute<CustomerEditRoute>(path: AppRoutes.editRoute),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  const MainShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MainShellScaffold(navigationShell: navigationShell);
  }
}

class DashboardBranch extends StatefulShellBranchData {
  const DashboardBranch();
}

class DepositsBranch extends StatefulShellBranchData {
  const DepositsBranch();
}

class RdBranch extends StatefulShellBranchData {
  const RdBranch();
}

class CustomersBranch extends StatefulShellBranchData {
  const CustomersBranch();
}

class DashboardRoute extends GoRouteData with $DashboardRoute {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardScreen();
  }
}

class OneTimeDepositsRoute extends GoRouteData with $OneTimeDepositsRoute {
  const OneTimeDepositsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OneTimeDepositsScreen();
  }
}

class OneTimeDepositCreateRoute extends GoRouteData
    with $OneTimeDepositCreateRoute {
  const OneTimeDepositCreateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OneTimeDepositFormScreen();
  }
}

class OneTimeDepositDetailRoute extends GoRouteData
    with $OneTimeDepositDetailRoute {
  final String depositId;
  const OneTimeDepositDetailRoute(this.depositId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OneTimeDepositDetailScreen(depositId: depositId);
  }
}

class OneTimeDepositEditRoute extends GoRouteData
    with $OneTimeDepositEditRoute {
  final String depositId;
  const OneTimeDepositEditRoute(this.depositId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OneTimeDepositFormScreen(depositId: depositId);
  }
}

class RecurringDepositsRoute extends GoRouteData with $RecurringDepositsRoute {
  const RecurringDepositsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RecurringDepositsScreen();
  }
}

class RecurringDepositCreateRoute extends GoRouteData
    with $RecurringDepositCreateRoute {
  const RecurringDepositCreateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RecurringDepositFormScreen();
  }
}

class RecurringDepositDetailRoute extends GoRouteData
    with $RecurringDepositDetailRoute {
  final String depositId;
  const RecurringDepositDetailRoute(this.depositId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RecurringDepositDetailScreen(depositId: depositId);
  }
}

class RecurringDepositEditRoute extends GoRouteData
    with $RecurringDepositEditRoute {
  final String depositId;
  const RecurringDepositEditRoute(this.depositId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RecurringDepositFormScreen(depositId: depositId);
  }
}

class CustomersRoute extends GoRouteData with $CustomersRoute {
  const CustomersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomersScreen();
  }
}

class CustomerCreateRoute extends GoRouteData with $CustomerCreateRoute {
  const CustomerCreateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CustomerFormScreen();
  }
}

class CustomerDetailRoute extends GoRouteData with $CustomerDetailRoute {
  final String customerId;
  const CustomerDetailRoute(this.customerId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CustomerDetailScreen(customerId: customerId);
  }
}

class CustomerEditRoute extends GoRouteData with $CustomerEditRoute {
  final String customerId;
  const CustomerEditRoute(this.customerId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CustomerFormScreen(customerId: customerId);
  }
}
