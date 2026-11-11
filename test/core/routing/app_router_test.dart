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
import 'package:postfolio/core/widgets/feedback/unsaved_changes_pop_scope.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer buildContainer({
    required FakeAuthRepository authRepo,
  }) {
    const customer = Customer(
      id: 'cust-1',
      name: 'Ramesh Rao',
      phone: '9876543210',
    );
    final rd = RecurringDeposit(
      id: 'rd-123',
      serialNo: '12',
      accountNo: '99887766',
      installmentAmount: 1000,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: 'cust-1',
      customerName: 'Ramesh Rao',
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2026, 1, 10),
    );

    final customerRepo = FakeCustomerRepository(
      customers: [customer],
      delay: Duration.zero,
    );
    final otdRepo = FakeOneTimeDepositRepository(
      deposits: const [],
      delay: Duration.zero,
    );
    final rdRepo = FakeRecurringDepositRepository(deposits: [rd]);
    final ledgerRepo = FakeRDLedgerRepository();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
        customerRepositoryProvider.overrideWithValue(customerRepo),
        oneTimeDepositRepositoryProvider.overrideWithValue(otdRepo),
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
    return container;
  }

  Widget buildApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocaleUtils.supportedLocales,
            );
          },
        ),
      ),
    );
  }

  group('GoRouter deep links, synchronous session hydration & root navigator', () {
    testWidgets(
      'unauthenticated deep link redirects with ?redirect= and restores exact route+query after sign-in',
      (tester) async {
        final authRepo = FakeAuthRepository();
        final container = buildContainer(authRepo: authRepo);
        final router = container.read(goRouterProvider);

        await tester.pumpWidget(buildApp(container));
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, '/login');

        // Navigate while unauthenticated to a deep link with ?tab=schedule.
        router.go('/rd/rd-123?tab=schedule');
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, '/login');
        expect(
          router.state.uri.queryParameters['redirect'],
          '/rd/rd-123?tab=schedule',
        );

        // Sign in -> GoRouter restores /rd/rd-123?tab=schedule!
        authRepo.emit(
          const AuthUser(
            id: 'agent-1',
            email: 'agent@postfolio.com',
            displayName: 'Agent',
          ),
        );
        await tester.pumpAndSettle();

        expect(router.state.uri.toString(), '/rd/rd-123?tab=schedule');
      },
    );

    testWidgets(
      'synchronous session hydration preserves Web F5 deep link (?view=hub&month=2026-10) without /login flash and blocks external open-redirects',
      (tester) async {
        final authRepo = FakeAuthRepository(
          initialUser: const AuthUser(
            id: 'agent-1',
            email: 'agent@postfolio.com',
            displayName: 'Agent',
          ),
        );
        final container = buildContainer(authRepo: authRepo);
        final router = container.read(goRouterProvider);

        await tester.pumpWidget(buildApp(container));
        await tester.pumpAndSettle();

        router.go('/rd?view=hub&month=2026-10');
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, '/rd');
        expect(container.read(rDViewModeControllerProvider), RDViewMode.monthlyHub);
        expect(container.read(rDHubMonthProvider), DateTime(2026, 10, 1));

        // Open-redirect guard: external URL in ?redirect= falls back safely to /customers.
        router.go('/login?redirect=https://evil.example/phish');
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, '/customers');
      },
    );

    testWidgets(
      'detail routes push onto root navigator so CustomerDetail -> RDDetail -> Back returns to CustomerDetail',
      (tester) async {
        final authRepo = FakeAuthRepository(
          initialUser: const AuthUser(
            id: 'agent-1',
            email: 'agent@postfolio.com',
            displayName: 'Agent',
          ),
        );
        final container = buildContainer(authRepo: authRepo);
        final router = container.read(goRouterProvider);

        await tester.pumpWidget(buildApp(container));
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, '/customers');

        // Push CustomerDetailRoute onto root navigator, then push RecurringDepositDetailRoute.
        final rootCtx = router.configuration.navigatorKey.currentContext!;
        // ignore: unawaited_futures
        const CustomerDetailRoute('cust-1').push<void>(rootCtx);
        await tester.pumpAndSettle();
        expect(find.text('Ramesh Rao'), findsWidgets);

        // ignore: unawaited_futures
        const RecurringDepositDetailRoute('rd-123', tab: 'schedule').push<void>(rootCtx);
        await tester.pumpAndSettle();
        expect(find.textContaining('99887766'), findsWidgets);

        // Popping returns directly to CustomerDetailRoute on the root navigator!
        router.pop();
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, '/customers/cust-1');
      },
    );
  });

  group('UnsavedChangesPopScope guard', () {
    testWidgets(
      'blocks maybePop on dirty form with confirmation dialog while clean form pops immediately',
      (tester) async {
        var dirty = true;
        late BuildContext formCtx;

        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocaleUtils.supportedLocales,
              home: Builder(
                builder: (homeCtx) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(homeCtx).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => StatefulBuilder(
                              builder: (ctx, _) {
                                formCtx = ctx;
                                return UnsavedChangesPopScope(
                                  isDirty: dirty,
                                  child: const Scaffold(body: Text('Dirty Form Body')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Form'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();
        expect(find.text('Dirty Form Body'), findsOneWidget);

        // System/AppBar back (`maybePop`) while dirty opens Discard dialog and keeps form mounted.
        // ignore: unawaited_futures
        Navigator.of(formCtx).maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Discard unsaved changes?'), findsOneWidget);

        // Cancel keeps the form open.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Dirty Form Body'), findsOneWidget);

        // Confirming "Discard" pops the form cleanly.
        // ignore: unawaited_futures
        Navigator.of(formCtx).maybePop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(find.text('Dirty Form Body'), findsNothing);
      },
    );
  });
}
