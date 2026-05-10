import 'package:faker/faker.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

class FakeDataSource {
  static final FakeDataSource _instance = FakeDataSource._internal();
  factory FakeDataSource() => _instance;

  late final List<Customer> customers;
  late final List<OneTimeDeposit> oneTimeDeposits;
  late final List<RecurringDeposit> recurringDeposits;

  FakeDataSource._internal() {
    _generateData();
  }

  void _generateData() {
    // Using a fixed seed ensures the generated fake data is exactly the same
    // every time the app is restarted, making UI testing much easier.
    final faker = Faker(seed: 12345);
    final random = faker.randomGenerator;

    // Generate Customers
    customers = List.generate(15, (index) {
      return Customer(
        id: faker.guid.guid(),
        name: faker.person.name(),
        email: faker.internet.email(),
        phone: '+91 ${random.fromCharSet('0123456789', 10)}',
        address: faker.address.streetAddress(),
        cifNumber: 'CIF${random.fromCharSet('0123456789', 6)}',
        dateOfBirth: faker.date.dateTimeBetween(DateTime(1950), DateTime(2005)),
        aadhaarNumber:
            '${random.fromCharSet('0123456789', 4)} ${random.fromCharSet('0123456789', 4)} ${random.fromCharSet('0123456789', 4)}',
        panNumber:
            '${random.fromCharSet('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 5)}${random.fromCharSet('0123456789', 4)}${random.fromCharSet('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1)}',
        savingsAccount: SavingsAccount(
          accountNumber: 'SA${random.fromCharSet('0123456789', 9)}',
          nominees: List.generate(
            random.integer(3),
            (_) => Nominee(
              name: faker.person.name(),
              relationship: random.element(NomineeRelationship.values),
              percentage: 100.0,
            ),
          ),
        ),
      );
    });

    final customerIds = customers.map((c) => c.id).toList();
    final depositStatuses = DepositStatus.values;

    // Generate One Time Deposits
    final oneTimeSchemes = OneTimeSchemeType.values;
    oneTimeDeposits = List.generate(15, (index) {
      final scheme = random.element(oneTimeSchemes);
      final int termYears;
      final int termMonths;

      final interestRate = random.decimal(scale: 2, min: 5.0) + 5.0;

      if (scheme.tenureInputType != TenureInputType.derived) {
        termYears = random.element(scheme.allowedTenuresInYears);
        termMonths = 0;
      } else {
        final timeInMonths = ProjectionCalculator.calculateKvpTermMonths(interestRate);
        termYears = timeInMonths ~/ 12;
        termMonths = timeInMonths % 12;
      }

      return OneTimeDeposit(
        id: faker.guid.guid(),
        accountNo: faker.randomGenerator.fromCharSet('0123456789', 10),
        principalAmount: random.integer(500000, min: 10000).toDouble(),
        termYears: termYears,
        termMonths: termMonths,
        interestRate: interestRate,
        customerId: random.element(customerIds),
        schemeType: scheme,
        startDate: faker.date.dateTimeBetween(DateTime(2020), DateTime.now()),
        linkedSavingsAccountNo:
            'SA${faker.randomGenerator.fromCharSet('0123456789', 9)}',
        status: random.element(depositStatuses),
        nominees: List.generate(
          random.integer(3),
          (_) => Nominee(
            name: faker.person.name(),
            relationship: random.element(NomineeRelationship.values),
            percentage: 100.0,
          ),
        ),
      );
    });

    // Generate Recurring Deposits
    final recurringSchemes = RecurringSchemeType.values;
    recurringDeposits = List.generate(15, (index) {
      final scheme = random.element(recurringSchemes);
      final termYears = scheme.tenureInputType != TenureInputType.derived
          ? random.element(scheme.allowedTenuresInYears)
          : 5;

      return RecurringDeposit(
        id: faker.guid.guid(),
        serialNo: 'RD-${random.integer(9999, min: 1000)}',
        accountNo: 'RD-${random.fromCharSet('0123456789', 7)}',
        installmentAmount: random.integer(50000, min: 1000).toDouble(),
        termYears: termYears,
        termMonths: 0,
        interestRate: random.decimal(scale: 2, min: 5.0) + 5.0,
        customerId: random.element(customerIds),
        schemeType: scheme,
        startDate: faker.date.dateTimeBetween(DateTime(2020), DateTime.now()),
        linkedAutoDebitAccountNo: 'SA${random.fromCharSet('0123456789', 9)}',
        status: random.element(depositStatuses),
        nominees: List.generate(
          random.integer(3),
          (_) => Nominee(
            name: faker.person.name(),
            relationship: random.element(NomineeRelationship.values),
            percentage: 100.0,
          ),
        ),
      );
    });
  }
}
