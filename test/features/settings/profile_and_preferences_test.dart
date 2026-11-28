import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/enums/start_tab.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/providers/app_preferences_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/features/profile/data/profile_repository.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  group('String masking extensions', () {
    test(
      'toMaskedAadhaarFormat keeps last 4 digits and handles edge lengths',
      () {
        expect('123456789012'.toMaskedAadhaarFormat(), 'XXXX XXXX 9012');
        expect('1234 5678 9012'.toMaskedAadhaarFormat(), 'XXXX XXXX 9012');
        expect('123456'.toMaskedAadhaarFormat(), 'XX3456');
        expect('1234'.toMaskedAadhaarFormat(), '1234');
      },
    );

    test('toMaskedPanFormat uppercases and keeps last 4 characters', () {
      expect('abcde1234f'.toMaskedPanFormat(), 'XXXXXX234F');
      expect('  ab1234  '.toMaskedPanFormat(), 'XX1234');
      expect('ab12'.toMaskedPanFormat(), 'AB12');
    });
  });

  group('AgentProfile validators, license status & summary', () {
    test('validateName enforces required and min length', () {
      expect(AgentProfile.validateName(null), isNotNull);
      expect(AgentProfile.validateName('   '), isNotNull);
      expect(AgentProfile.validateName('A'), isNotNull);
      expect(AgentProfile.validateName('Jim Gordon'), isNull);
    });

    test(
      'validatePhone allows empty, rejects letters, and checks 7-15 digits',
      () {
        expect(AgentProfile.validatePhone(null), isNull);
        expect(AgentProfile.validatePhone('  '), isNull);
        expect(AgentProfile.validatePhone('12345'), isNotNull);
        expect(AgentProfile.validatePhone('1234567890123456'), isNotNull);
        expect(AgentProfile.validatePhone('call 9876543210'), isNotNull);
        expect(AgentProfile.validatePhone('+91 98765-43210'), isNull);
      },
    );

    test('validateAadhaar & validatePan allow empty and check format', () {
      expect(AgentProfile.validateAadhaar(null), isNull);
      expect(AgentProfile.validateAadhaar(''), isNull);
      expect(AgentProfile.validateAadhaar('12345'), isNotNull);
      expect(AgentProfile.validateAadhaar('1234 5678 9012'), isNull);

      expect(AgentProfile.validatePan(null), isNull);
      expect(AgentProfile.validatePan(' '), isNull);
      expect(AgentProfile.validatePan('BADPAN'), isNotNull);
      expect(AgentProfile.validatePan('abcde1234f'), isNull);
    });

    test(
      'licenseDaysRemainingAt and licenseStatusAt classify valid, expiringSoon, expired, and null',
      () {
        final today = DateTime(2026, 11, 28);
        expect(AgentProfile.licenseDaysRemainingAt(null, today), isNull);
        expect(
          AgentProfile.licenseDaysRemainingAt(DateTime(2026, 11, 27), today),
          -1,
        );
        expect(
          AgentProfile.licenseDaysRemainingAt(DateTime(2026, 12, 28), today),
          30,
        );
        expect(AgentProfile.licenseStatusAt(null, today), isNull);
        expect(
          AgentProfile.licenseStatusAt(DateTime(2026, 11, 27), today),
          LicenseValidityStatus.expired,
        );
        expect(
          AgentProfile.licenseStatusAt(DateTime(2026, 11, 28), today),
          LicenseValidityStatus.expiringSoon,
        );
        expect(
          AgentProfile.licenseStatusAt(DateTime(2027, 1, 27), today),
          LicenseValidityStatus.expiringSoon,
        );
        expect(
          AgentProfile.licenseStatusAt(DateTime(2027, 2, 15), today),
          LicenseValidityStatus.valid,
        );
      },
    );

    test('agencySummaryLabel and section flags evaluate cleanly', () {
      const empty = AgentProfile(id: '1');
      expect(empty.agencySummaryLabel, isNull);
      expect(empty.hasSharedAgencyDetails, isFalse);
      expect(empty.hasLicenses, isFalse);
      expect(empty.hasKycOrCommissionDetails, isFalse);

      const full = AgentProfile(
        id: '1',
        agencyTypes: [AgencyType.mpkby, AgencyType.sas],
        agencyCode: 'DOP-01',
        postOfficeBranch: 'Jayanagar HPO',
        mpkbyLicenseNo: 'MPKBY-42',
        panNumber: 'ABCDE1234F',
      );
      expect(full.agencySummaryLabel, 'DOP-01 • Jayanagar HPO');
      expect(full.hasMpkby, isTrue);
      expect(full.hasSas, isTrue);
      expect(full.hasSharedAgencyDetails, isTrue);
      expect(full.hasMpkbyLicenseDetails, isTrue);
      expect(full.hasSasLicenseDetails, isFalse);
      expect(full.hasLicenses, isTrue);
      expect(full.hasKycOrCommissionDetails, isTrue);
    });
  });

  group('StorageService preferences & clearListCriteria', () {
    test(
      'persists app preferences, falls back on unknown startTab, and clears list criteria',
      () async {
        SharedPreferences.setMockInitialValues({'default_start_tab': 'legacy'});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        expect(storage.getUseDynamicColor(), isTrue);
        expect(storage.getStartTab(), AppStartTab.customers);
        expect(storage.getHapticsEnabled(), isTrue);
        expect(storage.getMaskSensitiveIds(), isFalse);

        await storage.setUseDynamicColor(false);
        await storage.setStartTab(AppStartTab.monthlyHub);
        await storage.setHapticsEnabled(false);
        await storage.setMaskSensitiveIds(true);

        expect(storage.getUseDynamicColor(), isFalse);
        expect(storage.getStartTab(), AppStartTab.monthlyHub);
        expect(storage.getHapticsEnabled(), isFalse);
        expect(storage.getMaskSensitiveIds(), isTrue);

        await storage.setCustomerSortField(CustomerSortField.createdAt);
        await storage.setCustomerSortDirection(SortDirection.desc);
        await storage.setOTDSortField(OTDSortField.amount);
        await storage.setOTDSortDirection(SortDirection.desc);
        await storage.setOTDStatusFilters([DepositStatus.closed]);
        await storage.setOTDUrgencyFilters([MaturityUrgency.matured]);
        await storage.setOTDSchemeFilters([
          OneTimeSchemeType.monthlyIncomeScheme,
        ]);
        await storage.setRDSortField(RDSortField.amount);
        await storage.setRDSortDirection(SortDirection.desc);
        await storage.setRDStatusFilters([DepositStatus.closed]);
        await storage.setRDUrgencyFilters([MaturityUrgency.maturingSoon]);

        await storage.clearListCriteria();

        expect(storage.getCustomerSortField(), isNull);
        expect(storage.getCustomerSortDirection(), isNull);
        expect(storage.getOTDSortField(), isNull);
        expect(storage.getOTDStatusFilters(), isNull);
        expect(storage.getOTDUrgencyFilters(), isNull);
        expect(storage.getOTDSchemeFilters(), isNull);
        expect(storage.getRDSortField(), isNull);
        expect(storage.getRDStatusFilters(), isNull);
        expect(storage.getRDUrgencyFilters(), isNull);
        expect(storage.getStartTab(), AppStartTab.monthlyHub);
        expect(storage.getMaskSensitiveIds(), isTrue);
      },
    );
  });

  group('AppPreferencesNotifier', () {
    test(
      'loads from StorageService and updates state across all preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'use_dynamic_color': false,
          'default_start_tab': 'dashboard',
          'haptics_enabled': false,
          'mask_sensitive_ids': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final initial = container.read(appPreferencesProvider);
        expect(initial.useDynamicColor, isFalse);
        expect(initial.startTab, AppStartTab.dashboard);
        expect(initial.hapticsEnabled, isFalse);
        expect(initial.maskSensitiveIds, isTrue);

        final notifier = container.read(appPreferencesProvider.notifier);
        await notifier.setHapticsEnabled(true);
        await notifier.setStartTab(AppStartTab.recurringDeposits);
        await notifier.setUseDynamicColor(true);
        await notifier.setMaskSensitiveIds(false);

        final updated = container.read(appPreferencesProvider);
        expect(updated.hapticsEnabled, isTrue);
        expect(updated.startTab, AppStartTab.recurringDeposits);
        expect(updated.useDynamicColor, isTrue);
        expect(updated.maskSensitiveIds, isFalse);
      },
    );
  });

  group('ProfileController', () {
    test(
      'fetches profile, saves normalized fields across personal/licensing/KYC, and falls back when row missing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final authRepo = FakeAuthRepository(
          initialUser: const AuthUser(
            id: 'agent-1',
            email: 'agent@postfolio.dev',
            displayName: 'Agent One',
          ),
        );
        final profileRepo = FakeProfileRepository();
        addTearDown(authRepo.dispose);

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(authRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
          ],
        );
        addTearDown(container.dispose);

        final loaded = await container.read(profileControllerProvider.future);
        expect(loaded, isNotNull);
        expect(loaded!.id, 'agent-1');
        expect(loaded.name, 'Agent One');
        expect(loaded.email, 'agent@postfolio.dev');

        final saveResult = await container
            .read(profileControllerProvider.notifier)
            .saveProfile(
              loaded.copyWith(
                name: '  Ramesh Kumar  ',
                phone: '  9876543210 ',
                address: ' 12 MG Road ',
                dateOfBirth: DateTime(1985, 6, 15, 10, 30),
                agencyCode: '  ',
                postOfficeBranch: ' Jayanagar HPO ',
                agencyTypes: const [AgencyType.sas, AgencyType.mpkby],
                mpkbyLicenseNo: ' MPKBY-1 ',
                mpkbyValidUntil: DateTime(2028, 3, 31, 8),
                sasLicenseNo: ' SAS-2 ',
                sasValidUntil: DateTime(2027, 12, 31, 8),
                panNumber: ' abcde1234f ',
                aadhaarNumber: '1234 5678 9012',
                commissionSbAccount: ' 0100020030 ',
                notes: ' Counter 2 ',
              ),
            );
        expect(saveResult, isA<Success<void, String>>());

        final refreshed = container.read(profileControllerProvider).value!;
        expect(refreshed.name, 'Ramesh Kumar');
        expect(refreshed.phone, '9876543210');
        expect(refreshed.address, '12 MG Road');
        expect(refreshed.dateOfBirth, DateTime(1985, 6, 15));
        expect(refreshed.agencyCode, isNull);
        expect(refreshed.postOfficeBranch, 'Jayanagar HPO');
        expect(refreshed.agencyTypes, const [AgencyType.mpkby, AgencyType.sas]);
        expect(refreshed.mpkbyLicenseNo, 'MPKBY-1');
        expect(refreshed.mpkbyValidUntil, DateTime(2028, 3, 31));
        expect(refreshed.sasLicenseNo, 'SAS-2');
        expect(refreshed.sasValidUntil, DateTime(2027, 12, 31));
        expect(refreshed.panNumber, 'ABCDE1234F');
        expect(refreshed.aadhaarNumber, '123456789012');
        expect(refreshed.commissionSbAccount, '0100020030');
        expect(refreshed.notes, 'Counter 2');
      },
    );

    test(
      'always reflects signed-in admin profile even while Acting-As another agent',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final authRepo = FakeAuthRepository(
          initialUser: const AuthUser(
            id: 'admin-1',
            email: 'admin@postfolio.dev',
            displayName: 'Admin Self',
          ),
        );
        final profileRepo = FakeProfileRepository(
          initialProfile: const AgentProfile(
            id: 'admin-1',
            name: 'Admin Self',
            email: 'admin@postfolio.dev',
            agencyCode: 'ADM-01',
          ),
        );
        addTearDown(authRepo.dispose);

        final adminRepo = FakeAdminRepository(isAdmin: true);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(authRepo),
            adminRepositoryProvider.overrideWithValue(adminRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(
              const AgentProfile(
                id: 'other-agent',
                name: 'Other Agent',
                email: 'other@postfolio.dev',
              ),
            );

        final profile = await container.read(profileControllerProvider.future);
        expect(profile!.id, 'admin-1');
        expect(profile.name, 'Admin Self');
      },
    );

    test('Demo Mode profile resets when demoSessionEpoch increments', () async {
      SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(profileControllerProvider.future);
      expect(initial!.name, 'Jim Gordon');
      expect(initial.mpkbyLicenseNo, isNotNull);
      expect(initial.sasLicenseNo, isNotNull);

      await container
          .read(profileControllerProvider.notifier)
          .saveProfile(initial.copyWith(name: 'Edited Demo Name'));
      expect(
        container.read(profileControllerProvider).value!.name,
        'Edited Demo Name',
      );

      container.read(demoSessionEpochProvider.notifier).reset();
      final reset = await container.read(profileControllerProvider.future);
      expect(reset!.name, 'Jim Gordon');
    });

    test(
      'toUpdatePayload uses model serialization and FakeProfileRepository.demo offsets dates from today',
      () async {
        final payload = AgentProfile(
          id: 'agent-1',
          name: '  Ramesh Kumar ',
          email: 'agent@postfolio.dev',
          agencyTypes: const [AgencyType.sas, AgencyType.mpkby],
          mpkbyValidUntil: DateTime(2028, 3, 31, 9, 45),
        ).normalized().toUpdatePayload();

        expect(payload.containsKey('id'), isFalse);
        expect(payload.containsKey('email'), isFalse);
        expect(payload['name'], 'Ramesh Kumar');
        expect(payload['agency_types'], ['mpkby', 'sas']);
        expect(payload['mpkby_valid_until'], '2028-03-31');

        final futureToday = DateTime(2030, 1, 1);
        final demoRepo = FakeProfileRepository.demo(today: futureToday);
        final demoRes = await demoRepo.fetchProfile('demo_user');
        final demoProfile = (demoRes as Success<AgentProfile?, String>).value!;
        expect(
          AgentProfile.licenseStatusAt(
            demoProfile.mpkbyValidUntil,
            futureToday,
          ),
          LicenseValidityStatus.valid,
        );
        expect(
          AgentProfile.licenseStatusAt(demoProfile.sasValidUntil, futureToday),
          LicenseValidityStatus.expiringSoon,
        );
      },
    );
  });
}
