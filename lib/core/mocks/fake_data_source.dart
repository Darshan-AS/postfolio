import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

/// Deterministic, zero-dependency in-memory portfolio for Demo Mode and offline UI tests.
///
/// Mirrors `supabase/seed.sql` 1-to-1 for the primary agent: 22 DC Universe customers,
/// 21 recurring deposits, 17 one-time deposits (TD 1Y/2Y/3Y/5Y, MIS, NSC, KVP),
/// 1 savings account, 38 nominees, and causally ordered RD ledger facts (payments across
/// cash/UPI/bank transfer, PO visits, and fee absorptions).
///
/// Every date is computed relative to [referenceDate] so "this month", "overdue", and
/// "maturing soon" hold on any calendar day without dating anything in the future.
/// Demo Mode constructs [FakeDataSource.forDate] from `currentDateProvider`; unit/widget
/// tests calling [FakeDataSource] get a stable portfolio anchored at [defaultReferenceDate].
class FakeDataSource {
  /// Fixed calendar date used by the zero-argument factory so tests that call
  /// `FakeDataSource()` stay deterministic regardless of the machine's clock.
  static final DateTime defaultReferenceDate = DateTime(2026, 10, 27);

  static final FakeDataSource _defaultInstance = FakeDataSource.forDate(
    defaultReferenceDate,
  );

  /// Deterministic portfolio anchored at [defaultReferenceDate] for unit and widget tests.
  factory FakeDataSource() => _defaultInstance;

  /// Builds the full 22-customer portfolio with every date computed relative to [today].
  FakeDataSource.forDate(DateTime today)
    : referenceDate = DateTime(today.year, today.month, today.day) {
    _buildPortfolio();
  }

  /// Calendar date ("today") that all relative dates in this portfolio were built against.
  final DateTime referenceDate;

  late final List<Customer> customers;
  late final List<OneTimeDeposit> oneTimeDeposits;
  late final List<RecurringDeposit> recurringDeposits;
  late final Map<String, List<RDTransaction>> rdTransactions;
  late final Map<String, List<RDPoDeposit>> rdPoDeposits;
  late final Map<String, List<RDFeeAbsorption>> rdFeeAbsorptions;

  /// Day [day] of the month [monthsAgo] months back (`0` = this month).
  /// Clamps days beyond the month's length, and caps dates in this month at [referenceDate].
  DateTime _dt(int monthsAgo, int day) {
    final first = DateTime(
      referenceDate.year,
      referenceDate.month - monthsAgo,
      1,
    );
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    final clampedDay = day > lastDay ? lastDay : day;
    final candidate = DateTime(first.year, first.month, clampedDay);
    if (monthsAgo <= 0 && candidate.isAfter(referenceDate)) {
      return referenceDate;
    }
    return candidate;
  }

  /// Calendar date [deltaDays] days from [referenceDate], DST-safe.
  DateTime _addDays(int deltaDays) => DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day + deltaDays,
  );

  /// Subtracts [months] months from [date], clamping the day to month end (matching Postgres).
  static DateTime _subtractMonths(DateTime date, int months) {
    final targetFirst = DateTime(date.year, date.month - months, 1);
    final lastDay = DateTime(targetFirst.year, targetFirst.month + 1, 0).day;
    return DateTime(
      targetFirst.year,
      targetFirst.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  void _buildPortfolio() {
    final customerList = <Customer>[];
    final customerByKey = <String, Customer>{};
    final otdList = <OneTimeDeposit>[];
    final rdList = <RecurringDeposit>[];
    final rdByKey = <String, RecurringDeposit>{};
    final txByRdId = <String, List<RDTransaction>>{};
    final poByRdId = <String, List<RDPoDeposit>>{};
    final absByRdId = <String, List<RDFeeAbsorption>>{};
    var txSeq = 0;
    var poSeq = 0;

    void addCustomer(
      String key,
      String name,
      String notes, {
      String? phone,
      String? address,
      DateTime? dob,
      String? cif,
      String? aadhaar,
      String? pan,
      String? email,
      SavingsAccount? savingsAccount,
    }) {
      final c = Customer(
        id: 'demo-cust-$key',
        name: name,
        notes: notes,
        phone: phone,
        address: address,
        dateOfBirth: dob,
        cifNumber: cif,
        aadhaarNumber: aadhaar,
        panNumber: pan,
        email: email,
        savingsAccount: savingsAccount,
      );
      customerList.add(c);
      customerByKey[key] = c;
    }

    void addRd(
      String key,
      int serial,
      double amount,
      DateTime start,
      int baseline, {
      String? customerKey,
      DepositStatus status = DepositStatus.active,
      double rate = 6.7,
      double openingReceivable = 0,
      List<Nominee> nominees = const [],
    }) {
      final holder = customerByKey[customerKey ?? key]!;
      final rd = RecurringDeposit(
        id: 'demo-rd-$key',
        serialNo: '$serial',
        accountNo: '02000100${serial.toString().padLeft(2, '0')}',
        installmentAmount: amount,
        termYears: 5,
        termMonths: 0,
        interestRate: rate,
        customerId: holder.id,
        customerName: holder.name,
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: start,
        initialPaidInstallments: baseline,
        openingReceivable: openingReceivable,
        status: status,
        nominees: nominees,
      );
      rdList.add(rd);
      rdByKey[key] = rd;
    }

    void addOtd(
      String key,
      String customerKey,
      OneTimeSchemeType scheme,
      int no,
      double principal,
      double rate,
      int years,
      int months,
      DateTime start, {
      DepositStatus status = DepositStatus.active,
      List<Nominee> nominees = const [],
    }) {
      final holder = customerByKey[customerKey]!;
      otdList.add(
        OneTimeDeposit(
          id: 'demo-otd-$key',
          accountNo: '03000200${no.toString().padLeft(2, '0')}',
          principalAmount: principal,
          termYears: years,
          termMonths: months,
          interestRate: rate,
          customerId: holder.id,
          customerName: holder.name,
          schemeType: scheme,
          startDate: start,
          status: status,
          nominees: nominees,
        ),
      );
    }

    void collect(
      String rdKey,
      DateTime on,
      double amount, {
      RDPaymentMode mode = RDPaymentMode.cash,
    }) {
      final rd = rdByKey[rdKey]!;
      txByRdId
          .putIfAbsent(rd.id, () => [])
          .add(
            RDTransaction(
              id: 'demo-tx-$rdKey-${++txSeq}',
              rdId: rd.id,
              paidDate: on,
              amount: amount,
              paymentMode: mode,
              createdAt: on,
            ),
          );
    }

    void deposit(String rdKey, DateTime on, {int count = 1, double fee = 0}) {
      final rd = rdByKey[rdKey]!;
      poByRdId
          .putIfAbsent(rd.id, () => [])
          .add(
            RDPoDeposit(
              id: 'demo-po-$rdKey-${++poSeq}',
              rdId: rd.id,
              depositedOn: on,
              installmentCount: count,
              feePaid: fee,
              amount: rd.installmentAmount * count + fee,
              createdAt: on,
            ),
          );
    }

    void onTime(
      String rdKey,
      int fromMonthsAgo,
      int toMonthsAgo, {
      RDPaymentMode mode = RDPaymentMode.cash,
    }) {
      final rd = rdByKey[rdKey]!;
      final dueOn15th = rd.startDate.day <= 15;
      for (var m = fromMonthsAgo; m >= toMonthsAgo; m--) {
        collect(
          rdKey,
          _dt(m, dueOn15th ? 5 : 20),
          rd.installmentAmount,
          mode: mode,
        );
        deposit(rdKey, _dt(m, dueOn15th ? 8 : 22));
      }
    }

    void absorb(String rdKey, DateTime on, double amount, String note) {
      final rd = rdByKey[rdKey]!;
      final installmentNo =
          (on.year - rd.startDate.year) * 12 +
          (on.month - rd.startDate.month) +
          1;
      absByRdId
          .putIfAbsent(rd.id, () => [])
          .add(
            RDFeeAbsorption(
              rdId: rd.id,
              installmentNo: installmentNo,
              amount: amount,
              absorbedOn: on,
              note: note,
              createdAt: on,
            ),
          );
    }

    // -------------------------------------------------------------------------
    // 1–13. Monthly Hub & Ledger Intermediate States (alphabetically front-loaded)
    // -------------------------------------------------------------------------

    // 1. In hand (cash): collected this month, ready to deposit at the PO.
    addCustomer(
      'alfred',
      'Alfred Pennyworth',
      'Collects household cash on the 3rd; prefers receipt slip for Wayne Manor records.',
      phone: '9845012301',
      address: '1007 Mountain Drive, Bristol, Gotham 400001',
      dob: DateTime(1958, 4, 2),
      cif: '100200301',
      aadhaar: '412398760011',
      pan: 'APENP1234A',
      email: 'alfred.pennyworth@wayne.example',
    );
    addRd(
      'alfred',
      1,
      5000,
      _dt(9, 5),
      7,
      nominees: const [
        Nominee(
          name: 'Julia Pennyworth',
          relationship: NomineeRelationship.daughter,
          percentage: 100,
        ),
      ],
    );
    onTime('alfred', 2, 1);
    collect('alfred', _dt(0, 3), 5000);

    // 2. One month in arrears: last month unpaid with default fee.
    addCustomer(
      'arthur',
      'Arthur Curry',
      'Frequently offshore near Amnesty Bay; remind via call when an installment slips past the 15th.',
      phone: '9845012302',
      address: 'Lighthouse Point, Amnesty Bay 576201',
      dob: DateTime(1982, 1, 29),
      cif: '100200302',
      aadhaar: '412398760022',
      pan: 'ACURC2345B',
    );
    addRd(
      'arthur',
      2,
      2500,
      _dt(11, 7),
      8,
      nominees: const [
        Nominee(
          name: 'Mera Curry',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('arthur', 3, 2);

    // 3. Part paid: ₹2,500 of ₹4,000 received this month; due at month end.
    addCustomer(
      'barbara',
      'Barbara Gordon',
      'Splits monthly RD in two parts around Burnside library payroll.',
      phone: '9845012303',
      address: '42 Clock Tower Lane, Burnside, Gotham 575001',
      dob: DateTime(1991, 9, 23),
      cif: '100200303',
      aadhaar: '412398760033',
      pan: 'BGORG3456C',
    );
    addRd(
      'barbara',
      3,
      4000,
      _dt(30, 20),
      28,
      nominees: const [
        Nominee(
          name: 'James Gordon',
          relationship: NomineeRelationship.father,
          percentage: 100,
        ),
      ],
    );
    onTime('barbara', 2, 1);
    collect('barbara', _dt(0, 2), 2500);

    // 4. Advance paid (+2 months ahead): settled through thisMonth + 2 via UPI.
    addCustomer(
      'barry',
      'Barry Allen',
      'Always pays two months ahead via UPI so he never misses a due date during CCPD lab shifts.',
      phone: '9845012304',
      address: '112 Speedway Ave, Central City 581401',
      dob: DateTime(1992, 3, 14),
      cif: '100200304',
      aadhaar: '412398760044',
      pan: 'BALLA4567D',
      email: 'barry.allen@ccpd.example',
    );
    addRd(
      'barry',
      4,
      2000,
      _dt(14, 10),
      11,
      nominees: const [
        Nominee(
          name: 'Iris West-Allen',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('barry', 3, 1, mode: RDPaymentMode.upi);
    collect('barry', _dt(0, 1), 6000, mode: RDPaymentMode.upi);
    deposit('barry', _dt(0, 2), count: 3);

    // 5. Household with many accounts: 2 RDs (settled + due month-end), all 4 OTD schemes
    //    across 4+ financial years, and Savings Bank with 3 nominees.
    addCustomer(
      'bruce',
      'Bruce Wayne',
      'Multi-scheme family portfolio across Wayne Manor; quarterly review with Alfred.',
      phone: '9845012305',
      address: 'Wayne Manor, 1007 Mountain Drive, Gotham 581402',
      dob: DateTime(1978, 2, 19),
      cif: '100200305',
      aadhaar: '412398760055',
      pan: 'BWAYW5678E',
      email: 'bruce.wayne@wayne.example',
      savingsAccount: const SavingsAccount(
        accountNumber: '0100030017',
        nominees: [
          Nominee(
            name: 'Dick Grayson',
            relationship: NomineeRelationship.son,
            percentage: 33.34,
          ),
          Nominee(
            name: 'Damian Wayne',
            relationship: NomineeRelationship.son,
            percentage: 33.33,
          ),
          Nominee(
            name: 'Cassandra Cain',
            relationship: NomineeRelationship.daughter,
            percentage: 33.33,
          ),
        ],
      ),
    );
    const dickNominee = [
      Nominee(
        name: 'Dick Grayson',
        relationship: NomineeRelationship.son,
        percentage: 100,
      ),
    ];
    const damianNominee = [
      Nominee(
        name: 'Damian Wayne',
        relationship: NomineeRelationship.son,
        percentage: 100,
      ),
    ];
    const cassandraNominee = [
      Nominee(
        name: 'Cassandra Cain',
        relationship: NomineeRelationship.daughter,
        percentage: 100,
      ),
    ];
    addRd(
      'bruce-a',
      5,
      5000,
      _dt(20, 10),
      18,
      customerKey: 'bruce',
      nominees: dickNominee,
    );
    onTime('bruce-a', 2, 0);
    addRd(
      'bruce-b',
      6,
      1500,
      _dt(7, 22),
      5,
      customerKey: 'bruce',
      nominees: damianNominee,
    );
    onTime('bruce-b', 2, 1);
    addOtd(
      'bruce-td2',
      'bruce',
      OneTimeSchemeType.timeDeposit,
      1,
      200000,
      7.0,
      2,
      0,
      _dt(14, 12),
      nominees: dickNominee,
    );
    addOtd(
      'bruce-td5',
      'bruce',
      OneTimeSchemeType.timeDeposit,
      2,
      500000,
      7.5,
      5,
      0,
      _dt(38, 12),
      nominees: cassandraNominee,
    );
    addOtd(
      'bruce-mis',
      'bruce',
      OneTimeSchemeType.monthlyIncomeScheme,
      3,
      900000,
      7.4,
      5,
      0,
      _dt(30, 6),
      nominees: dickNominee,
    );
    addOtd(
      'bruce-nsc',
      'bruce',
      OneTimeSchemeType.nationalSavingsCertificate,
      4,
      150000,
      7.7,
      5,
      0,
      _dt(18, 21),
      nominees: const [
        Nominee(
          name: 'Damian Wayne',
          relationship: NomineeRelationship.son,
          percentage: 50,
        ),
        Nominee(
          name: 'Cassandra Cain',
          relationship: NomineeRelationship.daughter,
          percentage: 50,
        ),
      ],
    );
    addOtd(
      'bruce-kvp',
      'bruce',
      OneTimeSchemeType.kisanVikasPatra,
      5,
      100000,
      7.5,
      9,
      7,
      _dt(8, 3),
      nominees: dickNominee,
    );

    // 6. Rich Year-1 passbook showcase (0 baseline): settled history + absorbed fee
    //    3 months ago + UPI collected this month ready for PO deposit.
    addCustomer(
      'clark',
      'Clark Kent',
      'Daily Planet reporter; transfers every month via UPI and checks his passbook closely.',
      phone: '9845012306',
      address: '344 Clinton Street, Apt 3B, Metropolis 576101',
      dob: DateTime(1984, 2, 29),
      cif: '100200306',
      aadhaar: '412398760066',
      pan: 'CKEPK6789F',
      email: 'clark.kent@planet.example',
    );
    addRd(
      'clark',
      7,
      3000,
      _dt(7, 10),
      0,
      nominees: const [
        Nominee(
          name: 'Lois Lane',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('clark', 7, 4, mode: RDPaymentMode.upi);
    collect('clark', _dt(3, 16), 3000, mode: RDPaymentMode.upi);
    deposit('clark', _dt(3, 18), count: 1, fee: 30);
    absorb('clark', _dt(3, 18), 30, 'Smallville storm delay; fee covered');
    onTime('clark', 2, 1, mode: RDPaymentMode.upi);
    collect('clark', _dt(0, 4), 3000, mode: RDPaymentMode.upi);

    // 7. Large cash in hand (with Alfred > ₹20,000 → two PO cash lots) + maturing-soon MIS.
    addCustomer(
      'diana',
      'Diana Prince',
      'Curator at Themyscira Antiquities Wing; brings large cash installments in person.',
      phone: '9845012307',
      address: '7 Embassy Row, Gateway City 580020',
      dob: DateTime(1975, 3, 22),
      cif: '100200307',
      aadhaar: '412398760077',
      pan: 'DPRPP7890G',
      email: 'diana.prince@themyscira.example',
    );
    addRd(
      'diana',
      8,
      18000,
      _dt(5, 8),
      3,
      nominees: const [
        Nominee(
          name: 'Hippolyta',
          relationship: NomineeRelationship.mother,
          percentage: 60,
        ),
        Nominee(
          name: 'Donna Troy',
          relationship: NomineeRelationship.sister,
          percentage: 40,
        ),
      ],
    );
    onTime('diana', 2, 1);
    collect('diana', _dt(0, 2), 18000);
    final in15Days = _addDays(15);
    addOtd(
      'diana-mis',
      'diana',
      OneTimeSchemeType.monthlyIncomeScheme,
      6,
      450000,
      6.6,
      5,
      0,
      _subtractMonths(in15Days, 60),
      nominees: const [
        Nominee(
          name: 'Hippolyta',
          relationship: NomineeRelationship.mother,
          percentage: 100,
        ),
      ],
    );

    // 8. In hand via bankTransfer + maturing-soon KVP (25 days).
    addCustomer(
      'edward',
      'Edward Nygma',
      'Sends exact installments via bank transfer; tracks maturity dates to the day.',
      phone: '9845012308',
      address: '1404 Riddle Arcade, Midtown Gotham 580001',
      dob: DateTime(1983, 6, 15),
      cif: '100200308',
      aadhaar: '412398760088',
      pan: 'ENYPN8901H',
    );
    addRd(
      'edward',
      9,
      3500,
      _dt(16, 12),
      14,
      nominees: const [
        Nominee(
          name: 'Kristen Kringle',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('edward', 2, 1, mode: RDPaymentMode.bankTransfer);
    collect('edward', _dt(0, 4), 3500, mode: RDPaymentMode.bankTransfer);
    final in25Days = _addDays(25);
    addOtd(
      'edward-kvp',
      'edward',
      OneTimeSchemeType.kisanVikasPatra,
      7,
      100000,
      7.5,
      9,
      7,
      _subtractMonths(in25Days, 115),
      nominees: const [
        Nominee(
          name: 'Kristen Kringle',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );

    // 9. Fronted by agent (₹2,000 receivable) + active NSC.
    addCustomer(
      'hal',
      'Hal Jordan',
      'Test pilot at Ferris Aircraft; agent fronts RD when he is away on sector duty.',
      phone: '9845012309',
      address: 'Hangar 7, Coast City 577201',
      dob: DateTime(1981, 2, 20),
      cif: '100200309',
      aadhaar: '412398760099',
      pan: 'HJOPJ9012I',
    );
    addRd(
      'hal',
      10,
      2000,
      _dt(40, 14),
      38,
      nominees: const [
        Nominee(
          name: 'Carol Ferris',
          relationship: NomineeRelationship.wife,
          percentage: 50,
        ),
        Nominee(
          name: 'Jim Jordan',
          relationship: NomineeRelationship.brother,
          percentage: 50,
        ),
      ],
    );
    onTime('hal', 2, 1);
    deposit('hal', _dt(0, 2));
    addOtd(
      'hal-nsc',
      'hal',
      OneTimeSchemeType.nationalSavingsCertificate,
      8,
      75000,
      7.7,
      5,
      0,
      _dt(51, 15),
      nominees: const [
        Nominee(
          name: 'Carol Ferris',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );

    // 10. Caught up: 2 months missed, then 3 installments + ₹30 fees paid & deposited at once.
    addCustomer(
      'harleen',
      'Harleen Quinzel',
      'Cleared three missed months plus default fees in one visit this month.',
      phone: '9845012310',
      address: '19 Amusement Mile, Gotham 575001',
      dob: DateTime(1990, 7, 20),
      cif: '100200310',
      aadhaar: '412398760110',
      pan: 'HQUPQ0123J',
    );
    addRd(
      'harleen',
      11,
      1000,
      _dt(8, 10),
      5,
      nominees: const [
        Nominee(
          name: 'Pamela Isley',
          relationship: NomineeRelationship.sister,
          percentage: 100,
        ),
      ],
    );
    onTime('harleen', 3, 3);
    collect('harleen', _dt(0, 2), 3030);
    deposit('harleen', _dt(0, 3), count: 3, fee: 30);

    // 11. Three to four months in arrears (near 4-default discontinuation threshold).
    addCustomer(
      'harvey',
      'Harvey Dent',
      'Three to four months overdue; follow up urgently before RD discontinuation threshold.',
      phone: '9845012311',
      address: '50 Courthouse Square, Gotham 571401',
      dob: DateTime(1977, 11, 11),
      cif: '100200311',
      aadhaar: '412398760121',
      pan: 'HDEPD1234K',
    );
    addRd(
      'harvey',
      12,
      1500,
      _dt(26, 3),
      22,
      nominees: const [
        Nominee(
          name: 'Gilda Dent',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('harvey', 4, 4);

    // 12. Part-paid + prior arrears: last month overdue, ₹1,000 paid toward ₹2,020 due.
    addCustomer(
      'jason',
      'Jason Todd',
      'Made a partial cash payment toward last month arrears; balance still due.',
      phone: '9845012312',
      address: '88 Crime Alley, Park Row, Gotham 585401',
      dob: DateTime(1994, 8, 16),
      cif: '100200312',
      aadhaar: '412398760132',
      pan: 'JTOPT2345L',
    );
    addRd(
      'jason',
      13,
      2000,
      _dt(15, 10),
      12,
      nominees: const [
        Nominee(
          name: 'Bruce Wayne',
          relationship: NomineeRelationship.father,
          percentage: 100,
        ),
      ],
    );
    onTime('jason', 3, 2);
    collect('jason', _dt(0, 3), 1000);

    // 13. Absorbed fee on an older account: late 3 months ago; agent bore ₹50 fee; settled now.
    addCustomer(
      'constantine',
      'John Constantine',
      'Late transfer three months ago from London; agent absorbed the 50 rupee counter fee.',
      phone: '9845012313',
      address: '13 Mucous Membrane Lane, Gotham 590001',
      dob: DateTime(1976, 5, 10),
      cif: '100200313',
      aadhaar: '412398760143',
      pan: 'JCOPC3456M',
    );
    addRd(
      'constantine',
      14,
      5000,
      _dt(18, 9),
      14,
      nominees: const [
        Nominee(
          name: 'Chas Chandler',
          relationship: NomineeRelationship.brother,
          percentage: 100,
        ),
      ],
    );
    onTime('constantine', 4, 4);
    collect('constantine', _dt(3, 16), 5000, mode: RDPaymentMode.upi);
    deposit('constantine', _dt(3, 18), count: 1, fee: 50);
    absorb(
      'constantine',
      _dt(3, 18),
      50,
      'Late transfer from London; fee absorbed',
    );
    onTime('constantine', 2, 0);

    // -------------------------------------------------------------------------
    // 14–22. Account Lifecycle & Customer Shape Scenarios
    // -------------------------------------------------------------------------

    // 14. Brand new RD opened on the 1st of this month + active 1Y Time Deposit.
    addCustomer(
      'kara',
      'Kara Zor-El',
      'Newly opened RD on the 1st of this month alongside a 1-year Time Deposit.',
      phone: '9845012314',
      address: '14 Midvale Terrace, National City 560001',
      dob: DateTime(1995, 9, 22),
      cif: '100200314',
      aadhaar: '412398760154',
      pan: 'KZOPZ4567N',
    );
    addRd(
      'kara',
      15,
      500,
      _dt(0, 1),
      0,
      nominees: const [
        Nominee(
          name: 'Alex Danvers',
          relationship: NomineeRelationship.sister,
          percentage: 100,
        ),
      ],
    );
    collect('kara', _dt(0, 1), 500);
    deposit('kara', _dt(0, 1));
    addOtd(
      'kara-td1',
      'kara',
      OneTimeSchemeType.timeDeposit,
      9,
      100000,
      6.9,
      1,
      0,
      _dt(4, 10),
      nominees: const [
        Nominee(
          name: 'Alex Danvers',
          relationship: NomineeRelationship.sister,
          percentage: 100,
        ),
      ],
    );

    // 15. Long name (>50 chars) + unpaid this month (due month-end).
    addCustomer(
      'koriandr',
      "Koriand'r of Tamaran, Royal Sovereign of the Vega System",
      'Titans Tower portfolio; prefers month-end reminder for her recurring deposit.',
      phone: '9845012315',
      address: 'Titans Tower, Jump City Bay 560087',
      dob: DateTime(1993, 4, 18),
      cif: '100200315',
      aadhaar: '412398760165',
      pan: 'KTAPK5678O',
    );
    addRd(
      'koriandr',
      16,
      500,
      _dt(6, 18),
      4,
      nominees: const [
        Nominee(
          name: "Komand'r of Tamaran",
          relationship: NomineeRelationship.sister,
          percentage: 100,
        ),
      ],
    );
    onTime('koriandr', 2, 1);

    // 16. Brought into app late: 36 baseline installments + ₹10,000 opening receivable,
    //     plus active MIS and 3Y TD.
    addCustomer(
      'lex',
      'Lex Luthor',
      'Transferred 3-year RD into Postfolio with 10,000 opening receivable plus corporate deposits.',
      phone: '9845012316',
      address: 'LexCorp Tower, 1000 Main Street, Metropolis 560003',
      dob: DateTime(1973, 1, 15),
      cif: '100200316',
      aadhaar: '412398760176',
      pan: 'LLUPL6789P',
    );
    const lenaNominee = [
      Nominee(
        name: 'Lena Luthor',
        relationship: NomineeRelationship.sister,
        percentage: 100,
      ),
    ];
    addRd(
      'lex',
      17,
      10000,
      _dt(36, 20),
      36,
      openingReceivable: 10000,
      nominees: lenaNominee,
    );
    addOtd(
      'lex-mis',
      'lex',
      OneTimeSchemeType.monthlyIncomeScheme,
      10,
      600000,
      7.4,
      5,
      0,
      _dt(55, 5),
      nominees: lenaNominee,
    );
    addOtd(
      'lex-td3',
      'lex',
      OneTimeSchemeType.timeDeposit,
      11,
      300000,
      7.1,
      3,
      0,
      _dt(26, 12),
      nominees: lenaNominee,
    );

    // 17. To collect (due month-end, up to date through last month) + active 5Y NSC.
    addCustomer(
      'lois',
      'Lois Lane',
      'Pays at month-end after Daily Planet column deadline; up to date through last month.',
      phone: '9845012317',
      address: '344 Clinton Street, Apt 3B, Metropolis 585401',
      dob: DateTime(1985, 8, 17),
      cif: '100200317',
      aadhaar: '412398760187',
      pan: 'LLAPL7890Q',
    );
    const clarkNominee = [
      Nominee(
        name: 'Clark Kent',
        relationship: NomineeRelationship.husband,
        percentage: 100,
      ),
    ];
    addRd('lois', 18, 1000, _dt(17, 25), 15, nominees: clarkNominee);
    onTime('lois', 2, 1);
    addOtd(
      'lois-nsc',
      'lois',
      OneTimeSchemeType.nationalSavingsCertificate,
      12,
      125000,
      7.7,
      5,
      0,
      _dt(10, 14),
      nominees: clarkNominee,
    );

    // 18. Maturing soon: RD and 1Y TD, both 20 days from maturity.
    addCustomer(
      'oliver',
      'Oliver Queen',
      'Both RD and 1-year Time Deposit mature in 20 days; prepare renewal forms.',
      phone: '9845012318',
      address: 'Queen Consolidated Plaza, Star City 581301',
      dob: DateTime(1979, 5, 16),
      cif: '100200318',
      aadhaar: '412398760198',
      pan: 'OQUPO8901R',
    );
    final in20Days = _addDays(20);
    const dinahNominee = [
      Nominee(
        name: 'Dinah Lance',
        relationship: NomineeRelationship.wife,
        percentage: 100,
      ),
    ];
    addRd(
      'oliver',
      19,
      1000,
      _subtractMonths(in20Days, 60),
      60,
      rate: 5.8,
      nominees: dinahNominee,
    );
    addOtd(
      'oliver-td1',
      'oliver',
      OneTimeSchemeType.timeDeposit,
      13,
      50000,
      6.9,
      1,
      0,
      _subtractMonths(in20Days, 12),
      nominees: dinahNominee,
    );

    // 19. Matured, still open: RD and NSC, both 40 days past maturity.
    addCustomer(
      'oswald',
      'Oswald Cobblepot',
      'Matured RD and NSC still open past maturity; pending payout instructions from Iceberg Lounge.',
      phone: '9845012319',
      address: 'The Iceberg Lounge, Pier 14, Gotham 575002',
      dob: DateTime(1961, 12, 30),
      cif: '100200319',
      aadhaar: '412398760209',
      pan: 'OCOPC9012S',
    );
    final ago40Days = _addDays(-40);
    const estherNominee = [
      Nominee(
        name: 'Esther Cobblepot',
        relationship: NomineeRelationship.mother,
        percentage: 100,
      ),
    ];
    addRd(
      'oswald',
      20,
      2000,
      _subtractMonths(ago40Days, 60),
      60,
      rate: 5.8,
      nominees: estherNominee,
    );
    addOtd(
      'oswald-nsc',
      'oswald',
      OneTimeSchemeType.nationalSavingsCertificate,
      14,
      25000,
      6.8,
      5,
      0,
      _subtractMonths(ago40Days, 60),
      nominees: estherNominee,
    );

    // 20. Closed: RD, 2Y TD, and 5Y MIS all closed.
    addCustomer(
      'pamela',
      'Pamela Isley',
      'Closed her matured RD, 2-year TD, and 5-year MIS after relocating to Robinson Park Conservatory.',
      phone: '9845012320',
      address: 'Greenhouse 4, Robinson Park, Gotham 560010',
      dob: DateTime(1980, 5, 22),
      cif: '100200320',
      aadhaar: '412398760220',
      pan: 'PISPI0123T',
    );
    const harleenNominee = [
      Nominee(
        name: 'Harleen Quinzel',
        relationship: NomineeRelationship.sister,
        percentage: 100,
      ),
    ];
    addRd(
      'pamela',
      21,
      3000,
      _dt(66, 10),
      60,
      status: DepositStatus.closed,
      rate: 5.8,
      nominees: harleenNominee,
    );
    addOtd(
      'pamela-td2',
      'pamela',
      OneTimeSchemeType.timeDeposit,
      15,
      100000,
      7.0,
      2,
      0,
      _dt(27, 14),
      status: DepositStatus.closed,
      nominees: harleenNominee,
    );
    addOtd(
      'pamela-mis',
      'pamela',
      OneTimeSchemeType.monthlyIncomeScheme,
      16,
      300000,
      6.6,
      5,
      0,
      _dt(64, 8),
      status: DepositStatus.closed,
      nominees: harleenNominee,
    );

    // 21. Name only: every optional KYC field empty; one ₹1,000 KVP with no nominee.
    addCustomer(
      'selina',
      'Selina Kyle',
      'Minimal profile — prefers privacy; small KVP with no nominee listed.',
    );
    addOtd(
      'selina-kvp',
      'selina',
      OneTimeSchemeType.kisanVikasPatra,
      17,
      1000,
      7.5,
      9,
      7,
      _dt(102, 5),
    );

    // 22. No account at all: empty sections, and deleting is allowed.
    addCustomer(
      'victor',
      'Victor Stone',
      'Newly onboarded at S.T.A.R. Labs; no deposits linked yet.',
      phone: '9845012322',
      address: 'S.T.A.R. Labs Campus, Metropolis 560025',
      dob: DateTime(1997, 6, 29),
    );

    customers = List.unmodifiable(customerList);
    oneTimeDeposits = List.unmodifiable(otdList);
    recurringDeposits = List.unmodifiable(rdList);
    rdTransactions = Map<String, List<RDTransaction>>.unmodifiable({
      for (final e in txByRdId.entries)
        e.key: List<RDTransaction>.unmodifiable(e.value),
    });
    rdPoDeposits = Map<String, List<RDPoDeposit>>.unmodifiable({
      for (final e in poByRdId.entries)
        e.key: List<RDPoDeposit>.unmodifiable(e.value),
    });
    rdFeeAbsorptions = Map<String, List<RDFeeAbsorption>>.unmodifiable({
      for (final e in absByRdId.entries)
        e.key: List<RDFeeAbsorption>.unmodifiable(e.value),
    });
  }
}
