// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$mainShellRoute];

RouteBase get $mainShellRoute => StatefulShellRouteData.$route(
  factory: $MainShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/dashboard',
          factory: $DashboardRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/deposits',
          factory: $OneTimeDepositsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              factory: $OneTimeDepositCreateRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':depositId',
              factory: $OneTimeDepositDetailRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'edit',
                  factory: $OneTimeDepositEditRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/rd',
          factory: $RecurringDepositsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              factory: $RecurringDepositCreateRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':depositId',
              factory: $RecurringDepositDetailRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'edit',
                  factory: $RecurringDepositEditRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/customers',
          factory: $CustomersRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              factory: $CustomerCreateRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':customerId',
              factory: $CustomerDetailRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'edit',
                  factory: $CustomerEditRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $MainShellRouteExtension on MainShellRoute {
  static MainShellRoute _fromState(GoRouterState state) =>
      const MainShellRoute();
}

mixin $DashboardRoute on GoRouteData {
  static DashboardRoute _fromState(GoRouterState state) =>
      const DashboardRoute();

  @override
  String get location => GoRouteData.$location('/dashboard');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OneTimeDepositsRoute on GoRouteData {
  static OneTimeDepositsRoute _fromState(GoRouterState state) =>
      const OneTimeDepositsRoute();

  @override
  String get location => GoRouteData.$location('/deposits');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OneTimeDepositCreateRoute on GoRouteData {
  static OneTimeDepositCreateRoute _fromState(GoRouterState state) =>
      const OneTimeDepositCreateRoute();

  @override
  String get location => GoRouteData.$location('/deposits/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OneTimeDepositDetailRoute on GoRouteData {
  static OneTimeDepositDetailRoute _fromState(GoRouterState state) =>
      OneTimeDepositDetailRoute(state.pathParameters['depositId']!);

  OneTimeDepositDetailRoute get _self => this as OneTimeDepositDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/deposits/${Uri.encodeComponent(_self.depositId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OneTimeDepositEditRoute on GoRouteData {
  static OneTimeDepositEditRoute _fromState(GoRouterState state) =>
      OneTimeDepositEditRoute(state.pathParameters['depositId']!);

  OneTimeDepositEditRoute get _self => this as OneTimeDepositEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/deposits/${Uri.encodeComponent(_self.depositId)}/edit',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RecurringDepositsRoute on GoRouteData {
  static RecurringDepositsRoute _fromState(GoRouterState state) =>
      const RecurringDepositsRoute();

  @override
  String get location => GoRouteData.$location('/rd');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RecurringDepositCreateRoute on GoRouteData {
  static RecurringDepositCreateRoute _fromState(GoRouterState state) =>
      const RecurringDepositCreateRoute();

  @override
  String get location => GoRouteData.$location('/rd/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RecurringDepositDetailRoute on GoRouteData {
  static RecurringDepositDetailRoute _fromState(GoRouterState state) =>
      RecurringDepositDetailRoute(state.pathParameters['depositId']!);

  RecurringDepositDetailRoute get _self => this as RecurringDepositDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/rd/${Uri.encodeComponent(_self.depositId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RecurringDepositEditRoute on GoRouteData {
  static RecurringDepositEditRoute _fromState(GoRouterState state) =>
      RecurringDepositEditRoute(state.pathParameters['depositId']!);

  RecurringDepositEditRoute get _self => this as RecurringDepositEditRoute;

  @override
  String get location =>
      GoRouteData.$location('/rd/${Uri.encodeComponent(_self.depositId)}/edit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomersRoute on GoRouteData {
  static CustomersRoute _fromState(GoRouterState state) =>
      const CustomersRoute();

  @override
  String get location => GoRouteData.$location('/customers');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomerCreateRoute on GoRouteData {
  static CustomerCreateRoute _fromState(GoRouterState state) =>
      const CustomerCreateRoute();

  @override
  String get location => GoRouteData.$location('/customers/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomerDetailRoute on GoRouteData {
  static CustomerDetailRoute _fromState(GoRouterState state) =>
      CustomerDetailRoute(state.pathParameters['customerId']!);

  CustomerDetailRoute get _self => this as CustomerDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/customers/${Uri.encodeComponent(_self.customerId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomerEditRoute on GoRouteData {
  static CustomerEditRoute _fromState(GoRouterState state) =>
      CustomerEditRoute(state.pathParameters['customerId']!);

  CustomerEditRoute get _self => this as CustomerEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/customers/${Uri.encodeComponent(_self.customerId)}/edit',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
