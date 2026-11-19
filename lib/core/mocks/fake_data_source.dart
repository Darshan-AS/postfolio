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
/// Mirrors `supabase/seed.sql` 1-to-1: 21 customers (one situation each, A–U plus Kannada),
/// 20 recurring deposits, 11 one-time deposits, 1 savings account, 36 nominees, and causally
/// ordered RD ledger facts (payments, PO visits, and a fee absorption).
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

  /// Builds the full 21-customer portfolio with every date computed relative to [today].
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
    // 1–11. Monthly Hub: what this month looks like
    // -------------------------------------------------------------------------

    // 1. Settled: paid on time and deposited every month, this month included.
    addCustomer(
      'asha',
      'Asha Kulkarni',
      'Seed 1. Recurring deposit paid on time and deposited every month, this month too. Monthly Hub: Settled.',
      phone: '9845012301',
      address: '14, Car Street, Sirsi 581401',
      dob: DateTime(1978, 3, 12),
      cif: '100200301',
      aadhaar: '412398760011',
      pan: 'AKUPK1234A',
      email: 'asha.kulkarni@example.com',
    );
    addRd(
      'asha',
      1,
      2000,
      _dt(14, 10),
      11,
      nominees: const [
        Nominee(
          name: 'Vinod Kulkarni',
          relationship: NomineeRelationship.husband,
          percentage: 100,
        ),
      ],
    );
    onTime('asha', 3, 0);

    // 2. In hand, cash: collected this month, not yet deposited.
    addCustomer(
      'bharat',
      'Bharat Shetty',
      'Seed 2. This month collected in cash, not yet deposited. Monthly Hub: In hand, with a Deposit button.',
      phone: '9845012302',
      address: '7, Bunder Road, Kundapura 576201',
      dob: DateTime(1969, 11, 2),
      cif: '100200302',
      aadhaar: '412398760022',
      pan: 'BSHPS2345B',
    );
    addRd(
      'bharat',
      2,
      5000,
      _dt(9, 5),
      7,
      nominees: const [
        Nominee(
          name: 'Sharada Shetty',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('bharat', 2, 1);
    collect('bharat', _dt(0, 3), 5000);

    // 3. In hand, UPI: collected this month by UPI, not yet deposited.
    addCustomer(
      'chitra',
      'Chitra Nair',
      'Seed 3. This month collected by UPI, not yet deposited. Post Office visit sheet: UPI total.',
      phone: '9845012303',
      address: '22, Temple Road, Udupi 576101',
      dob: DateTime(1985, 7, 19),
      cif: '100200303',
      aadhaar: '412398760033',
      pan: 'CNAPN3456C',
    );
    addRd(
      'chitra',
      3,
      3000,
      _dt(22, 12),
      20,
      nominees: const [
        Nominee(
          name: 'Gopalan Nair',
          relationship: NomineeRelationship.father,
          percentage: 100,
        ),
      ],
    );
    onTime('chitra', 2, 1, mode: RDPaymentMode.upi);
    collect('chitra', _dt(0, 4), 3000, mode: RDPaymentMode.upi);

    // 4. In hand, large cash: with customer 2 the cash passes ₹20,000 (two cash lots).
    addCustomer(
      'dinesh',
      'Dinesh Agarwal',
      'Seed 4. 18,000 rupees collected in cash this month. With Bharat Shetty the cash in hand passes 20,000, so the visit sheet shows two cash lots.',
      phone: '9845012304',
      address: '3, Market Road, Hubballi 580020',
      dob: DateTime(1972, 1, 25),
      cif: '100200304',
      aadhaar: '412398760044',
      pan: 'DAGPA4567D',
    );
    addRd(
      'dinesh',
      4,
      18000,
      _dt(5, 8),
      3,
      nominees: const [
        Nominee(
          name: 'Rekha Agarwal',
          relationship: NomineeRelationship.wife,
          percentage: 60,
        ),
        Nominee(
          name: 'Mohit Agarwal',
          relationship: NomineeRelationship.son,
          percentage: 40,
        ),
      ],
    );
    onTime('dinesh', 2, 1);
    collect('dinesh', _dt(0, 2), 18000);

    // 5. Part paid: ₹2,500 of ₹4,000 received this month; due at month end.
    addCustomer(
      'esha',
      'Esha Fernandes',
      "Seed 5. 2,500 of this month's 4,000 rupees received. Monthly Hub: part paid, 1,500 still owed.",
      phone: '9845012305',
      address: '9, Church Lane, Mangaluru 575001',
      dob: DateTime(1990, 5, 30),
      cif: '100200305',
      aadhaar: '412398760055',
      pan: 'EFEPF5678E',
    );
    addRd(
      'esha',
      5,
      4000,
      _dt(30, 20),
      28,
      nominees: const [
        Nominee(
          name: 'Maria Fernandes',
          relationship: NomineeRelationship.mother,
          percentage: 100,
        ),
      ],
    );
    onTime('esha', 2, 1);
    collect('esha', _dt(0, 2), 2500);

    // 6. To collect: up to date through last month, nothing yet this month.
    addCustomer(
      'farhan',
      'Farhan Qureshi',
      'Seed 6. Up to date through last month, nothing paid this month. Due at month end: upcoming, then due today on the last day.',
      phone: '9845012306',
      address: '41, Fort Road, Bidar 585401',
      dob: DateTime(1981, 9, 8),
      cif: '100200306',
      aadhaar: '412398760066',
      pan: 'FQUPQ6789F',
    );
    addRd(
      'farhan',
      6,
      1000,
      _dt(17, 25),
      15,
      nominees: const [
        Nominee(
          name: 'Ayesha Qureshi',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('farhan', 2, 1);

    // 7. One month in arrears: last month unpaid with default fee.
    addCustomer(
      'gauri',
      'Gauri Deshpande',
      'Seed 7. Last month unpaid. The Monthly Hub row carries one month of arrears and its default fee; this month goes overdue after the 15th.',
      phone: '9845012307',
      address: '18, Station Road, Dharwad 580001',
      dob: DateTime(1976, 12, 14),
      cif: '100200307',
      aadhaar: '412398760077',
      pan: 'GDEPD7890G',
    );
    addRd(
      'gauri',
      7,
      2500,
      _dt(11, 7),
      8,
      nominees: const [
        Nominee(
          name: 'Sameer Deshpande',
          relationship: NomineeRelationship.son,
          percentage: 100,
        ),
      ],
    );
    onTime('gauri', 3, 2);

    // 8. Three months in arrears: nothing paid or deposited for three months.
    addCustomer(
      'harish',
      'Harish Gowda',
      'Seed 8. Nothing paid or deposited for three months. Monthly Hub: Arrears tile and the Overdue filter.',
      phone: '9845012308',
      address: '5, Sugar Factory Road, Mandya 571401',
      dob: DateTime(1965, 4, 3),
      cif: '100200308',
      aadhaar: '412398760088',
      pan: 'HGOPG8901H',
    );
    addRd(
      'harish',
      8,
      1500,
      _dt(26, 3),
      22,
      nominees: const [
        Nominee(
          name: 'Lakshmi Gowda',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('harish', 4, 4);

    // 9. Fronted: deposited from agent's pocket; customer has not paid.
    addCustomer(
      'indira',
      'Indira Menon',
      "Seed 9. This month deposited from the agent's pocket; the customer has not paid. Monthly Hub: Fronted filter and the Receivable tile.",
      phone: '9845012309',
      address: '12, Lake View Road, Shivamogga 577201',
      dob: DateTime(1958, 8, 21),
      cif: '100200309',
      aadhaar: '412398760099',
      pan: 'IMEPM9012I',
    );
    addRd(
      'indira',
      9,
      2000,
      _dt(40, 14),
      38,
      nominees: const [
        Nominee(
          name: 'Suresh Menon',
          relationship: NomineeRelationship.son,
          percentage: 50,
        ),
        Nominee(
          name: 'Latha Menon',
          relationship: NomineeRelationship.daughter,
          percentage: 50,
        ),
      ],
    );
    onTime('indira', 2, 1);
    deposit('indira', _dt(0, 2));

    // 10. Caught up: two months missed, then three installments + ₹30 fees paid & deposited.
    addCustomer(
      'jayant',
      'Jayant Bhat',
      'Seed 10. Missed two months, then paid three installments and 30 rupees of default fees at once this month. One Post Office visit deposited all three.',
      phone: '9845012310',
      address: '27, Hampankatta, Mangaluru 575001',
      dob: DateTime(1983, 2, 17),
      cif: '100200310',
      aadhaar: '412398760110',
      pan: 'JBHPB0123J',
    );
    addRd(
      'jayant',
      10,
      1000,
      _dt(8, 10),
      5,
      nominees: const [
        Nominee(
          name: 'Vidya Bhat',
          relationship: NomineeRelationship.wife,
          percentage: 100,
        ),
      ],
    );
    onTime('jayant', 3, 3);
    collect('jayant', _dt(0, 2), 3030);
    deposit('jayant', _dt(0, 3), count: 3, fee: 30);

    // 11. Fee absorbed by the agent: paid a day late 3 months ago; agent bore ₹50 fee.
    addCustomer(
      'kavita',
      'Kavita Joshi',
      'Seed 11. Paid one day late three months ago; the Post Office charged a 50 rupee default fee and the agent bore it. Settled now.',
      phone: '9845012311',
      address: '8, College Road, Belagavi 590001',
      dob: DateTime(1987, 10, 9),
      cif: '100200311',
      aadhaar: '412398760121',
      pan: 'KJOPJ1234K',
    );
    addRd(
      'kavita',
      11,
      5000,
      _dt(18, 9),
      14,
      nominees: const [
        Nominee(
          name: 'Anand Joshi',
          relationship: NomineeRelationship.husband,
          percentage: 100,
        ),
      ],
    );
    onTime('kavita', 4, 4);
    collect('kavita', _dt(3, 16), 5000, mode: RDPaymentMode.upi);
    deposit('kavita', _dt(3, 18), count: 1, fee: 50);
    absorb('kavita', _dt(3, 18), 50, 'Customer was travelling; one day late');
    onTime('kavita', 2, 0);

    // -------------------------------------------------------------------------
    // 12–16. Account lifecycle
    // -------------------------------------------------------------------------

    // 12. Brand new: opened on the 1st of this month, first installment paid & deposited.
    addCustomer(
      'lalit',
      'Lalit Saxena',
      'Seed 12. Recurring deposit opened on the 1st of this month, first installment paid. No history yet.',
      phone: '9845012312',
      address: '33, MG Road, Bengaluru 560001',
      dob: DateTime(1995, 6, 27),
      cif: '100200312',
      aadhaar: '412398760132',
      pan: 'LSAPS2345L',
    );
    addRd(
      'lalit',
      12,
      500,
      _dt(0, 1),
      0,
      nominees: const [
        Nominee(
          name: 'Neha Saxena',
          relationship: NomineeRelationship.sister,
          percentage: 100,
        ),
      ],
    );
    collect('lalit', _dt(0, 1), 500);
    deposit('lalit', _dt(0, 1));

    // 13. Brought into the app late: 36 installments already paid, ₹10,000 opening receivable.
    addCustomer(
      'meera',
      'Meera Iyer',
      'Seed 13. Three-year-old account entered with 36 installments already paid and an opening receivable of 10,000 rupees.',
      phone: '9845012313',
      address: '6, Sampige Road, Bengaluru 560003',
      dob: DateTime(1971, 1, 15),
      cif: '100200313',
      aadhaar: '412398760143',
      pan: 'MIYPI3456M',
    );
    addRd(
      'meera',
      13,
      10000,
      _dt(36, 20),
      36,
      openingReceivable: 10000,
      nominees: const [
        Nominee(
          name: 'Krishnan Iyer',
          relationship: NomineeRelationship.husband,
          percentage: 100,
        ),
      ],
    );

    // 14. Maturing soon: RD and 1Y TD, both 20 days from maturity.
    addCustomer(
      'naveen',
      'Naveen Pillai',
      'Seed 14. A recurring deposit and a one-year Time Deposit that both mature in 20 days: "maturing soon".',
      phone: '9845012314',
      address: '19, Beach Road, Karwar 581301',
      dob: DateTime(1962, 7, 4),
      cif: '100200314',
      aadhaar: '412398760154',
      pan: 'NPIPP4567N',
    );
    final in20Days = _addDays(20);
    const deepaNominee = [
      Nominee(
        name: 'Deepa Pillai',
        relationship: NomineeRelationship.daughter,
        percentage: 100,
      ),
    ];
    addRd(
      'naveen',
      14,
      1000,
      _subtractMonths(in20Days, 60),
      60,
      rate: 5.8,
      nominees: deepaNominee,
    );
    addOtd(
      'naveen-td',
      'naveen',
      OneTimeSchemeType.timeDeposit,
      1,
      50000,
      6.9,
      1,
      0,
      _subtractMonths(in20Days, 12),
      nominees: deepaNominee,
    );

    // 15. Matured, still open: RD and NSC, both 40 days past maturity.
    addCustomer(
      'omana',
      'Omana Kurup',
      'Seed 15. A recurring deposit and a National Savings Certificate, both 40 days past maturity and still open: "matured".',
      phone: '9845012315',
      address: '2, Kadri Hills, Mangaluru 575002',
      dob: DateTime(1955, 12, 30),
      cif: '100200315',
      aadhaar: '412398760165',
      pan: 'OKUPK5678O',
    );
    final ago40Days = _addDays(-40);
    const rajanNominee = [
      Nominee(
        name: 'Rajan Kurup',
        relationship: NomineeRelationship.son,
        percentage: 100,
      ),
    ];
    addRd(
      'omana',
      15,
      2000,
      _subtractMonths(ago40Days, 60),
      60,
      rate: 5.8,
      nominees: rajanNominee,
    );
    addOtd(
      'omana-nsc',
      'omana',
      OneTimeSchemeType.nationalSavingsCertificate,
      2,
      25000,
      6.8,
      5,
      0,
      _subtractMonths(ago40Days, 60),
      nominees: rajanNominee,
    );

    // 16. Closed: RD and 2Y TD, both closed.
    addCustomer(
      'prakash',
      'Prakash Rao',
      'Seed 16. A recurring deposit and a two-year Time Deposit, both closed. Lists show the Closed badge; the Monthly Hub leaves the account out.',
      phone: '9845012316',
      address: '11, Rajajinagar 2nd Block, Bengaluru 560010',
      dob: DateTime(1968, 5, 22),
      cif: '100200316',
      aadhaar: '412398760176',
      pan: 'PRAPR6789P',
    );
    const sudhaNominee = [
      Nominee(
        name: 'Sudha Rao',
        relationship: NomineeRelationship.wife,
        percentage: 100,
      ),
    ];
    addRd(
      'prakash',
      16,
      3000,
      _dt(66, 10),
      60,
      status: DepositStatus.closed,
      rate: 5.8,
      nominees: sudhaNominee,
    );
    addOtd(
      'prakash-td',
      'prakash',
      OneTimeSchemeType.timeDeposit,
      3,
      100000,
      7.0,
      2,
      0,
      _dt(27, 14),
      status: DepositStatus.closed,
      nominees: sudhaNominee,
    );

    // -------------------------------------------------------------------------
    // 17–21. Customer shape
    // -------------------------------------------------------------------------

    // 17. Household with many accounts: 2 RDs, every OTD scheme, SB with 3 nominees.
    addCustomer(
      'ramesh',
      'Ramesh Hegde',
      'Seed 17. Many accounts: two recurring deposits, Time Deposits of 1, 2, 3 and 5 years, a Monthly Income Scheme at the 9,00,000 limit, a National Savings Certificate, a Kisan Vikas Patra and a savings account with three nominees. Opened across four financial years.',
      phone: '9845012317',
      address: '45, Yellapur Road, Sirsi 581402',
      dob: DateTime(1960, 2, 11),
      cif: '100200317',
      aadhaar: '412398760187',
      pan: 'RHEPH7890R',
      email: 'ramesh.hegde@example.com',
      savingsAccount: const SavingsAccount(
        accountNumber: '0100030017',
        nominees: [
          Nominee(
            name: 'Shanta Hegde',
            relationship: NomineeRelationship.wife,
            percentage: 33.34,
          ),
          Nominee(
            name: 'Arun Hegde',
            relationship: NomineeRelationship.son,
            percentage: 33.33,
          ),
          Nominee(
            name: 'Anita Hegde',
            relationship: NomineeRelationship.daughter,
            percentage: 33.33,
          ),
        ],
      ),
    );
    const shantaNominee = [
      Nominee(
        name: 'Shanta Hegde',
        relationship: NomineeRelationship.wife,
        percentage: 100,
      ),
    ];
    const arunNominee = [
      Nominee(
        name: 'Arun Hegde',
        relationship: NomineeRelationship.son,
        percentage: 100,
      ),
    ];
    const anitaNominee = [
      Nominee(
        name: 'Anita Hegde',
        relationship: NomineeRelationship.daughter,
        percentage: 100,
      ),
    ];
    addRd(
      'ramesh-a',
      17,
      5000,
      _dt(20, 10),
      18,
      customerKey: 'ramesh',
      nominees: shantaNominee,
    );
    onTime('ramesh-a', 2, 0);
    addRd(
      'ramesh-b',
      18,
      1500,
      _dt(7, 22),
      5,
      customerKey: 'ramesh',
      nominees: arunNominee,
    );
    onTime('ramesh-b', 2, 1);
    addOtd(
      'ramesh-td1',
      'ramesh',
      OneTimeSchemeType.timeDeposit,
      4,
      200000,
      6.9,
      1,
      0,
      _dt(2, 12),
      nominees: shantaNominee,
    );
    addOtd(
      'ramesh-td2',
      'ramesh',
      OneTimeSchemeType.timeDeposit,
      5,
      150000,
      7.0,
      2,
      0,
      _dt(14, 12),
      nominees: shantaNominee,
    );
    addOtd(
      'ramesh-td3',
      'ramesh',
      OneTimeSchemeType.timeDeposit,
      6,
      300000,
      7.1,
      3,
      0,
      _dt(26, 12),
      nominees: arunNominee,
    );
    addOtd(
      'ramesh-td5',
      'ramesh',
      OneTimeSchemeType.timeDeposit,
      7,
      500000,
      7.5,
      5,
      0,
      _dt(38, 12),
      nominees: anitaNominee,
    );
    addOtd(
      'ramesh-mis',
      'ramesh',
      OneTimeSchemeType.monthlyIncomeScheme,
      8,
      900000,
      7.4,
      5,
      0,
      _dt(30, 6),
      nominees: shantaNominee,
    );
    addOtd(
      'ramesh-nsc',
      'ramesh',
      OneTimeSchemeType.nationalSavingsCertificate,
      9,
      100000,
      7.7,
      5,
      0,
      _dt(18, 21),
      nominees: const [
        Nominee(
          name: 'Arun Hegde',
          relationship: NomineeRelationship.son,
          percentage: 50,
        ),
        Nominee(
          name: 'Anita Hegde',
          relationship: NomineeRelationship.daughter,
          percentage: 50,
        ),
      ],
    );
    addOtd(
      'ramesh-kvp',
      'ramesh',
      OneTimeSchemeType.kisanVikasPatra,
      10,
      50000,
      7.5,
      9,
      7,
      _dt(8, 3),
      nominees: shantaNominee,
    );

    // 18. Name only: every other field empty; one ₹1,000 TD with no nominee.
    addCustomer(
      'sunita',
      'Sunita Thomas',
      'Seed 18. Only a name is known: every other field is empty. One Time Deposit of 1,000 rupees with no nominee.',
    );
    addOtd(
      'sunita-td',
      'sunita',
      OneTimeSchemeType.timeDeposit,
      11,
      1000,
      6.9,
      1,
      0,
      _dt(2, 12),
    );

    // 19. Long name (>50 chars): not yet paid this month, so it sits beside Collect on Hub.
    addCustomer(
      'tejaswini',
      'Tejaswini Venkata Subrahmanya Lakshminarasimha Chintalapati',
      'Seed 19. A name too long for one line, at 360dp and at large text. Not yet paid this month, so the Monthly Hub shows it beside a Collect button.',
      phone: '9845012319',
      address:
          'Flat 1204, Tower C, Prestige Lakeside Habitat, Whitefield-Sarjapur Road, Varthur, Bengaluru 560087',
      dob: DateTime(1992, 11, 18),
      cif: '100200319',
      aadhaar: '412398760209',
      pan: 'TCHPC9012T',
    );
    addRd(
      'tejaswini',
      19,
      500,
      _dt(6, 18),
      4,
      nominees: const [
        Nominee(
          name: 'Venkata Ramana Chintalapati',
          relationship: NomineeRelationship.father,
          percentage: 100,
        ),
      ],
    );
    onTime('tejaswini', 2, 1);

    // 20. No account at all: empty sections, and deleting is allowed.
    addCustomer(
      'uma',
      'Uma Bose',
      'Seed 20. A customer with no account: empty sections on the detail screen, and deleting is allowed.',
      phone: '9845012320',
      address: '16, Residency Road, Bengaluru 560025',
      dob: DateTime(1999, 9, 9),
    );

    // 21. Kannada script: fonts, avatar initial, sorting, search; RD settled this month.
    addCustomer(
      'vijayalakshmi',
      'ವಿಜಯಲಕ್ಷ್ಮಿ ಗೌಡ',
      'Seed 21. A name written in Kannada (Vijayalakshmi Gowda): fonts, the avatar initial, sorting and search on non-Latin text. Recurring deposit settled this month.',
      phone: '9845012321',
      address: '30, ರಥಬೀದಿ, ಮೈಸೂರು 570001',
      dob: DateTime(1980, 4, 14),
      cif: '100200321',
      aadhaar: '412398760221',
      pan: 'VGOPG1234V',
    );
    addRd(
      'vijayalakshmi',
      20,
      1000,
      _dt(10, 6),
      8,
      nominees: const [
        Nominee(
          name: 'ಮಂಜುನಾಥ ಗೌಡ',
          relationship: NomineeRelationship.husband,
          percentage: 100,
        ),
      ],
    );
    onTime('vijayalakshmi', 2, 0, mode: RDPaymentMode.upi);

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
