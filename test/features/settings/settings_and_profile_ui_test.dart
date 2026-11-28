import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/constants/app_info.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/enums/start_tab.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/app_preferences_provider.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/profile/data/profile_repository.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:postfolio/features/profile/presentation/screens/profile_screen.dart';
import 'package:postfolio/features/settings/presentation/screens/settings_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  final source = FakeDataSource();

  Future<
    ({
      ProviderContainer container,
      FakeAuthRepository authRepo,
      FakeProfileRepository profileRepo,
      _RecordingIntentService intentService,
    })
  >
  createEnv({
    bool demoMode = false,
    bool isAdmin = false,
    Map<String, Object> initialPrefs = const {},
    List<Customer>? customers,
    AgentProfile? initialProfile,
    String? profileFetchError,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (demoMode) 'demo_mode_enabled': true,
      ...initialPrefs,
    });
    final prefs = await SharedPreferences.getInstance();
    final intentService = _RecordingIntentService();
    final authRepo = FakeAuthRepository(
      initialUser: const AuthUser(
        id: 'agent-1',
        email: 'agent@postfolio.dev',
        displayName: 'Agent One',
      ),
    );
    final profileRepo = FakeProfileRepository(
      fetchError: profileFetchError,
      initialProfile:
          initialProfile ??
          AgentProfile(
            id: 'agent-1',
            name: 'Agent One',
            email: 'agent@postfolio.dev',
            agencyCode: 'DOP-101',
            phone: '9876543210',
            address: '10 MG Road, Bengaluru',
            dateOfBirth: DateTime(1984, 4, 10),
            postOfficeBranch: 'Jayanagar HPO',
            agencyTypes: const [AgencyType.mpkby, AgencyType.sas],
            mpkbyLicenseNo: 'MPKBY-42',
            mpkbyValidUntil: DateTime(2027, 6, 30),
            sasLicenseNo: 'SAS-99',
            sasValidUntil: DateTime(2026, 12, 15),
            panNumber: 'ABCDE1234F',
            aadhaarNumber: '123456789012',
            commissionSbAccount: '0100088899',
            notes: 'Counter #3 timings 10:00–13:30',
          ),
    );
    final rdRepo = FakeRecurringDepositRepository(
      deposits: source.recurringDeposits,
    );
    final ledgerRepo = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
    );
    addTearDown(() {
      authRepo.dispose();
      rdRepo.dispose();
      ledgerRepo.dispose();
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 28)),
        intentServiceProvider.overrideWithValue(intentService),
        authRepositoryProvider.overrideWithValue(authRepo),
        adminRepositoryProvider.overrideWithValue(
          FakeAdminRepository(isAdmin: isAdmin),
        ),
        if (!demoMode) profileRepositoryProvider.overrideWithValue(profileRepo),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(
            customers: customers ?? source.customers,
            delay: Duration.zero,
          ),
        ),
        oneTimeDepositRepositoryProvider.overrideWithValue(
          FakeOneTimeDepositRepository(
            deposits: source.oneTimeDeposits,
            delay: Duration.zero,
          ),
        ),
        recurringDepositRepositoryProvider.overrideWithValue(rdRepo),
        rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
      ],
    );
    addTearDown(container.dispose);
    return (
      container: container,
      authRepo: authRepo,
      profileRepo: profileRepo,
      intentService: intentService,
    );
  }

  Future<void> pumpRouter(
    WidgetTester tester,
    ProviderContainer container, {
    Size size = const Size(360, 800),
    double textScale = 1.0,
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(
                  Theme.of(context).colorScheme,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocaleUtils.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen, {
    Size size = const Size(360, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(
                  Theme.of(context).colorScheme,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  group('ProfileScreen & Navigation', () {
    testWidgets(
      'tapping shell avatar opens detailed ProfileScreen with sections, expiry badge, and ID masking',
      (tester) async {
        final env = await createEnv(initialPrefs: {'mask_sensitive_ids': true});
        await pumpRouter(tester, env.container);

        final avatarBtn = find.byKey(
          const ValueKey('shell_account_avatar_button'),
        );
        expect(avatarBtn, findsOneWidget);
        final shellAvatar = tester.widget<AppShapeAvatar>(
          find.descendant(of: avatarBtn, matching: find.byType(AppShapeAvatar)),
        );
        expect(shellAvatar.shape, AppAvatarShape.cookie9);
        await tester.tap(avatarBtn);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
        final header = tester.widget<EntityDetailHeader>(
          find.byType(EntityDetailHeader),
        );
        expect(header.heroTag, isNotNull);
        expect(header.avatarShape, AppAvatarShape.cookie9);
        expect(header.avatarOpensFrom, isNull);

        expect(find.text('Agent One'), findsOneWidget);
        expect(find.text('DOP-101 • Jayanagar HPO'), findsOneWidget);
        expect(find.text('10 MG Road, Bengaluru'), findsOneWidget);
        expect(find.text('DOP-101'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('profile_mpkby_license_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('profile_sas_license_card')),
          findsOneWidget,
        );
        expect(find.text('MPKBY-42'), findsOneWidget);
        expect(find.text('SAS-99'), findsOneWidget);
        // MPKBY expires 2027-06-30 (>60 days), SAS expires 2026-12-15 (17 days left).
        expect(find.text(t.settings.licenseValid), findsOneWidget);
        expect(find.text(t.settings.licenseExpiringSoon), findsOneWidget);
        expect(
          find.textContaining(t.settings.licenseDaysLeft(count: 17)),
          findsOneWidget,
        );
        // Single Settings entry point in AppBar; no duplicate bottom Settings row.
        expect(
          find.byKey(const ValueKey('profile_settings_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('profile_open_settings_row')),
          findsNothing,
        );

        // KYC IDs are masked when preference is enabled and reveal on eye tap.
        expect(find.text('XXXX XXXX 9012'), findsOneWidget);
        expect(find.text('XXXXXX234F'), findsOneWidget);
        expect(find.text('ABCDE1234F'), findsNothing);
        final togglePan = find.byKey(
          ValueKey('toggle_mask_${t.settings.profileFields.panNumber}'),
        );
        await tester.ensureVisible(togglePan);
        await tester.pumpAndSettle();
        await tester.tap(togglePan);
        await tester.pumpAndSettle();
        expect(find.text('ABCDE1234F'), findsOneWidget);

        expect(find.text('0100088899'), findsOneWidget);
        expect(find.text('Counter #3 timings 10:00–13:30'), findsOneWidget);
      },
    );

    testWidgets('direct ProfileScreen uses circle-to-cookie9 opening morph', (
      tester,
    ) async {
      final env = await createEnv();
      await pumpScreen(tester, env.container, const ProfileScreen());
      final header = tester.widget<EntityDetailHeader>(
        find.byType(EntityDetailHeader),
      );
      expect(header.heroTag, isNull);
      expect(header.avatarShape, AppAvatarShape.cookie9);
      expect(header.avatarOpensFrom, AppAvatarShape.circle);
    });

    testWidgets(
      'shell avatar performs same-shape cookie9 Hero flight and returns on back',
      (tester) async {
        final env = await createEnv();
        await pumpRouter(tester, env.container, disableAnimations: false);

        final avatarBtn = find.byKey(
          const ValueKey('shell_account_avatar_button'),
        );
        final shellRect = tester.getRect(
          find.descendant(of: avatarBtn, matching: find.byType(AppShapeAvatar)),
        );
        expect(shellRect.width, AppDimensions.iconLg);

        await tester.tap(avatarBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        final heroFinder = find.byWidgetPredicate(
          (w) =>
              w is Hero &&
              w.tag is (Object, EntityHeroPart) &&
              (w.tag as (Object, EntityHeroPart)).$2 == EntityHeroPart.avatar,
        );
        expect(heroFinder, findsWidgets);

        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
        final detailHeader = tester.widget<EntityDetailHeader>(
          find.byType(EntityDetailHeader),
        );
        expect(detailHeader.avatarShape, AppAvatarShape.cookie9);
        expect(detailHeader.heroTag, isNotNull);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsNothing);
      },
    );

    testWidgets(
      'omits empty agency, license, KYC, and notes sections for a minimal profile',
      (tester) async {
        final env = await createEnv(
          initialProfile: const AgentProfile(
            id: 'agent-1',
            name: 'New Agent',
            email: 'agent@postfolio.dev',
          ),
        );
        await pumpScreen(tester, env.container, const ProfileScreen());
        expect(find.text('New Agent'), findsOneWidget);
        expect(find.text(t.settings.profileFields.agencySection), findsNothing);
        expect(
          find.text(t.settings.profileFields.licensesSection),
          findsNothing,
        );
        expect(find.text(t.settings.profileFields.kycSection), findsNothing);
        expect(find.text(t.settings.profileFields.notes), findsNothing);
      },
    );

    testWidgets('shows expired badge when license validUntil is in the past', (
      tester,
    ) async {
      final envExpired = await createEnv(
        initialProfile: AgentProfile(
          id: 'agent-1',
          name: 'Expired Agent',
          email: 'agent@postfolio.dev',
          mpkbyLicenseNo: 'MPKBY-OLD',
          mpkbyValidUntil: DateTime(2026, 11, 1),
        ),
      );
      await pumpScreen(tester, envExpired.container, const ProfileScreen());
      expect(find.text(t.settings.licenseExpired), findsOneWidget);
    });

    testWidgets(
      'shows error state with Retry when profile fetch fails and recovers on retry',
      (tester) async {
        final env = await createEnv(profileFetchError: 'Network timeout');
        await pumpScreen(tester, env.container, const ProfileScreen());

        expect(find.byType(ErrorStateView), findsOneWidget);
        expect(find.textContaining('Network timeout'), findsOneWidget);

        env.profileRepo.fetchError = null;
        await tester.tap(find.text(t.common.retry));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorStateView), findsNothing);
        expect(find.text('Agent One'), findsOneWidget);
      },
    );

    testWidgets(
      'sign out on ProfileScreen asks confirmation; cancel stays signed in, confirm signs out',
      (tester) async {
        final env = await createEnv();
        await pumpRouter(tester, env.container);

        await tester.tap(
          find.byKey(const ValueKey('shell_account_avatar_button')),
        );
        await tester.pumpAndSettle();

        final signOutBtn = find.byKey(
          const ValueKey('settings_sign_out_button'),
        );
        await tester.ensureVisible(signOutBtn);
        await tester.pumpAndSettle();
        await tester.tap(signOutBtn);
        await tester.pumpAndSettle();
        expect(find.text(t.settings.signOutConfirmTitle), findsOneWidget);

        await tester.tap(find.text(t.common.cancel));
        await tester.pumpAndSettle();
        expect(env.authRepo.signOutCount, 0);

        await tester.tap(signOutBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.auth.signOut).last);
        await tester.pumpAndSettle();
        expect(env.authRepo.signOutCount, 1);
      },
    );

    testWidgets(
      'Demo Mode on ProfileScreen shows Reset & Exit quick actions and hides Sign Out',
      (tester) async {
        final env = await createEnv(demoMode: true);
        await pumpScreen(tester, env.container, const ProfileScreen());

        final resetBtn = find.byKey(
          const ValueKey('settings_reset_demo_button'),
        );
        expect(resetBtn, findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings_exit_demo_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('settings_sign_out_button')),
          findsNothing,
        );

        await tester.tap(resetBtn);
        await tester.pumpAndSettle();
        expect(env.container.read(demoSessionEpochProvider), 1);
        expect(find.text(t.common.demoDataReset), findsOneWidget);
      },
    );
  });

  group('SettingsScreen', () {
    testWidgets(
      'navigates from ProfileScreen and updates theme, dynamic color, start tab, and list reset',
      (tester) async {
        final env = await createEnv(
          initialPrefs: {
            'customer_sort_field': CustomerSortField.createdAt.name,
            'customer_sort_direction': SortDirection.desc.name,
          },
        );
        await pumpRouter(tester, env.container);

        await tester.tap(
          find.byKey(const ValueKey('shell_account_avatar_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('profile_settings_button')));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text(AppInfo.displayVersion), findsOneWidget);

        await tester.tap(find.text(t.settings.themeDarkShort));
        await tester.pumpAndSettle();
        expect(env.container.read(themeModeProvider), AppThemeMode.dark);

        await tester.tap(find.text(t.settings.themeAccessibleShort));
        await tester.pumpAndSettle();
        expect(
          env.container.read(themeModeProvider),
          AppThemeMode.accessibleSystem,
        );
        expect(
          find.text(t.settings.dynamicColorDisabledForContrast),
          findsOneWidget,
        );

        await tester.tap(find.text(t.settings.themeSystemShort));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_dynamic_color_switch')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings_dynamic_color_switch')),
        );
        await tester.pumpAndSettle();
        expect(
          env.container.read(appPreferencesProvider).useDynamicColor,
          isFalse,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_start_tab_row')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings_start_tab_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStartTab.monthlyHub.displayName).last);
        await tester.pumpAndSettle();
        expect(
          env.container.read(appPreferencesProvider).startTab,
          AppStartTab.monthlyHub,
        );

        expect(
          env.container.read(customerListCriteriaProvider).sortField,
          CustomerSortField.createdAt,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_reset_filters_row')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings_reset_filters_row')),
        );
        await tester.pumpAndSettle();
        expect(
          env.container.read(customerListCriteriaProvider).sortField,
          CustomerSortField.name,
        );
        expect(find.text(t.settings.filtersResetSuccess), findsOneWidget);
      },
    );

    testWidgets('haptics toggle controls AppFeedback.lightImpact', (
      tester,
    ) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final env = await createEnv();
      await pumpScreen(tester, env.container, const SettingsScreen());

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_haptics_switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_haptics_switch')));
      await tester.pumpAndSettle();
      expect(
        env.container.read(appPreferencesProvider).hapticsEnabled,
        isFalse,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_reset_filters_row')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings_reset_filters_row')),
      );
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);

      // Re-enable haptics and verify feedback triggers vibration without global static state.
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_haptics_switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_haptics_switch')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_reset_filters_row')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings_reset_filters_row')),
      );
      await tester.pumpAndSettle();
      expect(haptics, isNotEmpty);
    });

    testWidgets(
      'Support & About actions launch support email, privacy policy, license page, and copy version',
      (tester) async {
        String? copiedClipboardText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedClipboardText =
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        final env = await createEnv();
        await pumpScreen(tester, env.container, const SettingsScreen());

        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_contact_support_row')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings_contact_support_row')),
        );
        await tester.pumpAndSettle();
        expect(env.intentService.supportEmails, hasLength(1));
        expect(env.intentService.supportEmails.single.to, AppInfo.supportEmail);

        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_privacy_policy_row')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings_privacy_policy_row')),
        );
        await tester.pumpAndSettle();
        expect(env.intentService.externalUrls, [AppInfo.privacyPolicyUrl]);

        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_copy_version_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('settings_copy_version_button')),
        );
        await tester.pumpAndSettle();
        expect(copiedClipboardText, AppInfo.fullVersion);
        expect(find.text(t.common.copiedToClipboard), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('settings_licenses_row')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings_licenses_row')));
        await tester.pumpAndSettle();
        expect(find.byType(LicensePage), findsOneWidget);
      },
    );
  });

  group('ProfileEditScreen', () {
    testWidgets(
      'edits and saves full agent profile fields from ProfileScreen',
      (tester) async {
        final env = await createEnv();
        await pumpRouter(tester, env.container);

        await tester.tap(
          find.byKey(const ValueKey('shell_account_avatar_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('profile_edit_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileEditScreen), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Agent One'),
          'Inspector Gordon',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'DOP-101'),
          'DOP-999',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'MPKBY-42'),
          'MPKBY-NEW-77',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileEditScreen), findsNothing);
        final saved = env.container.read(profileControllerProvider).value!;
        expect(saved.name, 'Inspector Gordon');
        expect(saved.agencyCode, 'DOP-999');
        expect(saved.mpkbyLicenseNo, 'MPKBY-NEW-77');
      },
    );

    testWidgets(
      'toggles multi-select agency types and conditionally shows license sections',
      (tester) async {
        final env = await createEnv(
          initialProfile: const AgentProfile(
            id: 'agent-1',
            name: 'Solo Agent',
            email: 'agent@postfolio.dev',
            agencyTypes: [AgencyType.mpkby],
          ),
        );
        await pumpScreen(tester, env.container, const ProfileEditScreen());

        expect(
          find.byKey(const ValueKey('profile_agency_types_group')),
          findsOneWidget,
        );
        expect(
          find.text(t.settings.profileFields.mpkbySection),
          findsOneWidget,
        );
        expect(find.text(t.settings.profileFields.sasSection), findsNothing);

        final sasToggle = find.descendant(
          of: find.byKey(const ValueKey('profile_agency_types_group')),
          matching: find.text(AgencyType.sas.displayName),
        );
        await tester.ensureVisible(sasToggle);
        await tester.pumpAndSettle();
        await tester.tap(sasToggle);
        await tester.pumpAndSettle();

        expect(find.text(t.settings.profileFields.sasSection), findsOneWidget);

        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();

        final saved = env.container.read(profileControllerProvider).value!;
        expect(saved.agencyTypes, const [AgencyType.mpkby, AgencyType.sas]);
      },
    );

    testWidgets(
      'toggling a scheme off hides its license fields, restores draft on toggle back, and clears on save',
      (tester) async {
        final env = await createEnv(
          initialProfile: AgentProfile(
            id: 'agent-1',
            name: 'Dual Agent',
            email: 'agent@postfolio.dev',
            agencyTypes: const [AgencyType.mpkby, AgencyType.sas],
            mpkbyLicenseNo: 'MPKBY-42',
            sasLicenseNo: 'SAS-99',
            sasValidUntil: DateTime(2027, 5, 1),
          ),
        );
        await pumpScreen(tester, env.container, const ProfileEditScreen());

        expect(
          find.text(t.settings.profileFields.mpkbySection),
          findsOneWidget,
        );
        expect(find.text(t.settings.profileFields.sasSection), findsOneWidget);
        expect(find.text('SAS-99'), findsOneWidget);

        final sasToggle = find.descendant(
          of: find.byKey(const ValueKey('profile_agency_types_group')),
          matching: find.text(AgencyType.sas.displayName),
        );
        await tester.ensureVisible(sasToggle);
        await tester.pumpAndSettle();
        await tester.tap(sasToggle);
        await tester.pumpAndSettle();

        expect(find.text(t.settings.profileFields.sasSection), findsNothing);

        // Toggling back ON before save restores the typed/existing draft intact.
        await tester.tap(sasToggle);
        await tester.pumpAndSettle();
        expect(find.text(t.settings.profileFields.sasSection), findsOneWidget);
        expect(find.text('SAS-99'), findsOneWidget);

        // Toggling OFF and saving clears only that scheme's license values.
        await tester.tap(sasToggle);
        await tester.pumpAndSettle();
        expect(find.text(t.settings.profileFields.sasSection), findsNothing);

        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();

        final saved = env.container.read(profileControllerProvider).value!;
        expect(saved.agencyTypes, const [AgencyType.mpkby]);
        expect(saved.mpkbyLicenseNo, 'MPKBY-42');
        expect(saved.sasLicenseNo, isNull);
        expect(saved.sasValidUntil, isNull);
      },
    );

    testWidgets('prompts before discarding unsaved profile edits', (
      tester,
    ) async {
      final env = await createEnv();
      await pumpRouter(tester, env.container);

      await tester.tap(
        find.byKey(const ValueKey('shell_account_avatar_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile_edit_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Agent One'),
        'Unsaved Name',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(t.common.unsavedChanges.title), findsOneWidget);
    });

    testWidgets(
      'rejects invalid phone/PAN/Aadhaar inline and clears license expiry date on clear tap',
      (tester) async {
        final env = await createEnv();
        await pumpScreen(tester, env.container, const ProfileEditScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, '9876543210'),
          'call 9876543210',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'ABCDE1234F'),
          'BADPAN',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '123456789012'),
          '12345',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();

        expect(find.text(t.errors.invalidPhone), findsOneWidget);
        expect(find.text(t.errors.invalidPan), findsOneWidget);
        expect(find.text(t.errors.invalidAadhaar), findsOneWidget);

        // Fix inputs and clear DOB date via suffix clear icon.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'call 9876543210'),
          '9876543210',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'BADPAN'),
          'ABCDE1234F',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '12345'),
          '123456789012',
        );
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 800),
        );
        await tester.pumpAndSettle();
        final clearDobBtn = find.byTooltip(t.common.clear).first;
        await tester.ensureVisible(clearDobBtn);
        await tester.pumpAndSettle();
        await tester.tap(clearDobBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text(t.common.confirm));
        await tester.pumpAndSettle();

        final saved = env.container.read(profileControllerProvider).value!;
        expect(saved.dateOfBirth, isNull);
      },
    );
  });

  group('Aadhaar & PAN Masking on CustomerDetailScreen', () {
    testWidgets('masks IDs when preference enabled and reveals on eye tap', (
      tester,
    ) async {
      const customer = Customer(
        id: 'cust-mask',
        name: 'Bruce Wayne',
        aadhaarNumber: '123456789012',
        panNumber: 'ABCDE1234F',
      );
      final env = await createEnv(
        initialPrefs: {'mask_sensitive_ids': true},
        customers: [customer],
      );
      await pumpScreen(
        tester,
        env.container,
        const CustomerDetailScreen(customerId: 'cust-mask'),
      );

      expect(find.text('XXXX XXXX 9012'), findsOneWidget);
      expect(find.text('1234 5678 9012'), findsNothing);
      expect(find.text('XXXXXX234F'), findsOneWidget);
      expect(find.text('ABCDE1234F'), findsNothing);

      final toggleAadhaar = find.byKey(
        ValueKey('toggle_mask_${t.customers.fields.aadhaarNumber}'),
      );
      await tester.ensureVisible(toggleAadhaar);
      await tester.pumpAndSettle();
      await tester.tap(toggleAadhaar);
      await tester.pumpAndSettle();
      expect(find.text('1234 5678 9012'), findsOneWidget);
    });
  });

  group('LoginScreen legal footer', () {
    testWidgets('shows independent disclaimer and Privacy Policy action', (
      tester,
    ) async {
      final env = await createEnv();
      await pumpScreen(tester, env.container, const LoginScreen());

      expect(find.text(t.settings.independentDisclaimer), findsOneWidget);
      expect(find.text(t.settings.privacyPolicy), findsOneWidget);
    });
  });
}

class _RecordingIntentService extends IntentService {
  final List<String> externalUrls = [];
  final List<({String to, String subject, String? body})> supportEmails = [];

  @override
  Future<void> launchExternalUrl(String url) async {
    externalUrls.add(url);
  }

  @override
  Future<void> launchSupportEmail({
    required String to,
    required String subject,
    String? body,
  }) async {
    supportEmails.add((to: to, subject: subject, body: body));
  }
}
