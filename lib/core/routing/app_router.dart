import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/deposits/presentation/screens/deposits_screen.dart';
import 'package:postfolio/features/main_shell/presentation/screens/main_shell_scaffold.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/rd_screen.dart';
import 'package:postfolio/features/users/presentation/screens/user_detail_screen.dart';
import 'package:postfolio/features/users/presentation/screens/user_form_screen.dart';
import 'package:postfolio/features/users/presentation/screens/users_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/users', // Defaulting to users tab
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/deposits',
                builder: (context, state) => const DepositsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rd',
                builder: (context, state) => const RdScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const UsersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const UserFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => UserDetailScreen(userId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => UserFormScreen(userId: state.pathParameters['id']),
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
