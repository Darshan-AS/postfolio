import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one customer of [pumpSignedInApp]'s default list.
const rameshRao = Customer(
  id: 'cust-1',
  name: 'Ramesh Rao',
  phone: '9876543210',
  email: 'ramesh@example.com',
);

/// The size of the phone [pumpSignedInApp] runs on.
const phoneSize = Size(412, 915);

/// What a test asks of the running router.
typedef AppRouter = ({
  /// Where the router is.
  String Function() location,

  /// The root navigator, which holds every detail and form screen.
  NavigatorState Function() root,
});

/// Pumps the whole app, signed in, on a phone, through the real router: the Customers tab
/// with one customer in it.
///
/// [customers] replaces the customer repository, for a test that needs it to answer late.
/// [disableAnimations] is the device's "remove animations" setting.
Future<AppRouter> pumpSignedInApp(
  WidgetTester tester, {
  CustomerRepository? customers,
  bool disableAnimations = false,
}) async {
  await LocaleSettings.setLocale(AppLocale.en);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final authRepo = FakeAuthRepository(
    initialUser: const AuthUser(
      id: 'agent-1',
      email: 'agent@postfolio.com',
      displayName: 'Agent',
    ),
  );
  final rdRepo = FakeRecurringDepositRepository(deposits: const []);
  final ledgerRepo = FakeRDLedgerRepository();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
      authRepositoryProvider.overrideWithValue(authRepo),
      customerRepositoryProvider.overrideWithValue(
        customers ??
            FakeCustomerRepository(customers: const [rameshRao], delay: Duration.zero),
      ),
      oneTimeDepositRepositoryProvider.overrideWithValue(
        FakeOneTimeDepositRepository(deposits: const [], delay: Duration.zero),
      ),
      recurringDepositRepositoryProvider.overrideWithValue(rdRepo),
      rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
    ],
  );
  addTearDown(() {
    authRepo.dispose();
    rdRepo.dispose();
    ledgerRepo.dispose();
    container.dispose();
  });

  tester.view.physicalSize = phoneSize * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final router = container.read(goRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocaleUtils.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (
    location: () => router.state.uri.toString(),
    root: () => router.configuration.navigatorKey.currentState!,
  );
}
