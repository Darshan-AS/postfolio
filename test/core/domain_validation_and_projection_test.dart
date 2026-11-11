import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/payout_frequency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';

void main() {
  group('Customer & SavingsAccount domain invariants', () {
    test('table: Customer.create enforces identity, KYC, and SB-nominee coupling', () {
      const validNominee = Nominee(
        name: 'Meera Mehta',
        relationship: NomineeRelationship.wife,
        percentage: 100,
      );

      final cases = <({
        String label,
        String name,
        String? email,
        String? phone,
        String? aadhaar,
        String? pan,
        String? cif,
        String? sbAccount,
        List<Nominee>? sbNominees,
        bool expectSuccess,
      })>[
        (
          label: 'minimal valid customer trims whitespace-only optional fields to null',
          name: '  Arjun Mehta  ',
          email: '   ',
          phone: '',
          aadhaar: null,
          pan: '  ',
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: true,
        ),
        (
          label: 'full valid KYC + SB account + 100% nominee succeeds',
          name: 'Deepika Sharma',
          email: 'deepika@example.com',
          phone: '+919876543210',
          aadhaar: '1234 5678 9012',
          pan: 'abcde1234f',
          cif: 'CIF100567',
          sbAccount: ' 0100200300 ',
          sbNominees: [validNominee],
          expectSuccess: true,
        ),
        (
          label: 'blank or 1-char name fails',
          name: 'A',
          email: null,
          phone: null,
          aadhaar: null,
          pan: null,
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'malformed email fails',
          name: 'Rohan Varma',
          email: 'not-an-email',
          phone: null,
          aadhaar: null,
          pan: null,
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'too-short phone fails',
          name: 'Rohan Varma',
          email: null,
          phone: '12345',
          aadhaar: null,
          pan: null,
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'non-12-digit Aadhaar fails',
          name: 'Rohan Varma',
          email: null,
          phone: null,
          aadhaar: '1234 5678 901',
          pan: null,
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'malformed PAN fails',
          name: 'Rohan Varma',
          email: null,
          phone: null,
          aadhaar: null,
          pan: 'ABCD12345F',
          cif: null,
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'too-short CIF fails',
          name: 'Rohan Varma',
          email: null,
          phone: null,
          aadhaar: null,
          pan: null,
          cif: '12',
          sbAccount: null,
          sbNominees: null,
          expectSuccess: false,
        ),
        (
          label: 'SB nominees without an SB account number fail',
          name: 'Rohan Varma',
          email: null,
          phone: null,
          aadhaar: null,
          pan: null,
          cif: null,
          sbAccount: '   ',
          sbNominees: [validNominee],
          expectSuccess: false,
        ),
      ];

      for (final c in cases) {
        final res = Customer.create(
          id: 'cust-1',
          name: c.name,
          email: c.email,
          phone: c.phone,
          aadhaarNumber: c.aadhaar,
          panNumber: c.pan,
          cifNumber: c.cif,
          savingsAccountNumber: c.sbAccount,
          savingsNominees: c.sbNominees,
        );
        expect(res is Success<Customer, String>, c.expectSuccess, reason: c.label);
      }

      final trimmed = (Customer.create(id: 'c1', name: '  Arjun  ', email: '  ')
              as Success<Customer, String>)
          .value;
      expect(trimmed.name, 'Arjun');
      expect(trimmed.email, isNull);
    });
  });

  group('Nominee domain invariants', () {
    test('table: Nominee.create and validateNominees enforce share & relationship rules', () {
      expect(Nominee.validateNominees(const []), isNull, reason: 'empty nominee list is valid');

      final otherMissingCustom = Nominee.create(
        name: 'Karan',
        relationship: NomineeRelationship.other,
        customRelationship: '   ',
        percentage: 100,
      );
      expect(otherMissingCustom, isA<Failure<Nominee, String>>());

      final otherValid = (Nominee.create(
        name: '  Karan  ',
        relationship: NomineeRelationship.other,
        customRelationship: '  Family Friend  ',
        percentage: 60,
      ) as Success<Nominee, String>)
          .value;
      expect(otherValid.name, 'Karan');
      expect(otherValid.displayRelationship, 'Family Friend');

      final standardDropsCustom = (Nominee.create(
        name: 'Sujata',
        relationship: NomineeRelationship.sister,
        customRelationship: 'Ignored',
        percentage: 40,
      ) as Success<Nominee, String>)
          .value;
      expect(standardDropsCustom.customRelationship, isNull);
      expect(Nominee.validateNominees([otherValid, standardDropsCustom]), isNull);
      expect(Nominee.validateNominees([otherValid]), isNotNull, reason: '60% != 100%');
      expect(
        Nominee.create(name: 'Zero', relationship: NomineeRelationship.son, percentage: 0),
        isA<Failure<Nominee, String>>(),
      );
    });
  });

  group('OneTimeDeposit & BaseDeposit invariants', () {
    test('table: OneTimeDeposit.create validates allowed tenures, bounds, and urgency', () {
      final start = DateTime(2025, 4, 1);
      final cases = <({
        String label,
        OneTimeSchemeType scheme,
        double principal,
        int? years,
        int? months,
        double? rate,
        bool expectSuccess,
      })>[
        (
          label: 'TD 1Y valid',
          scheme: OneTimeSchemeType.timeDeposit,
          principal: 100000,
          years: 1,
          months: 0,
          rate: null,
          expectSuccess: true,
        ),
        (
          label: 'TD 4Y invalid (Post Office allows 1/2/3/5Y only)',
          scheme: OneTimeSchemeType.timeDeposit,
          principal: 100000,
          years: 4,
          months: 0,
          rate: null,
          expectSuccess: false,
        ),
        (
          label: 'MIS with non-zero months rejected',
          scheme: OneTimeSchemeType.monthlyIncomeScheme,
          principal: 100000,
          years: 5,
          months: 3,
          rate: null,
          expectSuccess: false,
        ),
        (
          label: 'non-positive principal rejected',
          scheme: OneTimeSchemeType.nationalSavingsCertificate,
          principal: 0,
          years: 5,
          months: 0,
          rate: null,
          expectSuccess: false,
        ),
        (
          label: 'absurd interest rate (>100%) rejected',
          scheme: OneTimeSchemeType.nationalSavingsCertificate,
          principal: 50000,
          years: 5,
          months: 0,
          rate: 101,
          expectSuccess: false,
        ),
      ];

      for (final c in cases) {
        final res = OneTimeDeposit.create(
          id: 'otd-1',
          principalAmount: c.principal,
          customerId: 'cust-1',
          schemeType: c.scheme,
          startDate: start,
          termYears: c.years,
          termMonths: c.months,
          interestRate: c.rate,
        );
        expect(res is Success<OneTimeDeposit, String>, c.expectSuccess, reason: c.label);
      }

      final td5 = (OneTimeDeposit.create(
        id: 'td5',
        principalAmount: 100000,
        customerId: 'cust-1',
        schemeType: OneTimeSchemeType.timeDeposit,
        startDate: DateTime(2020, 1, 1),
        termYears: 5,
      ) as Success<OneTimeDeposit, String>)
          .value;
      expect(td5.schemeTermLabel, '5Y');
      expect(td5.maturityUrgency, MaturityUrgency.matured);
      expect(td5.copyWith(status: DepositStatus.closed).maturityUrgency, MaturityUrgency.closed);
    });
  });

  group('ProjectionCalculator & Indian Financial Year math', () {
    test('TD, MIS, NSC, and RD formulas match Post Office compounding & default extension rules', () {
      final start = DateTime(2025, 4, 1);

      // 1. TD (₹1,00,000 @ 7.5% for 5Y): quarterly compounding paid annually, principal returned.
      final td = ProjectionCalculator.calculateTD(
        principal: 100000,
        startDate: start,
        termYears: 5,
        interestRate: 7.5,
      );
      final expectedAnnualTd = 100000 * (pow(1 + 0.075 / 4, 4) - 1);
      expect(td, isA<IncomeGeneration>());
      final tdIncome = td as IncomeGeneration;
      expect(tdIncome.payoutFrequency, PayoutFrequency.annually);
      expect(tdIncome.periodicPayoutAmount, closeTo(expectedAnnualTd, 0.01));
      expect(tdIncome.maturityAmount, 100000);
      expect(tdIncome.totalInterestEarned, closeTo(expectedAnnualTd * 5, 0.01));

      // 2. MIS (₹4,50,000 @ 7.4% for 5Y): monthly simple interest = 450000 * 0.074 / 12 = ₹2,775/mo.
      final mis = ProjectionCalculator.calculateMIS(
        principal: 450000,
        startDate: start,
        interestRate: 7.4,
        termYears: 5,
      ) as IncomeGeneration;
      expect(mis.payoutFrequency, PayoutFrequency.monthly);
      expect(mis.periodicPayoutAmount, closeTo(2775.0, 0.001));
      expect(mis.totalInterestEarned, closeTo(2775.0 * 60, 0.01));
      expect(mis.maturityAmount, 450000);

      // 3. NSC (₹1,00,000 @ 7.7% for 5Y): annual compounding = 100000 * (1.077)^5 ≈ ₹1,44,903.37.
      final nsc = ProjectionCalculator.calculateNSC(
        principal: 100000,
        startDate: start,
        interestRate: 7.7,
        termYears: 5,
      ) as WealthAccumulation;
      expect(nsc.maturityAmount, closeTo(100000 * pow(1.077, 5), 0.01));
      expect(nsc.maturityDate, DateTime(2030, 4, 1));

      // 4. RD (₹5,000/mo @ 6.7% for 5Y, with 2 defaulted months extending maturity date).
      final rd = ProjectionCalculator.calculateRD(
        monthlyInstallment: 5000,
        startDate: start,
        interestRate: 6.7,
        termYears: 5,
        termMonths: 0,
        defaultedMonths: 2,
      ) as WealthAccumulation;
      expect(rd.totalInvested, 300000);
      expect(rd.maturityAmount, greaterThan(350000));
      expect(rd.maturityDate, DateTime(2030, 6, 1), reason: '60 months + 2 defaulted months');
    });

    test('Indian Financial Year boundary splits March 31 vs April 1', () {
      expect(DateTime(2025, 3, 31).financialYearStart, 2024);
      expect(DateTime(2025, 3, 31).financialYearLabel, 'FY 24-25');
      expect(DateTime(2025, 4, 1).financialYearStart, 2025);
      expect(DateTime(2025, 4, 1).financialYearLabel, 'FY 25-26');
    });
  });
}
