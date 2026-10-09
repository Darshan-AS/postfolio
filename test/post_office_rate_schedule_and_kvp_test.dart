import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/services/postal_rate_service.dart';
import 'package:postfolio/core/services/projection_calculator.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';

void main() {
  group('PostalRateService & Riverpod DI', () {
    test(
      'looks up exact official KVP rates and tenures across historical circulars via postalRateServiceProvider',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(postalRateServiceProvider);

        final q4Fy19 = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2020, 1, 15),
        );
        expect(q4Fy19.interestRate, 7.6);
        expect(q4Fy19.termYears, 9);
        expect(q4Fy19.termMonths, 5);
        expect(q4Fy19.totalMonths, 113);

        final covidEra = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2021, 6, 10),
        );
        expect(covidEra.interestRate, 6.9);
        expect(covidEra.termYears, 10);
        expect(covidEra.termMonths, 4);
        expect(covidEra.totalMonths, 124);

        final currentEra = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2025, 8, 20),
        );
        expect(currentEra.interestRate, 7.5);
        expect(currentEra.termYears, 9);
        expect(currentEra.termMonths, 7);
        expect(currentEra.totalMonths, 115);
      },
    );

    test(
      'looks up official TD (1/2/3/5Y), MIS, NSC, and RD rates by startDate',
      () {
        const service = PostalRateService();
        final date = DateTime(2024, 5, 1);

        final td1 = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.timeDeposit,
          startDate: date,
          tdTenureYears: 1,
        );
        final td2 = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.timeDeposit,
          startDate: date,
          tdTenureYears: 2,
        );
        final td3 = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.timeDeposit,
          startDate: date,
          tdTenureYears: 3,
        );
        final td5 = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.timeDeposit,
          startDate: date,
          tdTenureYears: 5,
        );
        final mis = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.monthlyIncomeScheme,
          startDate: date,
        );
        final nsc = service.resolveOneTimeSchemeTerms(
          schemeType: OneTimeSchemeType.nationalSavingsCertificate,
          startDate: date,
        );
        final rd = service.resolveRecurringSchemeTerms(
          schemeType: RecurringSchemeType.recurringDeposit,
          startDate: date,
        );

        expect(td1.interestRate, 6.9);
        expect(td1.termYears, 1);
        expect(td2.interestRate, 7.0);
        expect(td2.termYears, 2);
        expect(td3.interestRate, 7.1);
        expect(td3.termYears, 3);
        expect(td5.interestRate, 7.5);
        expect(td5.termYears, 5);
        expect(mis.interestRate, 7.4);
        expect(mis.termYears, 5);
        expect(nsc.interestRate, 7.7);
        expect(nsc.termYears, 5);
        expect(rd.interestRate, 6.7);
        expect(rd.termYears, 5);
      },
    );
  });

  group('Start-date-only OTD and RD domain creation', () {
    test(
      'OneTimeDeposit.create and RecurringDeposit.create only need startDate and fetch interest & maturity from PostalRateService',
      () {
        final kvpRes = OneTimeDeposit.create(
          id: 'kvp-1',
          principalAmount: 50000,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2019, 8, 10),
        );
        expect(kvpRes, isA<Success<OneTimeDeposit, String>>());
        final kvp = (kvpRes as Success<OneTimeDeposit, String>).value;
        expect(kvp.interestRate, 7.6);
        expect(kvp.termYears, 9);
        expect(kvp.termMonths, 5);
        expect(kvp.maturityAmount, 100000);
        expect(kvp.maturityDate, DateTime(2029, 1, 10));

        final misRes = OneTimeDeposit.create(
          id: 'mis-1',
          principalAmount: 100000,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.monthlyIncomeScheme,
          startDate: DateTime(2024, 6, 1),
        );
        final mis = (misRes as Success<OneTimeDeposit, String>).value;
        expect(mis.interestRate, 7.4);
        expect(mis.termYears, 5);
        expect(mis.termMonths, 0);
        expect(mis.maturityDate, DateTime(2029, 6, 1));

        final nscRes = OneTimeDeposit.create(
          id: 'nsc-1',
          principalAmount: 100000,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.nationalSavingsCertificate,
          startDate: DateTime(2024, 6, 1),
        );
        final nsc = (nscRes as Success<OneTimeDeposit, String>).value;
        expect(nsc.interestRate, 7.7);
        expect(nsc.termYears, 5);
        expect(nsc.termMonths, 0);
        expect(nsc.maturityDate, DateTime(2029, 6, 1));

        final tdRes = OneTimeDeposit.create(
          id: 'td-3y',
          principalAmount: 100000,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.timeDeposit,
          termYears: 3,
          startDate: DateTime(2024, 6, 1),
        );
        final td = (tdRes as Success<OneTimeDeposit, String>).value;
        expect(td.interestRate, 7.1);
        expect(td.termYears, 3);
        expect(td.termMonths, 0);
        expect(td.maturityDate, DateTime(2027, 6, 1));

        final rdRes = RecurringDeposit.create(
          id: 'rd-1',
          installmentAmount: 5000,
          customerId: 'cust-1',
          schemeType: RecurringSchemeType.recurringDeposit,
          startDate: DateTime(2024, 6, 1),
        );
        expect(rdRes, isA<Success<RecurringDeposit, String>>());
        final rd = (rdRes as Success<RecurringDeposit, String>).value;
        expect(rd.interestRate, 6.7);
        expect(rd.termYears, 5);
        expect(rd.termMonths, 0);
        expect(rd.maturityDate, DateTime(2029, 6, 1));
      },
    );
  });

  group('ProjectionCalculator KVP accuracy', () {
    test(
      'resolves boundary KVP rates to exact Post Office passbook months without +1 month rounding drift',
      () {
        // 7.6% -> 113 months (9Y 5M), not 114 months (9Y 6M)
        expect(ProjectionCalculator.calculateKvpTermMonths(7.6), 113);
        // 6.9% -> 124 months (10Y 4M), not 125 months (10Y 5M)
        expect(ProjectionCalculator.calculateKvpTermMonths(6.9), 124);
        // 7.8% -> 110 months (9Y 2M), not 111 months (9Y 3M)
        expect(ProjectionCalculator.calculateKvpTermMonths(7.8), 110);
        // Other official notified rates
        expect(ProjectionCalculator.calculateKvpTermMonths(7.5), 115);
        expect(ProjectionCalculator.calculateKvpTermMonths(7.7), 112);
        expect(ProjectionCalculator.calculateKvpTermMonths(7.3), 118);
        expect(ProjectionCalculator.calculateKvpTermMonths(7.2), 120);
        expect(ProjectionCalculator.calculateKvpTermMonths(7.0), 123);
        expect(ProjectionCalculator.calculateKvpTermMonths(8.7), 100);
        expect(ProjectionCalculator.calculateKvpTermMonths(8.4), 103);
      },
    );

    test(
      'calculates exact maturity date and note for 7.6% KVP matching Post Office passbook from startDate alone',
      () {
        final startDate = DateTime(2019, 8, 10);
        final projection = ProjectionCalculator.calculateKVP(
          principal: 50000,
          startDate: startDate,
        );

        expect(projection.interestRate, 7.6);
        expect(projection.termYears, 9);
        expect(projection.termMonths, 5);
        expect(projection.maturityAmount, 100000);
        expect(projection.totalInterestEarned, 50000);
        // 2019-08-10 + 113 months (9 years, 5 months) = 2029-01-10
        expect(projection.maturityDate, DateTime(2029, 1, 10));
        expect(projection, isA<WealthAccumulation>());
        expect((projection as WealthAccumulation).note, '9 Years & 5 Months');
      },
    );
  });

  group('OneTimeDeposit KVP self-healing and custom overrides', () {
    test(
      'self-heals legacy 9Y 6M (114m) and 9Y 0M (108m) DB records for 7.6% KVP so detail field and banner match',
      () {
        final legacyRoundedDeposit = OneTimeDeposit(
          id: 'kvp-legacy-round',
          principalAmount: 100000,
          termYears: 9,
          termMonths: 6, // Old .round() artifact (114 months)
          interestRate: 7.6,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2019, 10, 1),
        );

        expect(legacyRoundedDeposit.effectiveTermYears, 9);
        expect(legacyRoundedDeposit.effectiveTermMonths, 5);
        expect(legacyRoundedDeposit.maturityDate, DateTime(2029, 3, 1));
        expect(
          (legacyRoundedDeposit.projection as WealthAccumulation).note,
          '9 Years & 5 Months',
        );

        final legacyDefaultDeposit = legacyRoundedDeposit.copyWith(
          termYears: 9,
          termMonths: 0, // Old 9Y 0M migration placeholder (108 months)
        );
        expect(legacyDefaultDeposit.effectiveTermYears, 9);
        expect(legacyDefaultDeposit.effectiveTermMonths, 5);
        expect(legacyDefaultDeposit.maturityDate, DateTime(2029, 3, 1));
      },
    );

    test(
      'preserves intentional custom KVP tenure override across projection and detail getters',
      () {
        final customDepositResult = OneTimeDeposit.create(
          id: 'kvp-custom',
          principalAmount: 100000,
          termYears: 9,
          termMonths: 8, // Custom override (116 months)
          interestRate: 7.6,
          customerId: 'cust-1',
          schemeType: OneTimeSchemeType.kisanVikasPatra,
          startDate: DateTime(2019, 10, 1),
        );

        expect(customDepositResult, isA<Success<OneTimeDeposit, String>>());
        final deposit =
            (customDepositResult as Success<OneTimeDeposit, String>).value;
        expect(deposit.termYears, 9);
        expect(deposit.termMonths, 8);
        expect(deposit.effectiveTermYears, 9);
        expect(deposit.effectiveTermMonths, 8);
        expect(deposit.maturityDate, DateTime(2029, 6, 1));
        expect(
          (deposit.projection as WealthAccumulation).note,
          '9 Years & 8 Months',
        );
      },
    );
  });
}
