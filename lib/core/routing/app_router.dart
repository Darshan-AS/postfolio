import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/main_shell/presentation/screens/main_shell_scaffold.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_form_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/users/presentation/screens/user_detail_screen.dart';
import 'package:postfolio/features/users/presentation/screens/user_form_screen.dart';
import 'package:postfolio/features/users/presentation/screens/users_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.users, // Defaulting to users tab
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.deposits,
                builder: (context, state) => const OneTimeDepositsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const OneTimeDepositFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OneTimeDepositDetailScreen(
                      depositId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => OneTimeDepositFormScreen(
                      depositId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.rd,
                builder: (context, state) => const RecurringDepositsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const RecurringDepositFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => RecurringDepositDetailScreen(
                      depositId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => RecurringDepositFormScreen(
                      depositId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.users,
                builder: (context, state) => const UsersScreen(),
                routes: [
                  GoRoute(
                    path:
                        'new', // Note: GoRouter sub-routes should not start with a slash
                    builder: (context, state) => const UserFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        UserDetailScreen(userId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) =>
                        UserFormScreen(userId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
