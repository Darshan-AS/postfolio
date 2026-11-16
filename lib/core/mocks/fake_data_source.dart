import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_rules.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_schedule_factory.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

/// Deterministic, zero-dependency in-memory portfolio for Demo Mode and offline UI smoke tests.
///
/// Every record satisfies all domain invariants (100% nominee share totals, valid PAN/Aadhaar/CIF
/// formats, official Post Office scheme terms, and causally ordered RD ledger facts).
class FakeDataSource {
  static final FakeDataSource _instance = FakeDataSource._internal();
  factory FakeDataSource() => _instance;

  static const PostalRateService _postalRateService = PostalRateService();
  static final DateTime _referenceToday = DateTime(2026, 10, 27);

  late final List<Customer> customers;
  late final List<OneTimeDeposit> oneTimeDeposits;
  late final List<RecurringDeposit> recurringDeposits;
  late final Map<String, List<RDTransaction>> rdTransactions;
  late final Map<String, List<RDPoDeposit>> rdPoDeposits;

  FakeDataSource._internal() {
    _buildDeterministicPortfolio();
  }

  void _buildDeterministicPortfolio() {
    const seeds = <({
      String id,
      String name,
      String phone,
      String cif,
      String pan,
      String aadhaar,
      String sbNo,
      List<Nominee> nominees,
    })>[
      (
        id: 'demo-cust-01',
        name: 'Arjun Mehta',
        phone: '+919876543201',
        cif: 'CIF100201',
        pan: 'ABCDE1201F',
        aadhaar: '2345 6789 0101',
        sbNo: '0100200301',
        nominees: [
          Nominee(name: 'Sujata Mehta', relationship: NomineeRelationship.wife, percentage: 100),
        ],
      ),
      (
        id: 'demo-cust-02',
        name: 'Deepika Sharma',
        phone: '+919876543202',
        cif: 'CIF100202',
        pan: 'FGHIJ5602K',
        aadhaar: '2345 6789 0102',
        sbNo: '0100200302',
        nominees: [
          Nominee(name: 'Siddharth Sharma', relationship: NomineeRelationship.husband, percentage: 50),
          Nominee(name: 'Kriti Sharma', relationship: NomineeRelationship.daughter, percentage: 50),
        ],
      ),
      (
        id: 'demo-cust-03',
        name: 'Rohan Varma',
        phone: '+919876543203',
        cif: 'CIF100203',
        pan: 'KLMNO9003P',
        aadhaar: '2345 6789 0103',
        sbNo: '0100200303',
        nominees: [
          Nominee(name: 'Preeti Varma', relationship: NomineeRelationship.wife, percentage: 100),
        ],
      ),
      (
        id: 'demo-cust-04',
        name: 'Kavita Iyer',
        phone: '+919876543204',
        cif: 'CIF100204',
        pan: 'PQRST3404L',
        aadhaar: '2345 6789 0104',
        sbNo: '0100200304',
        nominees: [
          Nominee(name: 'Raghav Iyer', relationship: NomineeRelationship.son, percentage: 60),
          Nominee(name: 'Ananya Iyer', relationship: NomineeRelationship.daughter, percentage: 40),
        ],
      ),
      (
        id: 'demo-cust-05',
        name: 'Suresh Nair',
        phone: '+919876543205',
        cif: 'CIF100205',
        pan: 'UVWXY7805M',
        aadhaar: '2345 6789 0105',
        sbNo: '0100200305',
        nominees: [
          Nominee(name: 'Lakshmi Nair', relationship: NomineeRelationship.wife, percentage: 100),
        ],
      ),
      (
        id: 'demo-cust-06',
        name: 'Meenakshi Rao',
        phone: '+919876543206',
        cif: 'CIF100206',
        pan: 'ZABCD2306N',
        aadhaar: '2345 6789 0106',
        sbNo: '0100200306',
        nominees: [
          Nominee(name: 'Prakash Rao', relationship: NomineeRelationship.brother, percentage: 100),
        ],
      ),
    ];

    customers = [
      for (var i = 0; i < seeds.length; i++)
        Customer(
          id: seeds[i].id,
          name: seeds[i].name,
          email: '${seeds[i].name.toLowerCase().replaceAll(' ', '.')}@example.com',
          phone: seeds[i].phone,
          address: '${101 + i}, Post Office Road, Bengaluru',
          cifNumber: seeds[i].cif,
          dateOfBirth: DateTime(1975 + i * 3, (i % 12) + 1, 12),
          aadhaarNumber: seeds[i].aadhaar,
          panNumber: seeds[i].pan,
          savingsAccount: SavingsAccount(
            accountNumber: seeds[i].sbNo,
            nominees: seeds[i].nominees,
          ),
        ),
    ];

    final otdSpecs = <({
      String id,
      String custId,
      OneTimeSchemeType scheme,
      double principal,
      DateTime start,
      int? tdYears,
      DepositStatus status,
    })>[
      (
        id: 'demo-otd-01',
        custId: 'demo-cust-01',
        scheme: OneTimeSchemeType.monthlyIncomeScheme,
        principal: 450000,
        start: DateTime(2024, 5, 10),
        tdYears: null,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-otd-02',
        custId: 'demo-cust-02',
        scheme: OneTimeSchemeType.kisanVikasPatra,
        principal: 200000,
        start: DateTime(2023, 8, 15),
        tdYears: null,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-otd-03',
        custId: 'demo-cust-03',
        scheme: OneTimeSchemeType.timeDeposit,
        principal: 300000,
        start: DateTime(2025, 4, 20),
        tdYears: 5,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-otd-04',
        custId: 'demo-cust-04',
        scheme: OneTimeSchemeType.nationalSavingsCertificate,
        principal: 150000,
        start: DateTime(2025, 7, 5),
        tdYears: null,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-otd-05',
        custId: 'demo-cust-05',
        scheme: OneTimeSchemeType.timeDeposit,
        principal: 100000,
        start: DateTime(2024, 11, 1),
        tdYears: 2,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-otd-06',
        custId: 'demo-cust-06',
        scheme: OneTimeSchemeType.timeDeposit,
        principal: 75000,
        start: DateTime(2022, 6, 1),
        tdYears: 1,
        status: DepositStatus.closed,
      ),
    ];

    oneTimeDeposits = [
      for (var i = 0; i < otdSpecs.length; i++)
        () {
          final s = otdSpecs[i];
          final cust = customers.firstWhere((c) => c.id == s.custId);
          final terms = _postalRateService.resolveOneTimeSchemeTerms(
            schemeType: s.scheme,
            startDate: s.start,
            tdTenureYears: s.tdYears,
          );
          return OneTimeDeposit(
            id: s.id,
            accountNo: '50060070${i + 1}',
            principalAmount: s.principal,
            termYears: terms.termYears,
            termMonths: terms.termMonths,
            interestRate: terms.interestRate,
            customerId: cust.id,
            customerName: cust.name,
            schemeType: s.scheme,
            startDate: s.start,
            status: s.status,
            nominees: cust.savingsAccount?.nominees ?? const [],
          );
        }(),
    ];

    final rdSpecs = <({
      String id,
      String serial,
      String custId,
      double amount,
      DateTime start,
      int initialPaid,
      DepositStatus status,
    })>[
      (
        id: 'demo-rd-01',
        serial: '1',
        custId: 'demo-cust-01',
        amount: 5000,
        start: DateTime(2025, 1, 10),
        initialPaid: 12,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-rd-02',
        serial: '2',
        custId: 'demo-cust-02',
        amount: 10000,
        start: DateTime(2024, 6, 5),
        initialPaid: 24,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-rd-03',
        serial: '3',
        custId: 'demo-cust-03',
        amount: 2000,
        start: DateTime(2026, 5, 20),
        initialPaid: 0,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-rd-04',
        serial: '4',
        custId: 'demo-cust-04',
        amount: 3000,
        start: DateTime(2026, 2, 12),
        initialPaid: 0,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-rd-05',
        serial: '5',
        custId: 'demo-cust-05',
        amount: 1500,
        start: DateTime(2026, 3, 25),
        initialPaid: 0,
        status: DepositStatus.active,
      ),
      (
        id: 'demo-rd-06',
        serial: '6',
        custId: 'demo-cust-06',
        amount: 2500,
        start: DateTime(2020, 4, 10),
        initialPaid: 60,
        status: DepositStatus.closed,
      ),
    ];

    recurringDeposits = [
      for (var i = 0; i < rdSpecs.length; i++)
        () {
          final s = rdSpecs[i];
          final cust = customers.firstWhere((c) => c.id == s.custId);
          final terms = _postalRateService.resolveRecurringSchemeTerms(
            schemeType: RecurringSchemeType.recurringDeposit,
            startDate: s.start,
          );
          return RecurringDeposit(
            id: s.id,
            serialNo: s.serial,
            accountNo: '10020030${i + 1}',
            installmentAmount: s.amount,
            termYears: terms.termYears,
            termMonths: terms.termMonths,
            interestRate: terms.interestRate,
            customerId: cust.id,
            customerName: cust.name,
            schemeType: RecurringSchemeType.recurringDeposit,
            startDate: s.start,
            initialPaidInstallments: s.initialPaid,
            status: s.status,
            nominees: cust.savingsAccount?.nominees ?? const [],
          );
        }(),
    ];

    rdTransactions = {};
    rdPoDeposits = {};

    for (var idx = 0; idx < recurringDeposits.length; idx++) {
      final rd = recurringDeposits[idx];
      if (rd.status != DepositStatus.active) continue;

      final txs = <RDTransaction>[];
      final poEvents = <RDPoDeposit>[];
      var depositedThrough = rd.initialPaidInstallments;
      var paidCount = 0;

      for (var no = rd.initialPaidInstallments + 1; no <= rd.totalMonths; no++) {
        final month = RDScheduleFactory.installmentDateFor(rd.startDate, no);
        final due = RDLedgerRules.standard.dueDateFor(rd.startDate, month);
        if (!due.isBefore(_referenceToday)) break;

        // Deterministically leave recent months unpaid on alternate accounts to showcase arrears.
        if ((no + idx) % 5 == 0) continue;

        final dayOffset = ((no + idx) % 3 == 0) ? 2 : -2;
        final paidDay = DateTime(due.year, due.month, due.day).add(Duration(days: dayOffset));
        final lateMonths = RDLedgerRules.standard.defaultedMonths(due, paidDay);
        final fee = RDLedgerRules.standard.defaultFeeFor(rd.installmentAmount, lateMonths);

        txs.add(
          RDTransaction(
            id: '${rd.id}-tx-$no',
            rdId: rd.id,
            paidDate: paidDay,
            amount: rd.installmentAmount + fee,
            paymentMode: no.isEven ? RDPaymentMode.upi : RDPaymentMode.cash,
            createdAt: paidDay,
          ),
        );
        paidCount++;

        // Deposit earlier months at the PO, keeping the latest collected month in hand.
        if (paidCount >= 2 && (no % 2 == 0) && depositedThrough < no - 1) {
          final targetNo = no - 1;
          final count = targetNo - depositedThrough;
          final depositedOn = paidDay.add(const Duration(days: 1));
          var feePaid = 0.0;
          for (var k = depositedThrough + 1; k <= targetNo; k++) {
            final kDue = RDLedgerRules.standard.dueDateFor(
              rd.startDate,
              RDScheduleFactory.installmentDateFor(rd.startDate, k),
            );
            feePaid += RDLedgerRules.standard.defaultFeeFor(
              rd.installmentAmount,
              RDLedgerRules.standard.defaultedMonths(kDue, depositedOn),
            );
          }
          poEvents.add(
            RDPoDeposit(
              id: '${rd.id}-po-$targetNo',
              rdId: rd.id,
              depositedOn: depositedOn,
              installmentCount: count,
              feePaid: feePaid,
              amount: count * rd.installmentAmount + feePaid,
              createdAt: depositedOn,
            ),
          );
          depositedThrough = targetNo;
        }
      }

      rdTransactions[rd.id] = txs;
      rdPoDeposits[rd.id] = poEvents;
    }
  }
}
