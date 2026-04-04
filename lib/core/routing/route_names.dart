/// Centralized routing paths and names to avoid hardcoding strings across the app.
class RouteNames {
  static const dashboard = '/dashboard';

  static const deposits = '/deposits';
  static const oneTimeCreate = '/deposits/new';
  static String oneTimeDetail(String id) => '/deposits/$id';
  static String oneTimeEdit(String id) => '/deposits/$id/edit';

  static const rd = '/rd';
  static const rdCreate = '/rd/new';
  static String rdDetail(String id) => '/rd/$id';
  static String rdEdit(String id) => '/rd/$id/edit';

  // Users
  static const users = '/users';
  static const userCreate = '/users/new';

  // Dynamic Route Builders
  static String userDetail(String id) => '/users/$id';
  static String userEdit(String id) => '/users/$id/edit';
}
