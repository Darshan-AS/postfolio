import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingCustomerRepo extends FakeCustomerRepository {
  _FailingCustomerRepo();

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async =>
      const Failure('Customer save blocked');
}

class _FailingOtdRepo extends FakeOneTimeDepositRepository {
  _FailingOtdRepo();

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async => const Failure('Deposit save blocked');
}

Finder _fieldLabeled(String label) => find.ancestor(
  of: find.textContaining(label),
  matching: find.byType(TextFormField),
);

void main() {
  group('OneTimeDepositsScreen & OTD/Customer Form Hooks', () {
    Future<void> pumpWithRouter(
      WidgetTester tester, {
      required Widget child,
      CustomerRepository? customerRepo,
      OneTimeDepositRepository? otdRepo,
    }) async {
      final source = FakeDataSource();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => context.push('/target'),
                  child: const Text('Go Target'),
                ),
              ),
            ),
          ),
          GoRoute(path: '/target', builder: (_, _) => child),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
          customerRepositoryProvider.overrideWithValue(
            customerRepo ?? FakeCustomerRepository(customers: source.customers),
          ),
          oneTimeDepositRepositoryProvider.overrideWithValue(
            otdRepo ??
                FakeOneTimeDepositRepository(deposits: source.oneTimeDeposits),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Target'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'OneTimeDepositsScreen searches, opens sort & filter sheets, and resets empty filters',
      (tester) async {
        final source = FakeDataSource();
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
            customerRepositoryProvider.overrideWithValue(
              FakeCustomerRepository(customers: source.customers),
            ),
            oneTimeDepositRepositoryProvider.overrideWithValue(
              FakeOneTimeDepositRepository(deposits: source.oneTimeDeposits),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const OneTimeDepositsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Search narrows list, unmatched shows Clear Filters CTA.
        await tester.enterText(find.byType(SearchBar), 'NonExistentAccountXYZ');
        await tester.pumpAndSettle();
        expect(find.text(t.common.clearFilters), findsOneWidget);
        await tester.tap(find.text(t.common.clearFilters));
        await tester.pumpAndSettle();

        // Sort sheet opens, selects Amount, and closes via header close button.
        await tester.tap(find.byTooltip(t.sorting.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.sorting.properties['amount']!));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(t.common.close));
        await tester.pumpAndSettle();

        // Filter sheet toggles Status and Scheme filters then Clear + Close.
        await tester.tap(find.byTooltip(t.filters.title));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(OneTimeSchemeType.monthlyIncomeScheme.shortName),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(DepositStatus.closed.displayName));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.common.clear));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(t.common.close));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'CustomerFormScreen handles create failure snackbar, success pop, and edit DOB clear',
      (tester) async {
        // 1. Failing save displays error feedback.
        await pumpWithRouter(
          tester,
          child: const CustomerFormScreen(),
          customerRepo: _FailingCustomerRepo(),
        );
        await tester.enterText(
          _fieldLabeled(t.customers.fields.fullName),
          'Selina Kyle',
        );
        await tester.enterText(
          _fieldLabeled(t.customers.fields.phoneNumber),
          '9988776655',
        );
        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();
        expect(find.textContaining('Customer save blocked'), findsOneWidget);
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).last),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        // 2. Edit mode hydrates DOB + nominees, clears DOB via clear button, and pops on save.
        final repo = FakeCustomerRepository(
          customers: [
            Customer(
              id: 'cust-edit',
              name: 'Selina Kyle',
              phone: '9988776655',
              dateOfBirth: DateTime(1992, 3, 14),
              savingsAccount: const SavingsAccount(
                accountNumber: 'SB123456',
                nominees: [
                  Nominee(
                    name: 'Holly Robinson',
                    relationship: NomineeRelationship.brother,
                    percentage: 100,
                  ),
                ],
              ),
            ),
          ],
        );
        await pumpWithRouter(
          tester,
          child: const CustomerFormScreen(customerId: 'cust-edit'),
          customerRepo: repo,
        );
        await tester.tap(find.byTooltip(t.common.clear));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();
        expect(find.text('Go Target'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'OneTimeDepositFormScreen switches schemes, updates KVP rate/duration, validates customer & saves',
      (tester) async {
        final cust = const Customer(
          id: 'c-otd',
          name: 'Arthur Curry',
          phone: '9123456780',
        );
        final failingRepo = _FailingOtdRepo();

        await pumpWithRouter(
          tester,
          child: const OneTimeDepositFormScreen(),
          customerRepo: FakeCustomerRepository(customers: [cust]),
          otdRepo: failingRepo,
        );

        // Switch scheme to MIS then KVP and adjust interest rate.
        await tester.tap(
          find.text(OneTimeSchemeType.monthlyIncomeScheme.shortName),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(OneTimeSchemeType.kisanVikasPatra.shortName),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.interestRate),
          '7.5',
        );
        await tester.pumpAndSettle();

        // Attempting save without selecting customer shows validation snackbar.
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.accountNo),
          'KVP9001',
        );
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.principalAmount),
          '100000',
        );
        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();
        expect(
          find.text(t.oneTimeDeposits.selectCustomerPrompt),
          findsOneWidget,
        );
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).last),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        // With initialCustomerId and failing repo, shows failure toast; then succeeding repo pops.
        await pumpWithRouter(
          tester,
          child: const OneTimeDepositFormScreen(initialCustomerId: 'c-otd'),
          customerRepo: FakeCustomerRepository(customers: [cust]),
          otdRepo: failingRepo,
        );
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.accountNo),
          'TD9002',
        );
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.principalAmount),
          '50000',
        );
        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();
        expect(find.textContaining('Deposit save blocked'), findsOneWidget);
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).last),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        final savingRepo = FakeOneTimeDepositRepository();
        await pumpWithRouter(
          tester,
          child: const OneTimeDepositFormScreen(initialCustomerId: 'c-otd'),
          customerRepo: FakeCustomerRepository(customers: [cust]),
          otdRepo: savingRepo,
        );
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.accountNo),
          'TD9003',
        );
        await tester.enterText(
          _fieldLabeled(t.oneTimeDeposits.fields.principalAmount),
          '50000',
        );
        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();
        expect(find.text('Go Target'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
