import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:postfolio/core/utils/money.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

void main() {
  group('Paise, BasisPoints & Rupee formatting invariants', () {
    test('Paise & BasisPoints eliminate IEEE-754 drift', () {
      expect(
        Paise.fromRupees(0.1) + Paise.fromRupees(0.2),
        const Paise(30),
      );
      expect((Paise.fromRupees(0.1) + Paise.fromRupees(0.2)).toRupees(), 0.30);

      final shareSum = BasisPoints.fromPercent(16.1) +
          BasisPoints.fromPercent(48.2) +
          BasisPoints.fromPercent(35.7);
      expect(shareSum, BasisPoints.hundredPercent);
    });

    test('table: toRupeeFormat keeps whole rupees compact and preserves sub-rupee paise', () {
      final cases = <({double input, String expected})>[
        (input: 0.0, expected: '₹0'),
        (input: 5000.0, expected: '₹5,000'),
        (input: 100000.0, expected: '₹1,00,000'),
        (input: 2.50, expected: '₹2.50'),
        (input: 616.6666, expected: '₹616.67'),
        (input: 125.05, expected: '₹125.05'),
      ];

      for (final c in cases) {
        expect(c.input.toRupeeFormat(), c.expected, reason: 'input=${c.input}');
      }
    });

    test('table: Nominee.validateNominees accepts exact 100% splits that drift in float64', () {
      final validSplits = <List<double>>[
        [16.1, 48.2, 35.7],
        [33.33, 33.33, 33.34],
        [100.0],
      ];

      for (final split in validSplits) {
        final nominees = [
          for (var i = 0; i < split.length; i++)
            Nominee(
              name: 'Nominee $i',
              relationship: NomineeRelationship.son,
              percentage: split[i],
            ),
        ];
        expect(
          Nominee.validateNominees(nominees),
          isNull,
          reason: 'Expected $split to sum to 100.00%',
        );
      }

      final invalidSplits = <List<double>>[
        [33.33, 33.33, 33.33],
        [50.0, 50.01],
      ];
      for (final split in invalidSplits) {
        final nominees = [
          for (var i = 0; i < split.length; i++)
            Nominee(
              name: 'Nominee $i',
              relationship: NomineeRelationship.son,
              percentage: split[i],
            ),
        ];
        expect(
          Nominee.validateNominees(nominees),
          isNotNull,
          reason: 'Expected $split to fail 100.00% check',
        );
      }
    });
  });

  group('LocalDate & DateOnlyConverter timezone-offset immunity', () {
    test('parses ISO strings with IST/negative offsets without UTC calendar day shift', () {
      const converter = DateOnlyConverter();

      // 02:15 IST is 20:45 UTC on the PREVIOUS day (2026-03-31).
      // Calendar-date parsing must preserve 2026-04-01.
      expect(
        converter.fromJson('2026-04-01T02:15:00+05:30'),
        DateTime(2026, 4, 1),
      );
      // 23:45 UTC-5 is 04:45 UTC on the NEXT day (2026-04-01).
      // Calendar-date parsing must preserve 2026-03-31.
      expect(
        converter.fromJson('2026-03-31T23:45:00-05:00'),
        DateTime(2026, 3, 31),
      );
      expect(
        LocalDate.parse('2026-04-01T02:15:00+05:30').toDateTime(),
        DateTime(2026, 4, 1),
      );
    });

    test('Customer.dateOfBirth, OTD.startDate, and RD.startDate serialize as yyyy-MM-dd', () {
      final customer = Customer(
        id: 'c-1',
        name: 'Asha Rao',
        dateOfBirth: DateTime(1985, 4, 1, 23, 45),
      );
      expect(customer.toJson()['date_of_birth'], '1985-04-01');

      final otd = OneTimeDeposit(
        id: 'otd-1',
        principalAmount: 50000,
        termYears: 5,
        termMonths: 0,
        interestRate: 7.5,
        customerId: 'c-1',
        schemeType: OneTimeSchemeType.timeDeposit,
        startDate: DateTime(2026, 4, 1, 23, 45),
      );
      expect(otd.toJson()['start_date'], '2026-04-01');

      final rd = RecurringDeposit(
        id: 'rd-1',
        installmentAmount: 1000,
        termYears: 5,
        termMonths: 0,
        interestRate: 6.7,
        customerId: 'c-1',
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2026, 4, 1, 23, 45),
      );
      expect(rd.toJson()['start_date'], '2026-04-01');
    });
  });

  group('ProjectionCalculator month-end & leap-day clamping + KVP historical boundary', () {
    test('table: leap-day and 31st-of-month openings clamp to month-end instead of overflowing to March', () {
      final tdLeap = ProjectionCalculator.calculateTD(
        principal: 100000,
        startDate: DateTime(2024, 2, 29),
        termYears: 5,
      );
      expect(tdLeap.maturityDate, DateTime(2029, 2, 28));

      final misLeap = ProjectionCalculator.calculateMIS(
        principal: 100000,
        startDate: DateTime(2024, 2, 29),
      );
      expect(misLeap.maturityDate, DateTime(2029, 2, 28));

      final nscLeap = ProjectionCalculator.calculateNSC(
        principal: 100000,
        startDate: DateTime(2024, 2, 29),
      );
      expect(nscLeap.maturityDate, DateTime(2029, 2, 28));

      // 2024-07-31 + 115 months (9Y 7M) lands in Feb 2034 -> must clamp to 2034-02-28 (not Mar 3).
      final kvpMonthEnd = ProjectionCalculator.calculateKVP(
        principal: 50000,
        startDate: DateTime(2024, 7, 31),
      );
      expect(kvpMonthEnd.maturityDate, DateTime(2034, 2, 28));

      // 2024-01-31 + 60 months + 1 defaulted month = 61 months (Feb 2029) -> must clamp to 2029-02-28.
      final rdDefaulted = ProjectionCalculator.calculateRD(
        monthlyInstallment: 1000,
        startDate: DateTime(2024, 1, 31),
        defaultedMonths: 1,
      );
      expect(rdDefaulted.maturityDate, DateTime(2029, 2, 28));
    });

    test('PostalRateService maps pre-relaunch KVP (Dec 2011 - Nov 17 2014) to 8.4% (8Y 7M) and Nov 18 2014+ to 8.7% (8Y 4M)', () {
      const service = PostalRateService();

      final preRelaunch = service.resolveOneTimeSchemeTerms(
        schemeType: OneTimeSchemeType.kisanVikasPatra,
        startDate: DateTime(2013, 6, 15),
      );
      expect(preRelaunch.interestRate, 8.4);
      expect(preRelaunch.termYears, 8);
      expect(preRelaunch.termMonths, 7);

      final relaunched = service.resolveOneTimeSchemeTerms(
        schemeType: OneTimeSchemeType.kisanVikasPatra,
        startDate: DateTime(2014, 11, 20),
      );
      expect(relaunched.interestRate, 8.7);
      expect(relaunched.termYears, 8);
      expect(relaunched.termMonths, 4);
    });
  });
}
