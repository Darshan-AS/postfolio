import "package:postfolio/core/constants/app_constants.dart";
import 'package:faker/faker.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

class FakeDataSource {
  static final FakeDataSource _instance = FakeDataSource._internal();
  factory FakeDataSource() => _instance;

  static const PostalRateService _postalRateService = PostalRateService();

  late final List<Customer> customers;
  late final List<OneTimeDeposit> oneTimeDeposits;
  late final List<RecurringDeposit> recurringDeposits;
  late final Map<String, List<RDTransaction>> rdTransactions;
  late final Map<String, List<RDPoDeposit>> rdPoDeposits;

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
              percentage: AppConstants.maxPercentage,
            ),
          ),
        ),
      );
    });

    final customerIds = customers.map((c) => c.id).toList();

    // Generate One Time Deposits
    final oneTimeSchemes = OneTimeSchemeType.values;
    oneTimeDeposits = List.generate(15, (index) {
      final scheme = random.element(oneTimeSchemes);
      final startDate = faker.date.dateTimeBetween(
        DateTime(2020),
        DateTime.now(),
      );
      final tdOption = scheme.tenureInputType != TenureInputType.derived
          ? random.element(scheme.allowedTenuresInYears)
          : null;

      final terms = _postalRateService.resolveOneTimeSchemeTerms(
        schemeType: scheme,
        startDate: startDate,
        tdTenureYears: tdOption,
      );

      final maturityDate = DateTime(
        startDate.year + terms.termYears,
        startDate.month + terms.termMonths,
        startDate.day,
      );

      DepositStatus status;
      if (maturityDate.isBefore(DateTime.now())) {
        status = random.element([DepositStatus.active, DepositStatus.closed]);
      } else {
        // Can only be closed if the maturity date is in the past
        status = random.element([DepositStatus.active, DepositStatus.closed]);
      }

      return OneTimeDeposit(
        id: faker.guid.guid(),
        accountNo: faker.randomGenerator.fromCharSet('0123456789', 10),
        principalAmount: random.integer(500000, min: 10000).toDouble(),
        termYears: terms.termYears,
        termMonths: terms.termMonths,
        interestRate: terms.interestRate,
        customerId: random.element(customerIds),
        schemeType: scheme,
        startDate: startDate,
        status: status,
        nominees: List.generate(
          random.integer(3),
          (_) => Nominee(
            name: faker.person.name(),
            relationship: random.element(NomineeRelationship.values),
            percentage: AppConstants.maxPercentage,
          ),
        ),
      );
    });

    // Generate Recurring Deposits
    final recurringSchemes = RecurringSchemeType.values;
    recurringDeposits = List.generate(15, (index) {
      final scheme = random.element(recurringSchemes);
      final startDate = faker.date.dateTimeBetween(
        DateTime(2020),
        DateTime.now(),
      );
      final terms = _postalRateService.resolveRecurringSchemeTerms(
        schemeType: scheme,
        startDate: startDate,
      );

      final maturityDate = DateTime(
        startDate.year + terms.termYears,
        startDate.month + terms.termMonths,
        startDate.day,
      );

      DepositStatus status;
      if (maturityDate.isBefore(DateTime.now())) {
        status = random.element([DepositStatus.active, DepositStatus.closed]);
      } else {
        // Can only be closed if the maturity date is in the past
        status = random.element([DepositStatus.active, DepositStatus.closed]);
      }

      return RecurringDeposit(
        id: faker.guid.guid(),
        serialNo: 'RD-${random.integer(9999, min: 1000)}',
        accountNo: 'RD-${random.fromCharSet('0123456789', 7)}',
        installmentAmount: random.integer(50000, min: 1000).toDouble(),
        termYears: terms.termYears,
        termMonths: terms.termMonths,
        interestRate: terms.interestRate,
        customerId: random.element(customerIds),
        schemeType: scheme,
        startDate: startDate,
        status: status,
        nominees: List.generate(
          random.integer(3),
          (_) => Nominee(
            name: faker.person.name(),
            relationship: random.element(NomineeRelationship.values),
            percentage: AppConstants.maxPercentage,
          ),
        ),
      );
    });

    // Ledger facts for demo mode: most due months are paid a few days before/after the due
    // date, a few are skipped (so arrears and default fees appear), and all but the most
    // recent couple of paid months have been deposited at the Post Office.
    final today = DateTime.now();
    rdTransactions = {};
    rdPoDeposits = {};
    for (final rd in recurringDeposits) {
      if (rd.status != DepositStatus.active) continue;
      final txs = <RDTransaction>[];
      final deposits = <RDPoDeposit>[];
      final total = rd.totalMonths;
      var paidCount = 0;
      for (var no = rd.initialPaidInstallments + 1; no <= total; no++) {
        final month = RDScheduleFactory.installmentDateFor(rd.startDate, no);
        final due = RDLedgerRules.standard.dueDateFor(rd.startDate, month);
        if (!due.isBefore(today)) break;
        // ~1 in 6 months is skipped to create realistic arrears.
        if (random.integer(6) == 0) continue;
        final paidOn = due.add(Duration(days: random.integer(9, min: -4)));
        txs.add(RDTransaction(
          id: faker.guid.guid(),
          rdId: rd.id,
          paidDate: DateTime(paidOn.year, paidOn.month, paidOn.day),
          amount: rd.installmentAmount,
          paymentMode: random.element(RDPaymentMode.values),
          createdAt: paidOn,
        ));
        paidCount++;
        if (paidCount > 2 && random.integer(5) != 0) {
          deposits.add(RDPoDeposit(
            rdId: rd.id,
            installmentNo: no,
            depositedOn: DateTime(paidOn.year, paidOn.month, paidOn.day)
                .add(Duration(days: random.integer(4, min: 1))),
          ));
        }
      }
      rdTransactions[rd.id] = txs;
      rdPoDeposits[rd.id] = deposits;
    }
  }
}
