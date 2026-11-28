import 'package:postfolio/core/routing/app_routes.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum AppStartTab {
  customers,
  dashboard,
  oneTimeDeposits,
  recurringDeposits,
  monthlyHub;

  String get displayName => t.enums.startTab[name] ?? name;

  String get routeLocation => switch (this) {
    AppStartTab.customers => AppRoutes.customers,
    AppStartTab.dashboard => AppRoutes.dashboard,
    AppStartTab.oneTimeDeposits => AppRoutes.deposits,
    AppStartTab.recurringDeposits => AppRoutes.rd,
    AppStartTab.monthlyHub => AppRoutes.rdHubLocation,
  };
}
