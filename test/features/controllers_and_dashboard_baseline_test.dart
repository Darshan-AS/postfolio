import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/dashboard/providers/dashboard_provider.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<
    ({
      ProviderContainer container,
      FakeCustomerRepository customers,
      FakeOneTimeDepositRepository otds,
      FakeRecurringDepositRepository rds,
      SharedPreferences prefs,
    })> _buildHarness({
  List<Customer> customers = const [],
  List<OneTimeDeposit> otds = const [],
  List<RecurringDeposit> rds = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final customerRepo = FakeCustomerRepository(customers: customers, delay: Duration.zero);
  final otdRepo = FakeOneTimeDepositRepository(deposits: otds, delay: Duration.zero);
  final rdRepo = FakeRecurringDepositRepository(deposits: rds);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      customerRepositoryProvider.overrideWithValue(customerRepo),
      oneTimeDepositRepositoryProvider.overrideWithValue(otdRepo),
      recurringDepositRepositoryProvider.overrideWithValue(rdRepo),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(customerRepo.dispose);
  addTearDown(otdRepo.dispose);
  addTearDown(rdRepo.dispose);
  return (
    container: container,
    customers: customerRepo,
    otds: otdRepo,
    rds: rdRepo,
    prefs: prefs,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('CustomersController & CustomerListCriteria', () {
    test('CRUD, multi-field search (name/phone/CIF/PAN), and sort persistence', () async {
      final h = await _buildHarness(customers: [
        Customer(
          id: 'c1',
          name: 'Zara Khan',
          phone: '9876500001',
          cifNumber: 'CIF9001',
          panNumber: 'ZZZZZ1111Z',
          createdAt: DateTime(2025, 1, 10),
        ),
        Customer(
          id: 'c2',
          name: 'Amit Patel',
          phone: '9876500002',
          cifNumber: 'CIF1002',
          panNumber: 'AAAAA2222A',
          createdAt: DateTime(2025, 5, 10),
        ),
      ]);
      final c = h.container;
      c.listen(filteredCustomersProvider, (_, _) {});

      // Default sort: name ascending → Amit, Zara.
      var list = await c.read(filteredCustomersProvider.future);
      expect(list.map((e) => e.id), ['c2', 'c1']);

      // Search by PAN (case-insensitive) and CIF.
      c.read(customerListCriteriaProvider.notifier).updateSearch('zzzzz1111z');
      list = await c.read(filteredCustomersProvider.future);
      expect(list.single.id, 'c1');

      c.read(customerListCriteriaProvider.notifier).clearAll();
      c.read(customerListCriteriaProvider.notifier).updateSortField(CustomerSortField.createdAt);
      c.read(customerListCriteriaProvider.notifier).updateSortDirection(SortDirection.desc);
      list = await c.read(filteredCustomersProvider.future);
      expect(list.map((e) => e.id), ['c2', 'c1']);
      expect(c.read(storageServiceProvider).getCustomerSortField(), CustomerSortField.createdAt);

      // Create (id: null) + update (id: existing) + delete via controller.
      final createRes = await c.read(customersControllerProvider.notifier).saveCustomer(
            name: 'Bhavna Rao',
            phone: '9811122233',
          );
      expect(createRes, isA<Success<void, String>>());
      list = await c.read(filteredCustomersProvider.future);
      final created = list.firstWhere((e) => e.name == 'Bhavna Rao');

      final updateRes = await c.read(customersControllerProvider.notifier).saveCustomer(
            id: created.id,
            name: 'Bhavna Rao Sharma',
            phone: '9811122233',
          );
      expect(updateRes, isA<Success<void, String>>());
      c.listen(customerByIdProvider(created.id), (_, _) {});
      expect((await c.read(customerByIdProvider(created.id).future)).name, 'Bhavna Rao Sharma');

      expect(
        await c.read(customersControllerProvider.notifier).deleteCustomer('c1'),
        isA<Success<void, String>>(),
      );
      list = await c.read(filteredCustomersProvider.future);
      expect(list.map((e) => e.id), isNot(contains('c1')));
    });
  });

  group('OneTimeDepositsController & RecurringDepositsController', () {
    test('OTD lazy customerName fallback, scheme/status/urgency filters, and status toggle', () async {
      final h = await _buildHarness(
        customers: [const Customer(id: 'c1', name: 'Ramesh Nair'), const Customer(id: 'c2', name: 'Anita Roy')],
        otds: [
          OneTimeDeposit(
            id: 'otd1',
            customerId: 'c1',
            schemeType: OneTimeSchemeType.monthlyIncomeScheme,
            principalAmount: 300000,
            interestRate: 7.4,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2019, 1, 1), // Matured in 2024
          ),
          OneTimeDeposit(
            id: 'otd2',
            customerId: 'c2',
            schemeType: OneTimeSchemeType.timeDeposit,
            principalAmount: 100000,
            interestRate: 7.5,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2025, 6, 1),
          ),
        ],
      );
      final c = h.container;
      c.listen(filteredOneTimeDepositsProvider, (_, _) {});

      var list = await c.read(filteredOneTimeDepositsProvider.future);
      expect(list, hasLength(2));
      expect(list.firstWhere((d) => d.id == 'otd1').customerName, 'Ramesh Nair',
          reason: 'resolves missing customerName from CustomersController');

      final criteria = c.read(oneTimeListCriteriaProvider.notifier);
      criteria.toggleSchemeFilter(OneTimeSchemeType.monthlyIncomeScheme);
      criteria.toggleUrgencyFilter(MaturityUrgency.matured);
      list = await c.read(filteredOneTimeDepositsProvider.future);
      expect(list.single.id, 'otd1');

      criteria.clearFilters();
      criteria.updateSortField(OTDSortField.amount);
      criteria.updateSortDirection(SortDirection.desc);
      list = await c.read(filteredOneTimeDepositsProvider.future);
      expect(list.map((d) => d.id), ['otd1', 'otd2']);

      // Closing otd1 removes it from default active-only filter without losing data.
      expect(
        await c
            .read(oneTimeDepositsControllerProvider.notifier)
            .toggleDepositStatus('otd1', DepositStatus.closed),
        isA<Success<void, String>>(),
      );
      list = await c.read(filteredOneTimeDepositsProvider.future);
      expect(list.map((d) => d.id), ['otd2']);
    });

    test('RD serialNo sorts numerically (1, 2, 10) rather than lexically (1, 10, 2)', () async {
      RecurringDeposit rd(String id, String serial) => RecurringDeposit(
            id: id,
            serialNo: serial,
            customerId: 'c1',
            customerName: 'Arjun',
            schemeType: RecurringSchemeType.recurringDeposit,
            installmentAmount: 1000,
            interestRate: 6.7,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2025, 1, 10),
          );

      final h = await _buildHarness(rds: [rd('r10', '10'), rd('r2', '2'), rd('r1', '1')]);
      final c = h.container;
      c.listen(filteredRecurringDepositsProvider, (_, _) {});

      c.read(recurringListCriteriaProvider.notifier).updateSortField(RDSortField.serialNo);
      c.read(recurringListCriteriaProvider.notifier).updateSortDirection(SortDirection.asc);

      final list = await c.read(filteredRecurringDepositsProvider.future);
      expect(list.map((d) => d.serialNo), ['1', '2', '10']);
    });
  });

  group('Dashboard metrics & Indian Financial Year chart series', () {
    test('aggregates active vs total portfolio and buckets Mar 31 vs Apr 1 across FYs', () async {
      final h = await _buildHarness(
        customers: [
          const Customer(id: 'c1', name: 'Active Holder'),
          const Customer(id: 'c2', name: 'Closed Only Holder'),
          const Customer(id: 'c3', name: 'No Accounts Yet'),
        ],
        otds: [
          OneTimeDeposit(
            id: 'fy24_mar',
            customerId: 'c1',
            schemeType: OneTimeSchemeType.kisanVikasPatra,
            principalAmount: 100000,
            interestRate: 7.5,
            termYears: 9,
            termMonths: 7,
            startDate: DateTime(2025, 3, 31), // FY 24-25
          ),
          OneTimeDeposit(
            id: 'fy25_apr',
            customerId: 'c1',
            schemeType: OneTimeSchemeType.timeDeposit,
            principalAmount: 250000,
            interestRate: 7.5,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2025, 4, 1), // FY 25-26
          ),
          OneTimeDeposit(
            id: 'closed_mis',
            customerId: 'c2',
            schemeType: OneTimeSchemeType.monthlyIncomeScheme,
            principalAmount: 50000,
            interestRate: 7.4,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2025, 6, 15), // FY 25-26
            status: DepositStatus.closed,
          ),
        ],
        rds: [
          RecurringDeposit(
            id: 'rd_closed',
            customerId: 'c2',
            schemeType: RecurringSchemeType.recurringDeposit,
            installmentAmount: 2000,
            interestRate: 6.7,
            termYears: 5,
            termMonths: 0,
            startDate: DateTime(2020, 1, 10),
            status: DepositStatus.closed,
          ),
        ],
      );
      final c = h.container;
      c.listen(customersControllerProvider, (_, _) {});
      c.listen(oneTimeDepositsControllerProvider, (_, _) {});
      c.listen(recurringDepositsControllerProvider, (_, _) {});
      c.listen(dashboardMetricsDataProvider, (_, _) {});
      c.listen(dashboardChartSeriesProvider, (_, _) {});
      await c.read(customersControllerProvider.future);
      await c.read(oneTimeDepositsControllerProvider.future);
      await c.read(recurringDepositsControllerProvider.future);

      final metrics = c.read(dashboardMetricsDataProvider);
      expect(metrics.totalCustomers, 3);
      expect(metrics.activeCustomers, 1, reason: 'only c1 holds active deposits');
      expect(metrics.totalOtds, 3);
      expect(metrics.activeOtds, 2);
      expect(metrics.totalRds, 1);
      expect(metrics.activeRds, 0);
      expect(metrics.activeOtdsByScheme[OneTimeSchemeType.kisanVikasPatra], 1);
      expect(metrics.activeOtdsByScheme[OneTimeSchemeType.monthlyIncomeScheme], 0);
      expect(metrics.totalOtdsByScheme[OneTimeSchemeType.monthlyIncomeScheme], 1);

      // Yearly series: FY 24-25 (₹1,00,000) and FY 25-26 (₹3,00,000 across Apr + Jun).
      final yearly = c.read(dashboardChartSeriesProvider);
      expect(yearly.map((p) => (p.id, p.label, p.amount, p.count)), [
        (2024, 'FY 24-25', 100000.0, 1),
        (2025, 'FY 25-26', 300000.0, 2),
      ]);

      // Drill down into FY 25-26 → 12 monthly buckets starting April 2025 through March 2026.
      c.read(dashboardChartSelectedYearProvider.notifier).setYear(2025);
      final monthly = c.read(dashboardChartSeriesProvider);
      expect(monthly, hasLength(12));
      expect(monthly.first.id, 202504);
      expect(monthly.first.amount, 250000.0);
      expect(monthly[2].id, 202506);
      expect(monthly[2].amount, 50000.0);
      expect(monthly.last.id, 202603);
    });
  });
}
