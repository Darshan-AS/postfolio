/// Centralized routing paths and names to avoid hardcoding strings across the app.
class RouteNames {
  static const dashboard = '/dashboard';
  static const deposits = '/deposits';
  static const rd = '/rd';

  // Users
  static const users = '/users';
  static const userCreate = '/users/new';

  // Dynamic Route Builders
  static String userDetail(String id) => '/users/$id';
  static String userEdit(String id) => '/users/$id/edit';
}
