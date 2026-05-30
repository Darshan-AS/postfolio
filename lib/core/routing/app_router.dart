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
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/routing/app_routes.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _depositsNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _rdNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _customersNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  final listenable = ValueNotifier<bool>(false);

  ref.listen(authControllerProvider, (prev, next) {
    listenable.value = !listenable.value;
  });

  ref.onDispose(() => listenable.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.customers,
    routes: $appRoutes,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      final isAuth = authState is AuthStateAuthenticated;

      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      if (!isAuth && !isLoggingIn) {
        return AppRoutes.login;
      }

      if (isAuth && isLoggingIn) {
        return AppRoutes.customers;
      }

      return null;
    },
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
              path: AppRoutes.otdIdParam,
              routes: [
                TypedGoRoute<OneTimeDepositEditRoute>(
                  path: AppRoutes.editRoute,
                ),
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
              path: AppRoutes.rdIdParam,
              routes: [
                TypedGoRoute<RecurringDepositEditRoute>(
                  path: AppRoutes.editRoute,
                ),
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

  static final GlobalKey<NavigatorState> $navigatorKey = _dashboardNavigatorKey;
}

class DepositsBranch extends StatefulShellBranchData {
  const DepositsBranch();

  static final GlobalKey<NavigatorState> $navigatorKey = _depositsNavigatorKey;
}

class RdBranch extends StatefulShellBranchData {
  const RdBranch();

  static final GlobalKey<NavigatorState> $navigatorKey = _rdNavigatorKey;
}

class CustomersBranch extends StatefulShellBranchData {
  const CustomersBranch();

  static final GlobalKey<NavigatorState> $navigatorKey = _customersNavigatorKey;
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
  final String otdId;
  const OneTimeDepositDetailRoute(this.otdId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OneTimeDepositDetailScreen(depositId: otdId);
  }
}

class OneTimeDepositEditRoute extends GoRouteData
    with $OneTimeDepositEditRoute {
  final String otdId;
  const OneTimeDepositEditRoute(this.otdId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return OneTimeDepositFormScreen(depositId: otdId);
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
  final String rdId;
  const RecurringDepositDetailRoute(this.rdId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RecurringDepositDetailScreen(depositId: rdId);
  }
}

class RecurringDepositEditRoute extends GoRouteData
    with $RecurringDepositEditRoute {
  final String rdId;
  const RecurringDepositEditRoute(this.rdId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RecurringDepositFormScreen(depositId: rdId);
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

@TypedGoRoute<LoginRoute>(path: AppRoutes.login)
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}
