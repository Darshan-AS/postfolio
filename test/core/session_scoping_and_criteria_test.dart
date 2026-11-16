import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session scoping (activeSessionKeyProvider)', () {
    test('signing out or switching users resets Hub selection, filters, and PO visit planner state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository(
        initialUser: const AuthUser(
          id: 'agent-a',
          email: 'a@postfolio.com',
          displayName: 'Agent A',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(authRepo),
          rdLedgerRepositoryProvider.overrideWith((ref) {
            ref.watch(activeSessionKeyProvider);
            final repo = FakeRDLedgerRepository();
            ref.onDispose(repo.dispose);
            return repo;
          }),
        ],
      );
      addTearDown(() {
        authRepo.dispose();
        container.dispose();
      });

      container.listen(authControllerProvider, (_, _) {});
      container.listen(rDHubSelectionProvider, (_, _) {});
      container.listen(rDHubFiltersProvider, (_, _) {});
      container.listen(rDPoVisitPlannerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      expect(container.read(activeSessionKeyProvider), 'auth:agent-a');

      // Agent A accumulates session-specific UI/operation state.
      container.read(rDHubSelectionProvider.notifier).selectAll(['inst-1', 'inst-2']);
      container.read(rDHubFiltersProvider.notifier).setSearchQuery('Ramesh');
      container.read(rDPoVisitPlannerProvider.notifier).setDate(DateTime(2026, 2, 14));
      expect(container.read(rDHubSelectionProvider).count, 2);
      expect(container.read(rDHubFiltersProvider).searchQuery, 'Ramesh');

      // Agent A signs out -> activeSessionKey transitions 'auth:agent-a' -> null.
      await container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(activeSessionKeyProvider), isNull);
      expect(container.read(rDHubSelectionProvider).count, 0);
      expect(container.read(rDHubSelectionProvider).isSelectionMode, isFalse);
      expect(container.read(rDHubFiltersProvider).searchQuery, isEmpty);

      // Toggling Demo Mode transitions null -> 'demo'.
      await container.read(demoModeProvider.notifier).enable();
      expect(container.read(activeSessionKeyProvider), 'demo');
    });
  });

  group('Reactive customer rename overlay', () {
    test('renaming a customer updates pre-joined OTD, RD, and Monthly Hub lists immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const initialCustomer = Customer(
        id: 'cust-1',
        name: 'Ramesh',
        phone: '9876543210',
      );
      final preJoinedOtd = OneTimeDeposit(
        id: 'otd-1',
        principalAmount: 50000,
        termYears: 5,
        termMonths: 0,
        interestRate: 7.5,
        customerId: 'cust-1',
        customerName: 'Ramesh', // Pre-joined at initial query time (like SQL view)
        schemeType: OneTimeSchemeType.timeDeposit,
        startDate: DateTime(2026, 1, 10),
      );
      final preJoinedRd = RecurringDeposit(
        id: 'rd-1',
        serialNo: '1',
        installmentAmount: 1000,
        termYears: 5,
        termMonths: 0,
        interestRate: 6.7,
        customerId: 'cust-1',
        customerName: 'Ramesh', // Pre-joined at initial query time
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2026, 1, 10),
      );

      final customerRepo = FakeCustomerRepository(
        customers: [initialCustomer],
        delay: Duration.zero,
      );
      final otdRepo = FakeOneTimeDepositRepository(
        deposits: [preJoinedOtd],
        delay: Duration.zero,
      );
      final rdRepo = FakeRecurringDepositRepository(deposits: [preJoinedRd]);
      final ledgerRepo = FakeRDLedgerRepository();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 3, 20)),
          customerRepositoryProvider.overrideWithValue(customerRepo),
          oneTimeDepositRepositoryProvider.overrideWithValue(otdRepo),
          recurringDepositRepositoryProvider.overrideWithValue(rdRepo),
          rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
      );
      addTearDown(() {
        rdRepo.dispose();
        ledgerRepo.dispose();
        container.dispose();
      });

      container.listen(customersControllerProvider, (_, _) {});
      container.listen(filteredOneTimeDepositsProvider, (_, _) {});
      container.listen(filteredRecurringDepositsProvider, (_, _) {});
      container.listen(monthlyOperationItemsProvider, (_, _) {});
      container.read(rDHubMonthProvider.notifier).setMonth(DateTime(2026, 3, 1));

      await container.read(customersControllerProvider.future);
      expect((await container.read(filteredOneTimeDepositsProvider.future)).single.customerName, 'Ramesh');
      expect((await container.read(filteredRecurringDepositsProvider.future)).single.customerName, 'Ramesh');
      expect((await container.read(monthlyOperationItemsProvider.future)).single.deposit.customerName, 'Ramesh');

      // Rename customer ONLY in CustomersController (OTD and RD streams do NOT re-emit).
      await container.read(customersControllerProvider.notifier).saveCustomer(
        id: 'cust-1',
        name: 'Ramesh Kumar',
        phone: '9876543210',
      );
      await Future<void>.delayed(Duration.zero);

      expect((await container.read(filteredOneTimeDepositsProvider.future)).single.customerName, 'Ramesh Kumar');
      expect((await container.read(filteredRecurringDepositsProvider.future)).single.customerName, 'Ramesh Kumar');
      expect((await container.read(monthlyOperationItemsProvider.future)).single.deposit.customerName, 'Ramesh Kumar');
    });
  });

  group('List criteria clearAll() persistence parity & reactive CurrentDate', () {
    test('OneTimeListCriteria.clearAll and RecurringListCriteria.clearAll persist exact defaults across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final c1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c1.dispose);

      c1.listen(oneTimeListCriteriaProvider, (_, _) {});
      c1.listen(recurringListCriteriaProvider, (_, _) {});

      c1.read(oneTimeListCriteriaProvider.notifier)
        ..updateSortField(OTDSortField.amount)
        ..updateSortDirection(SortDirection.desc)
        ..toggleStatusFilter(DepositStatus.closed)
        ..toggleUrgencyFilter(MaturityUrgency.maturingSoon)
        ..toggleSchemeFilter(OneTimeSchemeType.kisanVikasPatra)
        ..clearAll();

      c1.read(recurringListCriteriaProvider.notifier)
        ..updateSortField(RDSortField.amount)
        ..updateSortDirection(SortDirection.desc)
        ..toggleFilter(DepositStatus.closed)
        ..toggleUrgencyFilter(MaturityUrgency.matured)
        ..clearAll();

      await Future<void>.delayed(Duration.zero);

      // Re-hydrate in a fresh container reading from the persisted SharedPreferences.
      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);

      expect(c2.read(oneTimeListCriteriaProvider), const OTDSearchCriteria());
      expect(c2.read(recurringListCriteriaProvider), const RDSearchCriteria());
    });

    test('currentDateProvider refreshes on app resume across midnight without background timers', () {
      var simulatedNow = DateTime(2026, 10, 27, 23, 58);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => simulatedNow)],
      );
      addTearDown(container.dispose);

      final emissions = <DateTime>[];
      container.listen(currentDateProvider, (_, next) => emissions.add(next), fireImmediately: true);
      expect(emissions, [DateTime(2026, 10, 27)]);

      // Resume on the same calendar day -> no spurious emission.
      simulatedNow = DateTime(2026, 10, 27, 23, 59);
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(emissions, [DateTime(2026, 10, 27)]);

      // Cross midnight and resume -> emits new calendar day!
      simulatedNow = DateTime(2026, 10, 28, 0, 2);
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(emissions, [DateTime(2026, 10, 27), DateTime(2026, 10, 28)]);
    });
  });
}
