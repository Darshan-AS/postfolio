import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one customer of [pumpSignedInApp]'s default list.
const rameshRao = Customer(
  id: 'cust-1',
  name: 'Ramesh Rao',
  phone: '9876543210',
  email: 'ramesh@example.com',
);

/// A time deposit of [rameshRao]'s, for a test that puts one in the list.
final rameshTimeDeposit = OneTimeDeposit(
  id: 'otd-1',
  accountNo: '500600701',
  principalAmount: 100000,
  termYears: 5,
  termMonths: 0,
  interestRate: 7.5,
  customerId: rameshRao.id,
  customerName: rameshRao.name,
  schemeType: OneTimeSchemeType.timeDeposit,
  startDate: DateTime(2025, 4, 20),
);

/// A recurring deposit of [rameshRao]'s, for a test that puts one in the list.
final rameshRecurringDeposit = RecurringDeposit(
  id: 'rd-1',
  serialNo: '7',
  accountNo: '100200301',
  installmentAmount: 2000,
  termYears: 5,
  termMonths: 0,
  interestRate: 6.7,
  customerId: rameshRao.id,
  customerName: rameshRao.name,
  schemeType: RecurringSchemeType.recurringDeposit,
  startDate: DateTime(2026, 1, 10),
);

/// A customer repository whose full record of a customer arrives only when the test says
/// so, as it does from a server. The list answers at once.
class LateCustomerRepository extends FakeCustomerRepository {
  LateCustomerRepository() : super(customers: const [rameshRao], delay: Duration.zero);

  final Completer<void> _answered = Completer<void>();

  void answer() => _answered.complete();

  @override
  Stream<Result<Customer, String>> watchCustomerById(String id) async* {
    await _answered.future;
    yield* super.watchCustomerById(id);
  }
}

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
/// [customers], [oneTimeDeposits] and [recurringDeposits] replace the repositories: with
/// other records, or with one that answers late. The lists of deposits are empty otherwise.
/// [disableAnimations] is the device's "remove animations" setting.
Future<AppRouter> pumpSignedInApp(
  WidgetTester tester, {
  CustomerRepository? customers,
  OneTimeDepositRepository? oneTimeDeposits,
  FakeRecurringDepositRepository? recurringDeposits,
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
  final rdRepo = recurringDeposits ?? FakeRecurringDepositRepository(deposits: const []);
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
        oneTimeDeposits ??
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
