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
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies that Demo Mode's [FakeDataSource] mirrors all 22 DC scenarios from
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

    // Shape, clean notes & no future dates
    expect(customers, hasLength(22));
    expect([for (final d in rds) int.parse(d.serialNo!)]..sort(), [
      for (var n = 1; n <= 21; n++) n,
    ]);
    expect(otds, hasLength(17));
    for (final c in customers) {
      expect(c.notes, isNotNull, reason: c.name);
      expect(c.notes!.startsWith('Seed '), isFalse, reason: c.name);
    }
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

    // 1. Alfred Pennyworth: in hand cash
    final alfred = ledger(rd(1, 'Alfred Pennyworth'));
    expect(alfred.summary.cashInHandCash, 5000);
    expect(alfred.summary.cashInHandDigital, 0);

    // 2. Arthur Curry: 1 month in arrears
    final late = today.day > 15;
    final arthur = ledger(rd(2, 'Arthur Curry'));
    expect(arthur.summary.arrearsCount, late ? 2 : 1);
    expect(arthur.summary.feeDue, late ? 50 : 25);

    // 3. Barbara Gordon: part paid
    final barbara = rd(3, 'Barbara Gordon');
    expect(
      statusOf(installment(barbara)),
      RDInstallmentDisplayStatus.partiallyPaid,
    );
    expect(installment(barbara).outstandingAmount, 1500);

    // 4. Barry Allen: advance paid (+2 months ahead)
    final barry = rd(4, 'Barry Allen');
    expect(statusOf(installment(barry)), RDInstallmentDisplayStatus.settled);
    expect(ledger(barry).summary.depositedThroughNo, thisMonthNo(barry) + 2);
    expect(ledger(barry).summary.paidThroughNo, thisMonthNo(barry) + 2);
    expect(ledger(barry).summary.arrearsCount, 0);

    // 5. Bruce Wayne: 2 RDs, all 4 OTD schemes, 4+ FYs, SB with 3 nominees
    final bruce = customer('Bruce Wayne');
    expect(bruce.savingsAccount!.nominees, hasLength(3));
    expect(Nominee.validateNominees(bruce.savingsAccount!.nominees), isNull);
    expect(
      statusOf(installment(rd(5, bruce.name))),
      RDInstallmentDisplayStatus.settled,
    );
    final bruceUnpaid = installment(rd(6, bruce.name));
    expect(statusOf(bruceUnpaid), unpaidOn(bruceUnpaid.dueDate));
    expect({
      for (final d in otdsOf(bruce)) d.schemeType,
    }, OneTimeSchemeType.values.toSet());
    expect(
      {
        for (final d in otdsOf(bruce)) financialYear(d.startDate),
        financialYear(rd(5, bruce.name).startDate),
        financialYear(rd(6, bruce.name).startDate),
      }.length,
      greaterThanOrEqualTo(4),
    );

    // 6. Clark Kent: 0 baseline, absorbed fee, and UPI collected in hand
    final clarkRd = rd(7, 'Clark Kent');
    final clark = ledger(clarkRd);
    expect(clarkRd.initialPaidInstallments, 0);
    expect(
      statusOf(installment(clarkRd)),
      RDInstallmentDisplayStatus.collectedPendingPo,
    );
    expect(clark.summary.absorbedTotal, 30);
    expect(clark.summary.cashInHandDigital, 3000);
    expect(clark.poReadiness.readyCount, 1);

    // 7. Diana Prince: large cash (with Alfred > ₹20,000) + maturing soon MIS
    final dianaCust = customer('Diana Prince');
    final diana = ledger(rd(8, dianaCust.name));
    expect(diana.summary.cashInHandCash, 18000);
    expect(
      alfred.summary.cashInHandCash + diana.summary.cashInHandCash,
      greaterThan(20000),
    );
    expect(
      otdsOf(dianaCust).single.maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );

    // 8. Edward Nygma: bankTransfer in hand + maturing soon KVP
    final edwardCust = customer('Edward Nygma');
    final edward = ledger(rd(9, edwardCust.name));
    expect(edward.summary.cashInHandDigital, 3500);
    expect(edward.summary.cashInHandCash, 0);
    expect(
      otdsOf(edwardCust).single.maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );

    // 9. Hal Jordan: fronted + active NSC
    final halCust = customer('Hal Jordan');
    final hal = rd(10, halCust.name);
    expect(
      statusOf(installment(hal)),
      RDInstallmentDisplayStatus.paidFromPocket,
    );
    expect(ledger(hal).summary.receivable, 2000);
    expect(
      otdsOf(halCust).single.schemeType,
      OneTimeSchemeType.nationalSavingsCertificate,
    );

    // 10. Harleen Quinzel: 3 installments + ₹30 fees caught up in one visit
    final harleen = rd(11, 'Harleen Quinzel');
    expect(statusOf(installment(harleen)), RDInstallmentDisplayStatus.settled);
    expect(
      ds.rdPoDeposits[harleen.id]!.map((po) => po.installmentCount),
      contains(3),
    );
    expect(ledger(harleen).summary.owedByCustomer, 0);

    // 11. Harvey Dent: 3–4 months in arrears
    final harvey = ledger(rd(12, 'Harvey Dent'));
    expect(harvey.summary.arrearsCount, late ? 4 : 3);
    expect(harvey.summary.feeDue, late ? 105 : 90);

    // 12. Jason Todd: part-paid + prior arrears
    final jasonRd = rd(13, 'Jason Todd');
    final jasonPrior = installment(jasonRd, monthsAgo: 1);
    expect(statusOf(jasonPrior), RDInstallmentDisplayStatus.partiallyPaid);
    expect(jasonPrior.customerPaidAmount, 1000);
    expect(jasonPrior.outstandingAmount, 1020);
    expect(ledger(jasonRd).summary.arrearsCount, late ? 2 : 1);

    // 13. John Constantine: ₹50 absorbed fee, settled now
    final constantine = rd(14, 'John Constantine');
    expect(ledger(constantine).summary.absorbedTotal, 50);
    expect(ledger(constantine).summary.owedByCustomer, 0);

    // 14. Kara Zor-El: brand new RD + 1Y TD
    final karaCust = customer('Kara Zor-El');
    final kara = rd(15, karaCust.name);
    expect(thisMonthNo(kara), 1);
    expect(statusOf(installment(kara)), RDInstallmentDisplayStatus.settled);
    expect(otdsOf(karaCust).single.schemeType, OneTimeSchemeType.timeDeposit);

    // 15. Koriand'r: >50 char name, unpaid this month
    final koriandr = customers.singleWhere(
      (c) => c.name.startsWith("Koriand'r"),
    );
    expect(koriandr.name.length, greaterThan(50));
    final koriandrInst = installment(rd(16, koriandr.name));
    expect(statusOf(koriandrInst), unpaidOn(koriandrInst.dueDate));
    expect(statusOf(koriandrInst), isNot(RDInstallmentDisplayStatus.overdue));

    // 16. Lex Luthor: 36 baseline + ₹10,000 opening receivable + 2 OTDs
    final lexCust = customer('Lex Luthor');
    final lex = rd(17, lexCust.name);
    expect(lex.initialPaidInstallments, 36);
    expect(ledger(lex).summary.openingReceivableLeft, 10000);
    expect(otdsOf(lexCust), hasLength(2));

    // 17. Lois Lane: to collect (due month-end) + NSC
    final loisCust = customer('Lois Lane');
    final lois = rd(18, loisCust.name);
    expect(statusOf(installment(lois)), unpaidOn(installment(lois).dueDate));
    expect(ledger(lois).summary.arrearsCount, 0);
    expect(
      otdsOf(loisCust).single.schemeType,
      OneTimeSchemeType.nationalSavingsCertificate,
    );

    // 18. Oliver Queen: RD + TD maturing soon
    final oliver = customer('Oliver Queen');
    expect(
      rd(19, oliver.name).maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );
    expect(
      otdsOf(oliver).single.maturityUrgencyAt(today),
      MaturityUrgency.maturingSoon,
    );

    // 19. Oswald Cobblepot: RD + NSC matured and still open
    final oswald = customer('Oswald Cobblepot');
    expect(
      rd(20, oswald.name).maturityUrgencyAt(today),
      MaturityUrgency.matured,
    );
    expect(
      otdsOf(oswald).single.maturityUrgencyAt(today),
      MaturityUrgency.matured,
    );

    // 20. Pamela Isley: closed RD, TD, and MIS
    final pamela = customer('Pamela Isley');
    expect(rd(21, pamela.name).status, DepositStatus.closed);
    expect(otdsOf(pamela), hasLength(2));
    expect(
      otdsOf(pamela).every((d) => d.status == DepositStatus.closed),
      isTrue,
    );

    // 21. Selina Kyle: minimal profile + ₹1,000 KVP with no nominees
    final selina = customer('Selina Kyle');
    expect(selina.phone, isNull);
    expect(selina.savingsAccount, isNull);
    expect(otdsOf(selina).single.schemeType, OneTimeSchemeType.kisanVikasPatra);
    expect(otdsOf(selina).single.nominees, isEmpty);

    // 22. Victor Stone: no accounts
    final victor = customer('Victor Stone');
    expect(otdsOf(victor), isEmpty);
    expect(rds.where((d) => d.customerId == victor.id), isEmpty);
  }

  for (final date in sampleDates) {
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    test('all 22 Demo Mode scenarios hold on $iso', () {
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

    expect(customers, hasLength(22));
    expect(otds, hasLength(17));
    expect(rds, hasLength(21));

    final karaRd = rds.singleWhere((d) => d.serialNo == '15');
    expect(karaRd.startDate, DateTime(2028, 2, 1));

    final constantineRd = rds.singleWhere((d) => d.serialNo == '14');
    final absorptionsRes = await container
        .read(rdLedgerRepositoryProvider)
        .watchFeeAbsorptions(constantineRd.id)
        .first;
    final absorptions = (absorptionsRes as Success).value as List;
    expect(absorptions, hasLength(1));
  });
}
