import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies that Demo Mode's [FakeDataSource] mirrors all 21 scenarios from
/// `supabase/seed.sql` relative to any calendar day (1st, 15th, month-end, year rollover,
/// and leap day) and wires into the Demo Mode repository providers via [clockProvider].
void main() {
  final sampleDates = [
    DateTime(2026, 11, 1),
    DateTime(2026, 11, 15),
    DateTime(2026, 11, 19),
    DateTime(2026, 11, 30),
    DateTime(2026, 12, 31),
    DateTime(2027, 1, 1),
    DateTime(2028, 2, 29),
    DateTime(2028, 3, 31),
  ];

  void assertAllScenarios(DateTime today) {
    final ds = FakeDataSource.forDate(today);
    final customers = ds.customers;
    final rds = ds.recurringDeposits;
    final otds = ds.oneTimeDeposits;

    Customer customer(String name) =>
        customers.singleWhere((c) => c.name == name);

    RecurringDeposit rd(int serial, String holder) {
      final deposit = rds.singleWhere((d) => d.serialNo == '$serial');
      expect(deposit.customerName, holder);
      return deposit;
    }

    RDLedgerProjection ledger(RecurringDeposit deposit) =>
        RDLedgerProjector.standard.project(
          RDLedgerFacts(
            deposit: deposit,
            transactions: ds.rdTransactions[deposit.id] ?? const [],
            poDeposits: ds.rdPoDeposits[deposit.id] ?? const [],
            absorptions: ds.rdFeeAbsorptions[deposit.id] ?? const [],
          ),
          asOf: today,
        );

    int thisMonthNo(RecurringDeposit deposit) =>
        RDScheduleFactory.installmentNoFor(deposit.startDate, today);

    RDInstallment installment(RecurringDeposit deposit, {int monthsAgo = 0}) =>
        ledger(deposit).installments[thisMonthNo(deposit) - 1 - monthsAgo];

    RDInstallmentDisplayStatus statusOf(RDInstallment i) =>
        i.displayStatusAt(today);

    RDInstallmentDisplayStatus unpaidOn(DateTime dueDate) {
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (due.isAfter(today)) return RDInstallmentDisplayStatus.upcoming;
      if (due == today) return RDInstallmentDisplayStatus.dueToday;
      return RDInstallmentDisplayStatus.overdue;
    }

    List<OneTimeDeposit> otdsOf(Customer c) => [
      for (final d in otds)
        if (d.customerId == c.id) d,
    ];

    int financialYear(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

    // Shape & no future dates
    expect(customers, hasLength(21));
    expect([for (final d in rds) int.parse(d.serialNo!)]..sort(), [
      for (var n = 1; n <= 20; n++) n,
    ]);
    expect(otds, hasLength(11));
    for (final d in rds) {
      expect(d.startDate.isAfter(today), isFalse);
      for (final tx in ds.rdTransactions[d.id] ?? const []) {
        expect(tx.paidDate.isAfter(today), isFalse);
      }
      for (final po in ds.rdPoDeposits[d.id] ?? const []) {
        expect(po.depositedOn.isAfter(today), isFalse);
      }
      for (final abs in ds.rdFeeAbsorptions[d.id] ?? const []) {
        expect(abs.absorbedOn.isAfter(today), isFalse);
      }
    }
    for (final d in otds) {
      expect(d.startDate.isAfter(today), isFalse);
    }

    // 1. Asha: settled
    final asha = rd(1, 'Asha Kulkarni');
    expect(statusOf(installment(asha)), RDInstallmentDisplayStatus.settled);
    expect(ledger(asha).summary.arrearsCount, 0);

    // 2–4. Bharat, Chitra, Dinesh: in hand cash, UPI, and two cash lots
    final bharat = ledger(rd(2, 'Bharat Shetty'));
    final chitra = ledger(rd(3, 'Chitra Nair'));
    final dinesh = ledger(rd(4, 'Dinesh Agarwal'));
    expect(bharat.summary.cashInHandCash, 5000);
    expect(chitra.summary.cashInHandDigital, 3000);
    expect(dinesh.summary.cashInHandCash, 18000);
    expect(
      bharat.summary.cashInHandCash + dinesh.summary.cashInHandCash,
      greaterThan(kPoCashLotLimit),
    );

    // 5. Esha: part paid
    final esha = rd(5, 'Esha Fernandes');
    expect(
      statusOf(installment(esha)),
      RDInstallmentDisplayStatus.partiallyPaid,
    );
    expect(installment(esha).outstandingAmount, 1500);

    // 6. Farhan: unpaid this month, not late
    final farhan = rd(6, 'Farhan Qureshi');
    expect(
      statusOf(installment(farhan)),
      unpaidOn(installment(farhan).dueDate),
    );
    expect(ledger(farhan).summary.arrearsCount, 0);

    // 7–8. Gauri & Harish: 1 and 3 months in arrears
    final late = today.day > 15;
    final gauri = ledger(rd(7, 'Gauri Deshpande'));
    expect(gauri.summary.arrearsCount, late ? 2 : 1);
    expect(gauri.summary.feeDue, late ? 50 : 25);

    final harish = ledger(rd(8, 'Harish Gowda'));
    expect(harish.summary.arrearsCount, late ? 4 : 3);
    expect(harish.summary.feeDue, late ? 105 : 90);

    // 9. Indira: fronted
    final indira = rd(9, 'Indira Menon');
    expect(
      statusOf(installment(indira)),
      RDInstallmentDisplayStatus.frontedByAgent,
    );
    expect(ledger(indira).summary.receivable, 2000);

    // 10. Jayant: 3 installments + ₹30 fees caught up in one visit
    final jayant = rd(10, 'Jayant Bhat');
    expect(statusOf(installment(jayant)), RDInstallmentDisplayStatus.settled);
    expect(
      ds.rdPoDeposits[jayant.id]!.map((po) => po.installmentCount),
      contains(3),
    );
    expect(ledger(jayant).summary.owedByCustomer, 0);

    // 11. Kavita: ₹50 absorbed fee, settled now
    final kavita = rd(11, 'Kavita Joshi');
    expect(ledger(kavita).summary.absorbedTotal, 50);
    expect(ledger(kavita).summary.owedByCustomer, 0);

    // 12–16. Lifecycle: brand new, opening receivable, maturing soon, matured, closed
    final lalit = rd(12, 'Lalit Saxena');
    expect(thisMonthNo(lalit), 1);
    expect(statusOf(installment(lalit)), RDInstallmentDisplayStatus.settled);

    final meera = rd(13, 'Meera Iyer');
    expect(meera.initialPaidInstallments, 36);
    expect(ledger(meera).summary.openingReceivableLeft, 10000);

    final naveen = customer('Naveen Pillai');
    expect(
      rd(14, naveen.name).maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );
    expect(
      otdsOf(naveen).single.maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );

    final omana = customer('Omana Kurup');
    expect(
      rd(15, omana.name).maturityUrgencyAt(today),
      MaturityUrgency.matured,
    );
    expect(
      otdsOf(omana).single.maturityUrgencyAt(today),
      MaturityUrgency.matured,
    );

    final prakash = customer('Prakash Rao');
    expect(rd(16, prakash.name).status, DepositStatus.closed);
    expect(otdsOf(prakash).single.status, DepositStatus.closed);

    // 17–21. Customer shapes
    final ramesh = customer('Ramesh Hegde');
    expect(ramesh.savingsAccount!.nominees, hasLength(3));
    expect(Nominee.validateNominees(ramesh.savingsAccount!.nominees), isNull);
    expect({
      for (final d in otdsOf(ramesh)) d.schemeType,
    }, OneTimeSchemeType.values.toSet());
    expect(
      {
        for (final d in otdsOf(ramesh)) financialYear(d.startDate),
        financialYear(rd(17, ramesh.name).startDate),
        financialYear(rd(18, ramesh.name).startDate),
      }.length,
      greaterThanOrEqualTo(4),
    );

    final sunita = customer('Sunita Thomas');
    expect(sunita.phone, isNull);
    expect(sunita.savingsAccount, isNull);
    expect(otdsOf(sunita).single.nominees, isEmpty);

    final tejaswini = customers.singleWhere(
      (c) => c.name.startsWith('Tejaswini'),
    );
    expect(tejaswini.name.length, greaterThan(50));

    final uma = customer('Uma Bose');
    expect(otdsOf(uma), isEmpty);
    expect(rds.where((d) => d.customerId == uma.id), isEmpty);

    final kannada = customers.singleWhere(
      (c) => RegExp(r'[\u0C80-\u0CFF]').hasMatch(c.name),
    );
    expect(
      statusOf(installment(rd(20, kannada.name))),
      RDInstallmentDisplayStatus.settled,
    );
  }

  for (final date in sampleDates) {
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    test('all 21 Demo Mode scenarios hold on $iso', () {
      assertAllScenarios(date);
    });
  }

  test('Demo Mode repository providers build data relative to clockProvider '
      'and include fee absorptions', () async {
    SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    final fakeToday = DateTime(2028, 2, 29);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => fakeToday),
      ],
    );
    addTearDown(container.dispose);

    final customersRes = await container
        .read(customerRepositoryProvider)
        .watchCustomers()
        .first;
    final otdsRes = await container
        .read(oneTimeDepositRepositoryProvider)
        .watchOneTimeDeposits()
        .first;
    final rdsRes = await container
        .read(recurringDepositRepositoryProvider)
        .watchRecurringDeposits()
        .first;

    final customers = (customersRes as Success<List<Customer>, String>).value;
    final otds = (otdsRes as Success<List<OneTimeDeposit>, String>).value;
    final rds = (rdsRes as Success<List<RecurringDeposit>, String>).value;

    expect(customers, hasLength(21));
    expect(otds, hasLength(11));
    expect(rds, hasLength(20));

    final lalitRd = rds.singleWhere((d) => d.serialNo == '12');
    expect(lalitRd.startDate, DateTime(2028, 2, 1));

    final kavitaRd = rds.singleWhere((d) => d.serialNo == '11');
    final absorptionsRes = await container
        .read(rdLedgerRepositoryProvider)
        .watchFeeAbsorptions(kavitaRd.id)
        .first;
    final absorptions = (absorptionsRes as Success).value as List;
    expect(absorptions, hasLength(1));
  });
}
