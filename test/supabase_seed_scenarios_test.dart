@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/auth/domain/local_seed_agent.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/supabase_one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks `supabase/seed.sql` against the LOCAL Supabase stack: each seeded customer is
/// there to show one situation, and this reads the data the way the app does (repositories,
/// then [RDLedgerProjector]) and asserts that the situation is what the app would show.
/// Change the seed and this file together.
///
/// The seed counts every date back from the day of the reset. This test projects the ledger
/// as of that same day, read from when the seeded agent's profile was created, so it passes
/// however long ago the reset was. `--dart-define=SEED_TODAY=2026-11-30` names the day
/// instead, for a database seeded with `PGOPTIONS="-c seed.today=2026-11-30"`.
///
/// Skipped when the seeded agent owns no customers: another agent signed in first and took
/// over the seed data, or the database was not seeded. `supabase db reset` restores it.
///
/// Run: flutter test test/supabase_seed_scenarios_test.dart   (requires `supabase start`)
void main() {
  const url = 'http://127.0.0.1:54321';
  const anon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  const seedTodayOverride = String.fromEnvironment('SEED_TODAY');

  late SupabaseClient client;
  late DateTime today;
  String? skipReason;
  var customers = <Customer>[];
  var rds = <RecurringDeposit>[];
  var otds = <OneTimeDeposit>[];
  var facts = <String, RDRawFactsBundle>{};

  T ok<T>(Result<T, String> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail(error),
  };

  setUpAll(() async {
    client = SupabaseClient(
      url,
      anon,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final auth = await client.auth.signInWithPassword(
      email: LocalSeedAgent.email,
      password: LocalSeedAgent.password,
    );

    customers = ok(
      await SupabaseCustomerRepository(client).watchCustomers().first,
    );
    if (customers.isEmpty) {
      skipReason =
          'The seeded agent owns no customers: another agent took over the seed data, or '
          'the database is not seeded. Run `supabase db reset`.';
      return;
    }
    rds = ok(
      await SupabaseRecurringDepositRepository(
        client,
      ).watchRecurringDeposits().first,
    );
    otds = ok(
      await SupabaseOneTimeDepositRepository(
        client,
      ).watchOneTimeDeposits().first,
    );
    facts = ok(
      await SupabaseRDLedgerRepository(
        client,
      ).fetchRawFactsForRds([for (final rd in rds) rd.id]),
    );

    if (seedTodayOverride.isNotEmpty) {
      today = DateTime.parse(seedTodayOverride);
    } else {
      final profile = await client
          .from('agent_profiles')
          .select('created_at')
          .eq('id', auth.user!.id)
          .single();
      // The seed's "today" is the calendar day in India at the moment of the reset.
      final india = DateTime.parse(
        profile['created_at'] as String,
      ).toUtc().add(const Duration(hours: 5, minutes: 30));
      today = DateTime(india.year, india.month, india.day);
    }
  });

  tearDownAll(() async {
    await client.auth.signOut();
    await client.dispose();
  });

  /// Runs [body] unless the seed data is not there.
  void seedTest(String description, void Function() body) {
    test(description, () {
      if (skipReason != null) {
        markTestSkipped(skipReason!);
        return;
      }
      body();
    });
  }

  Customer customer(String name) =>
      customers.singleWhere((c) => c.name == name);

  /// The recurring deposit with that serial number; the seed numbers them 1 to 20.
  RecurringDeposit rd(int serial, String holder) {
    final deposit = rds.singleWhere((d) => d.serialNo == '$serial');
    expect(deposit.customerName, holder, reason: 'holder of serial $serial');
    return deposit;
  }

  RDLedgerProjection ledger(RecurringDeposit deposit) =>
      RDLedgerProjector.standard.project(
        RDLedgerFacts(
          deposit: deposit,
          transactions: facts[deposit.id]?.transactions ?? const [],
          poDeposits: facts[deposit.id]?.poDeposits ?? const [],
          absorptions: facts[deposit.id]?.absorptions ?? const [],
        ),
        asOf: today,
      );

  int thisMonthNo(RecurringDeposit deposit) =>
      RDScheduleFactory.installmentNoFor(deposit.startDate, today);

  /// The installment `monthsAgo` months before this month's (0 = this month).
  RDInstallment installment(RecurringDeposit deposit, {int monthsAgo = 0}) =>
      ledger(deposit).installments[thisMonthNo(deposit) - 1 - monthsAgo];

  RDInstallmentDisplayStatus statusOf(RDInstallment i) =>
      i.displayStatusAt(today);

  /// What an installment nobody has paid or deposited shows on the seed's day.
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

  /// Indian financial year (April to March) a date falls in, named by its first year.
  int financialYear(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

  group('the whole seed', () {
    seedTest(
      '21 customers, 20 recurring deposits numbered 1 to 20, 11 one-time '
      'deposits',
      () {
        expect(customers, hasLength(21));
        expect([for (final d in rds) int.parse(d.serialNo!)]..sort(), [
          for (var n = 1; n <= 20; n++) n,
        ]);
        expect(otds, hasLength(11));
        for (final c in customers) {
          expect(c.notes, startsWith('Seed '), reason: c.name);
        }
      },
    );

    seedTest('nothing is dated after the day of the reset', () {
      for (final d in rds) {
        expect(d.startDate.isAfter(today), isFalse, reason: 'RD ${d.serialNo}');
        for (final tx in facts[d.id]?.transactions ?? const []) {
          expect(
            tx.paidDate.isAfter(today),
            isFalse,
            reason: 'payment on RD ${d.serialNo}',
          );
        }
        for (final po in facts[d.id]?.poDeposits ?? const []) {
          expect(
            po.depositedOn.isAfter(today),
            isFalse,
            reason: 'deposit on RD ${d.serialNo}',
          );
        }
      }
      for (final d in otds) {
        expect(d.startDate.isAfter(today), isFalse, reason: d.accountNo);
      }
    });
  });

  group('Monthly Hub: this month', () {
    seedTest('1 Asha Kulkarni: settled, nothing owed', () {
      final d = rd(1, 'Asha Kulkarni');
      final summary = ledger(d).summary;
      expect(statusOf(installment(d)), RDInstallmentDisplayStatus.settled);
      expect(summary.depositedThroughNo, thisMonthNo(d));
      expect(summary.arrearsCount, 0);
      expect(summary.owedByCustomer, 0);
    });

    seedTest('2 Bharat Shetty: 5,000 in hand in cash, ready to deposit', () {
      final d = rd(2, 'Bharat Shetty');
      final p = ledger(d);
      expect(
        statusOf(installment(d)),
        RDInstallmentDisplayStatus.collectedPendingPo,
      );
      expect(p.poReadiness.readyCount, 1);
      expect(p.summary.cashInHandCash, 5000);
      expect(p.summary.cashInHandDigital, 0);
    });

    seedTest('3 Chitra Nair: 3,000 in hand by UPI', () {
      final d = rd(3, 'Chitra Nair');
      final p = ledger(d);
      expect(
        statusOf(installment(d)),
        RDInstallmentDisplayStatus.collectedPendingPo,
      );
      expect(p.summary.cashInHandDigital, 3000);
      expect(p.summary.cashInHandCash, 0);
    });

    seedTest('4 Dinesh Agarwal: 18,000 in hand in cash, and with Bharat more '
        'than one cash lot', () {
      final d = rd(4, 'Dinesh Agarwal');
      final p = ledger(d);
      expect(
        statusOf(installment(d)),
        RDInstallmentDisplayStatus.collectedPendingPo,
      );
      expect(p.summary.cashInHandCash, 18000);
      expect(
        p.summary.cashInHandCash +
            ledger(rd(2, 'Bharat Shetty')).summary.cashInHandCash,
        greaterThan(kPoCashLotLimit),
      );
    });

    seedTest('5 Esha Fernandes: part paid, 1,500 of 4,000 still owed', () {
      final d = rd(5, 'Esha Fernandes');
      final inst = installment(d);
      expect(statusOf(inst), RDInstallmentDisplayStatus.partiallyPaid);
      expect(inst.customerPaidAmount, 2500);
      expect(inst.outstandingAmount, 1500);
      expect(ledger(d).summary.cashInHandCash, 2500);
    });

    seedTest('6 Farhan Qureshi: paid through last month, this month not yet '
        'paid and not late', () {
      final d = rd(6, 'Farhan Qureshi');
      final inst = installment(d);
      final summary = ledger(d).summary;
      expect(statusOf(inst), unpaidOn(inst.dueDate));
      expect(statusOf(inst), isNot(RDInstallmentDisplayStatus.overdue));
      expect(summary.paidThroughNo, thisMonthNo(d) - 1);
      expect(summary.arrearsCount, 0);
    });

    seedTest('7 Gauri Deshpande: last month overdue with a 25 rupee fee', () {
      final d = rd(7, 'Gauri Deshpande');
      final lastMonth = installment(d, monthsAgo: 1);
      final thisMonth = installment(d);
      final late = today.day > 15;
      expect(statusOf(lastMonth), RDInstallmentDisplayStatus.overdue);
      expect(lastMonth.lateFee, 25);
      expect(statusOf(thisMonth), unpaidOn(thisMonth.dueDate));
      expect(ledger(d).summary.arrearsCount, late ? 2 : 1);
      expect(ledger(d).summary.feeDue, late ? 50 : 25);
    });

    seedTest('8 Harish Gowda: three months in arrears, 90 rupees of fees', () {
      final d = rd(8, 'Harish Gowda');
      final late = today.day > 15;
      for (final monthsAgo in [1, 2, 3]) {
        expect(
          statusOf(installment(d, monthsAgo: monthsAgo)),
          RDInstallmentDisplayStatus.overdue,
          reason: '$monthsAgo month(s) ago',
        );
      }
      expect(installment(d, monthsAgo: 3).lateFee, 45);
      expect(installment(d, monthsAgo: 2).lateFee, 30);
      expect(installment(d, monthsAgo: 1).lateFee, 15);
      expect(ledger(d).summary.arrearsCount, late ? 4 : 3);
      expect(ledger(d).summary.feeDue, late ? 105 : 90);
    });

    seedTest('9 Indira Menon: fronted by the agent, 2,000 receivable', () {
      final d = rd(9, 'Indira Menon');
      final summary = ledger(d).summary;
      expect(
        statusOf(installment(d)),
        RDInstallmentDisplayStatus.frontedByAgent,
      );
      expect(summary.receivable, 2000);
      expect(summary.owedByCustomer, 2000);
      expect(summary.cashInHandCash, 0);
    });

    seedTest('10 Jayant Bhat: three installments and 30 rupees of fees paid at '
        'once, one visit', () {
      final d = rd(10, 'Jayant Bhat');
      final summary = ledger(d).summary;
      for (final monthsAgo in [0, 1, 2]) {
        expect(
          statusOf(installment(d, monthsAgo: monthsAgo)),
          RDInstallmentDisplayStatus.settled,
          reason: '$monthsAgo month(s) ago',
        );
      }
      expect(installment(d, monthsAgo: 2).lateFee, 20);
      expect(installment(d, monthsAgo: 1).lateFee, 10);
      expect(installment(d).lateFee, 0);
      expect(
        facts[d.id]!.poDeposits.map((po) => po.installmentCount),
        contains(3),
      );
      expect(summary.depositedThroughNo, thisMonthNo(d));
      expect(summary.arrearsCount, 0);
      expect(summary.owedByCustomer, 0);
      expect(summary.customerCredit, 0);
    });

    seedTest('11 Kavita Joshi: a 50 rupee fee the agent bore, settled now', () {
      final d = rd(11, 'Kavita Joshi');
      final summary = ledger(d).summary;
      final lateMonth = installment(d, monthsAgo: 3);
      expect(statusOf(installment(d)), RDInstallmentDisplayStatus.settled);
      expect(statusOf(lateMonth), RDInstallmentDisplayStatus.settled);
      expect(lateMonth.poLateFee, 50);
      expect(lateMonth.absorbedFee, 50);
      expect(summary.absorbedTotal, 50);
      expect(summary.owedByCustomer, 0);
      expect(summary.arrearsCount, 0);
    });
  });

  group('account lifecycle', () {
    seedTest(
      '12 Lalit Saxena: opened this month, first installment settled',
      () {
        final d = rd(12, 'Lalit Saxena');
        expect(thisMonthNo(d), 1);
        expect(d.initialPaidInstallments, 0);
        expect(statusOf(installment(d)), RDInstallmentDisplayStatus.settled);
      },
    );

    seedTest('13 Meera Iyer: 36 installments before the app, 10,000 opening '
        'receivable', () {
      final d = rd(13, 'Meera Iyer');
      final summary = ledger(d).summary;
      final inst = installment(d);
      expect(d.initialPaidInstallments, 36);
      expect(thisMonthNo(d), 37);
      expect(
        statusOf(installment(d, monthsAgo: 1)),
        RDInstallmentDisplayStatus.baseline,
      );
      expect(statusOf(inst), unpaidOn(inst.dueDate));
      expect(summary.openingReceivableLeft, 10000);
      expect(summary.owedByCustomer, 10000);
    });

    seedTest('14 Naveen Pillai: both accounts maturing soon', () {
      final c = customer('Naveen Pillai');
      expect(
        rd(14, c.name).maturityUrgencyAt(today),
        MaturityUrgency.maturingSoon,
      );
      final td = otdsOf(c).single;
      expect(td.schemeType, OneTimeSchemeType.timeDeposit);
      expect(td.maturityUrgencyAt(today), MaturityUrgency.maturingSoon);
    });

    seedTest('15 Omana Kurup: both accounts matured and still open', () {
      final c = customer('Omana Kurup');
      final d = rd(15, c.name);
      expect(d.status, DepositStatus.active);
      expect(d.maturityUrgencyAt(today), MaturityUrgency.matured);
      final nsc = otdsOf(c).single;
      expect(nsc.schemeType, OneTimeSchemeType.nationalSavingsCertificate);
      expect(nsc.status, DepositStatus.active);
      expect(nsc.maturityUrgencyAt(today), MaturityUrgency.matured);
    });

    seedTest('16 Prakash Rao: both accounts closed', () {
      final c = customer('Prakash Rao');
      final d = rd(16, c.name);
      expect(d.status, DepositStatus.closed);
      expect(d.maturityUrgencyAt(today), MaturityUrgency.closed);
      final td = otdsOf(c).single;
      expect(td.status, DepositStatus.closed);
      expect(td.maturityUrgencyAt(today), MaturityUrgency.closed);
    });
  });

  group('customer shape', () {
    seedTest('17 Ramesh Hegde: two recurring deposits, every one-time scheme, '
        'four financial years', () {
      final c = customer('Ramesh Hegde');
      final settled = rd(17, c.name);
      final unpaid = rd(18, c.name);
      expect(
        statusOf(installment(settled)),
        RDInstallmentDisplayStatus.settled,
      );
      expect(installment(settled).dueDate.day, 15);
      final unpaidInst = installment(unpaid);
      expect(statusOf(unpaidInst), unpaidOn(unpaidInst.dueDate));
      expect(statusOf(unpaidInst), isNot(RDInstallmentDisplayStatus.overdue));

      final held = otdsOf(c);
      expect(
        {
          for (final d in held)
            if (d.schemeType == OneTimeSchemeType.timeDeposit) d.termYears,
        },
        {1, 2, 3, 5},
      );
      expect({
        for (final d in held) d.schemeType,
      }, OneTimeSchemeType.values.toSet());
      expect(
        held
            .singleWhere(
              (d) => d.schemeType == OneTimeSchemeType.monthlyIncomeScheme,
            )
            .principalAmount,
        900000,
      );
      expect(
        {
          for (final d in held) financialYear(d.startDate),
          financialYear(settled.startDate),
          financialYear(unpaid.startDate),
        }.length,
        greaterThanOrEqualTo(4),
      );
    });

    seedTest('18 Sunita Thomas: only a name, and one 1,000 rupee Time '
        'Deposit', () {
      final c = customer('Sunita Thomas');
      expect([
        c.phone,
        c.email,
        c.address,
        c.cifNumber,
        c.aadhaarNumber,
        c.panNumber,
        c.dateOfBirth,
      ], everyElement(isNull));
      expect(otdsOf(c).single.principalAmount, 1000);
      expect(rds.where((d) => d.customerId == c.id), isEmpty);
    });

    seedTest('19 Tejaswini …: a name of more than 50 characters, not yet paid '
        'this month', () {
      final c = customers.singleWhere((c) => c.name.startsWith('Tejaswini'));
      expect(c.name.length, greaterThan(50));
      final inst = installment(rd(19, c.name));
      expect(statusOf(inst), unpaidOn(inst.dueDate));
      expect(statusOf(inst), isNot(RDInstallmentDisplayStatus.overdue));
    });

    seedTest('20 Uma Bose: no account of any kind', () {
      final c = customer('Uma Bose');
      expect(rds.where((d) => d.customerId == c.id), isEmpty);
      expect(otdsOf(c), isEmpty);
    });

    seedTest('21 a name in Kannada script, recurring deposit settled', () {
      final c = customers.singleWhere(
        (c) => RegExp(r'[\u0C80-\u0CFF]').hasMatch(c.name),
      );
      expect(
        statusOf(installment(rd(20, c.name))),
        RDInstallmentDisplayStatus.settled,
      );
    });
  });

  // The lists above leave out what only a detail screen loads.
  group('details', () {
    test('17 Ramesh Hegde: a savings account whose three nominees add up to '
        '100%', () async {
      if (skipReason != null) {
        markTestSkipped(skipReason!);
        return;
      }
      final detail = ok(
        await SupabaseCustomerRepository(
          client,
        ).watchCustomerById(customer('Ramesh Hegde').id).first,
      );
      final nominees = detail.savingsAccount!.nominees;
      expect(nominees, hasLength(3));
      expect(Nominee.validateNominees(nominees), isNull);
    });

    test('18 and 20: no savings account, and a Time Deposit with no '
        'nominee', () async {
      if (skipReason != null) {
        markTestSkipped(skipReason!);
        return;
      }
      final repo = SupabaseCustomerRepository(client);
      for (final name in ['Sunita Thomas', 'Uma Bose']) {
        final detail = ok(
          await repo.watchCustomerById(customer(name).id).first,
        );
        expect(detail.savingsAccount, isNull, reason: name);
      }
      final td = ok(
        await SupabaseOneTimeDepositRepository(client)
            .watchOneTimeDepositById(
              otdsOf(customer('Sunita Thomas')).single.id,
            )
            .first,
      );
      expect(td.nominees, isEmpty);
    });
  });
}
