import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/admin/presentation/widgets/acting_as_banner.dart';
import 'package:postfolio/features/admin/presentation/widgets/admin_agent_picker_sheet.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/profile/presentation/screens/profile_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projector.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  const adminUser = AuthUser(
    id: 'admin-1',
    email: 'admin@postfolio.dev',
    displayName: 'Admin User',
  );
  const adminProfile = AgentProfile(
    id: 'admin-1',
    name: 'Admin User',
    email: 'admin@postfolio.dev',
    agencyCode: 'AG-0001',
  );
  const targetAgentA = AgentProfile(
    id: 'agent-a',
    name: 'Meera Nair',
    email: 'meera@postfolio.dev',
    agencyCode: 'AG-1042',
  );
  const targetAgentB = AgentProfile(
    id: 'agent-b',
    name: 'Vikram Joshi',
    email: 'vikram@postfolio.dev',
    agencyCode: 'AG-2088',
  );

  final source = FakeDataSource();

  Future<({ProviderContainer container, FakeAdminRepository adminRepo})>
  createContainer({
    bool isAdmin = true,
    bool demoMode = false,
    List<AgentProfile> agents = const [
      adminProfile,
      targetAgentA,
      targetAgentB,
    ],
    String? listAgentsError,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (demoMode) 'demo_mode_enabled': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository(initialUser: adminUser);
    final adminRepo = FakeAdminRepository(
      isAdmin: isAdmin,
      agents: agents,
      listAgentsError: listAgentsError,
    );
    final rdRepo = FakeRecurringDepositRepository(
      deposits: source.recurringDeposits,
    );
    final ledgerRepo = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
    );
    await ledgerRepo.upsertSummaries([
      for (final rd in source.recurringDeposits)
        RDLedgerProjector.standard
            .project(
              RDLedgerFacts(
                deposit: rd,
                transactions: source.rdTransactions[rd.id] ?? const [],
                poDeposits: source.rdPoDeposits[rd.id] ?? const [],
              ),
              asOf: DateTime(2026, 4, 20),
            )
            .summary,
    ]);
    addTearDown(() {
      authRepo.dispose();
      rdRepo.dispose();
      ledgerRepo.dispose();
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
        adminRepositoryProvider.overrideWithValue(adminRepo),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(
            customers: source.customers,
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
    return (container: container, adminRepo: adminRepo);
  }

  Future<void> pumpWidgetUnderTest(
    WidgetTester tester,
    ProviderContainer container,
    Widget home, {
    Size size = const Size(360, 800),
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: SkeletonizerConfig(
                  data: AppTheme.skeletonizerConfig(
                    Theme.of(context).colorScheme,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: home,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  Future<void> pumpRouterApp(
    WidgetTester tester,
    ProviderContainer container, {
    Size size = const Size(412, 915),
    double textScale = 1.0,
    ThemeData? theme,
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
            theme: theme ?? AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) {
              final scheme = Theme.of(context).colorScheme;
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: SkeletonizerConfig(
                  data: AppTheme.skeletonizerConfig(scheme),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isActingAs = ref.watch(
                        actingAsControllerProvider.select((s) => s.isActingAs),
                      );
                      final body = child ?? const SizedBox.shrink();
                      return Column(
                        children: [
                          const ActingAsBanner(),
                          Expanded(
                            child: MediaQuery.removePadding(
                              context: context,
                              removeTop: isActingAs,
                              child: body,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
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
    expect(tester.takeException(), isNull);
  }

  void expectAccessibleIconButtons(WidgetTester tester) {
    for (final element in find.byType(IconButton).evaluate()) {
      final widget = element.widget as IconButton;
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;
      expect(
        widget.tooltip?.trim().isNotEmpty ?? false,
        isTrue,
        reason: 'IconButton without tooltip: $widget',
      );
      expect(
        renderBox.size.width,
        greaterThanOrEqualTo(AppDimensions.minTapTarget),
      );
      expect(
        renderBox.size.height,
        greaterThanOrEqualTo(AppDimensions.minTapTarget),
      );
    }
  }

  group('ActingAsBanner', () {
    testWidgets('renders nothing when not acting as another agent', (
      tester,
    ) async {
      final env = await createContainer();
      await pumpWidgetUnderTest(
        tester,
        env.container,
        const Scaffold(body: Column(children: [ActingAsBanner()])),
      );
      expect(find.byKey(const ValueKey('acting_as_banner')), findsNothing);
    });

    testWidgets(
      'displays warning banner with status bar style and exits cleanly',
      (tester) async {
        final env = await createContainer();
        await env.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(targetAgentA);

        await pumpWidgetUnderTest(
          tester,
          env.container,
          const Scaffold(body: Column(children: [ActingAsBanner()])),
        );

        final scheme = AppTheme.lightTheme.colorScheme;
        final bannerFinder = find.byKey(const ValueKey('acting_as_banner'));
        expect(bannerFinder, findsOneWidget);
        expect(
          tester.widget<MaterialBanner>(bannerFinder).backgroundColor,
          scheme.errorContainer,
        );
        expect(
          find.text(t.admin.actingAs(name: targetAgentA.displayLabel)),
          findsOneWidget,
        );
        expect(find.text(t.admin.exitActingAs), findsOneWidget);
        expect(
          SystemChrome.latestStyle?.statusBarIconBrightness,
          Brightness.dark,
        );

        // Tap Exit -> clears acting-as state and logs end.
        await tester.tap(find.byKey(const ValueKey('acting_as_exit_button')));
        await tester.pumpAndSettle();
        expect(
          env.container.read(actingAsControllerProvider).isActingAs,
          isFalse,
        );
        expect(find.byKey(const ValueKey('acting_as_banner')), findsNothing);
        expect(env.adminRepo.loggedEvents.last, (
          targetAgentId: targetAgentA.id,
          action: ActingAsAuditAction.end,
        ));
      },
    );

    testWidgets(
      'stays visible from MaterialApp.router.builder over pushed detail routes and Exit routes to /dashboard',
      (tester) async {
        final env = await createContainer();
        await env.container
            .read(actingAsControllerProvider.notifier)
            .startActingAs(targetAgentA);

        await pumpRouterApp(tester, env.container);

        // Push a detail screen on the root navigator; banner stays visible above it.
        final router = env.container.read(goRouterProvider);
        unawaited(
          router.push(CustomerDetailRoute(source.customers.first.id).location),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('acting_as_banner')), findsOneWidget);

        // Tapping Exit clears acting-as and navigates to DashboardRoute.
        await tester.tap(find.byKey(const ValueKey('acting_as_exit_button')));
        await tester.pumpAndSettle();
        expect(
          env.container.read(actingAsControllerProvider).isActingAs,
          isFalse,
        );
        expect(router.state.uri.path, const DashboardRoute().location);
      },
    );

    testWidgets('has 0 overflows at 360x800 @ 2.0x text scale', (tester) async {
      final env = await createContainer();
      await env.container
          .read(actingAsControllerProvider.notifier)
          .startActingAs(targetAgentA);

      await pumpWidgetUnderTest(
        tester,
        env.container,
        const Scaffold(body: Column(children: [ActingAsBanner()])),
        size: const Size(360, 800),
        textScale: 2.0,
      );
      expect(find.byKey(const ValueKey('acting_as_banner')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdminAgentPickerSheet', () {
    testWidgets(
      'lists agents with badges, filters by name/email/code, selects target and returns to own account',
      (tester) async {
        final env = await createContainer();
        await pumpWidgetUnderTest(
          tester,
          env.container,
          const Scaffold(body: AdminAgentPickerSheet()),
          size: const Size(360, 800),
        );

        expect(find.text(t.admin.pickerTitle), findsOneWidget);
        expect(find.text(adminProfile.displayLabel), findsOneWidget);
        expect(find.text(targetAgentA.displayLabel), findsOneWidget);
        expect(find.text(targetAgentB.displayLabel), findsOneWidget);
        expect(find.text(t.admin.yourAccountBadge), findsOneWidget);
        expect(find.text(t.admin.currentAccountBadge), findsOneWidget);

        // Search by agency code.
        await tester.enterText(find.byType(SearchBar), 'AG-2088');
        await tester.pump(
          AppMotion.debounce + const Duration(milliseconds: 50),
        );
        await tester.pumpAndSettle();

        expect(find.text(targetAgentB.displayLabel), findsOneWidget);
        expect(find.text(targetAgentA.displayLabel), findsNothing);

        // Search with no matches -> no-results empty state + clear filters.
        await tester.enterText(find.byType(SearchBar), 'nonexistent-xyz');
        await tester.pump(
          AppMotion.debounce + const Duration(milliseconds: 50),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.common.noResults), findsOneWidget);

        await tester.tap(find.text(t.common.clearFilters));
        await tester.pumpAndSettle();
        expect(find.text(targetAgentA.displayLabel), findsOneWidget);

        // Select Meera Nair -> starts acting-as immediately with full CRUD.
        await tester.tap(find.text(targetAgentA.displayLabel));
        await tester.pumpAndSettle();
        expect(
          env.container.read(actingAsControllerProvider),
          const ActingAsState.active(targetAgent: targetAgentA),
        );
      },
    );

    testWidgets(
      'renders cleanly at 360x800 @ 2.0x text scale with accessible icon buttons',
      (tester) async {
        final env = await createContainer();
        await pumpWidgetUnderTest(
          tester,
          env.container,
          const Scaffold(body: AdminAgentPickerSheet()),
          size: const Size(360, 800),
          textScale: 2.0,
        );
        expect(find.text(targetAgentA.displayLabel), findsOneWidget);
        expectAccessibleIconButtons(tester);
      },
    );

    testWidgets('shows error view when agent loading fails', (tester) async {
      final errorEnv = await createContainer(
        listAgentsError: 'Backend temporarily unavailable',
      );
      await pumpWidgetUnderTest(
        tester,
        errorEnv.container,
        const Scaffold(body: AdminAgentPickerSheet()),
      );
      expect(find.text('Backend temporarily unavailable'), findsOneWidget);
    });

    testWidgets('shows empty state when no other agents exist', (tester) async {
      final emptyEnv = await createContainer(agents: const [adminProfile]);
      await pumpWidgetUnderTest(
        tester,
        emptyEnv.container,
        const Scaffold(body: AdminAgentPickerSheet()),
      );
      expect(find.text(t.admin.noOtherAgents), findsOneWidget);
    });

    testWidgets(
      'hoists own account first while strictly preserving backend order across >32 agents',
      (tester) async {
        final manyAgents = <AgentProfile>[
          for (var i = 0; i < 20; i++)
            AgentProfile(
              id: 'agent-${i.toString().padLeft(2, '0')}',
              name: 'Agent ${i.toString().padLeft(2, '0')}',
              email: 'a$i@postfolio.dev',
            ),
          adminProfile,
          for (var i = 20; i < 40; i++)
            AgentProfile(
              id: 'agent-${i.toString().padLeft(2, '0')}',
              name: 'Agent ${i.toString().padLeft(2, '0')}',
              email: 'a$i@postfolio.dev',
            ),
        ];
        final env = await createContainer(agents: manyAgents);
        await pumpWidgetUnderTest(
          tester,
          env.container,
          const Scaffold(body: AdminAgentPickerSheet()),
          size: const Size(360, 1200),
        );

        // Admin is hoisted to top, followed by Agent 00, Agent 01, Agent 02 in exact order.
        final adminTop = tester
            .getTopLeft(find.text(adminProfile.displayLabel))
            .dy;
        final a0Top = tester.getTopLeft(find.text('Agent 00')).dy;
        final a1Top = tester.getTopLeft(find.text('Agent 01')).dy;
        final a2Top = tester.getTopLeft(find.text('Agent 02')).dy;
        expect(adminTop, lessThan(a0Top));
        expect(a0Top, lessThan(a1Top));
        expect(a1Top, lessThan(a2Top));
      },
    );
  });

  group('Admin Switch Account Trigger Visibility', () {
    testWidgets(
      'mobile ProfileScreen shows Switch Account for admins and opens picker sheet',
      (tester) async {
        final adminEnv = await createContainer(isAdmin: true, demoMode: false);
        await pumpWidgetUnderTest(
          tester,
          adminEnv.container,
          const ProfileScreen(),
          size: const Size(360, 800),
        );
        final switchBtn = find.byKey(
          const ValueKey('admin_switch_account_button'),
        );
        expect(switchBtn, findsOneWidget);
        expectAccessibleIconButtons(tester);

        await tester.ensureVisible(switchBtn);
        await tester.pumpAndSettle();
        await tester.tap(switchBtn);
        await tester.pumpAndSettle();
        expect(find.byType(AdminAgentPickerSheet), findsOneWidget);
      },
    );

    testWidgets(
      'mobile ProfileScreen hides Switch Account for non-admin agents',
      (tester) async {
        final agentEnv = await createContainer(isAdmin: false, demoMode: false);
        await pumpWidgetUnderTest(
          tester,
          agentEnv.container,
          const ProfileScreen(),
          size: const Size(360, 800),
        );
        expect(
          find.byKey(const ValueKey('admin_switch_account_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'mobile ProfileScreen hides Switch Account for admins in Demo Mode',
      (tester) async {
        final demoEnv = await createContainer(isAdmin: true, demoMode: true);
        await pumpWidgetUnderTest(
          tester,
          demoEnv.container,
          const ProfileScreen(),
          size: const Size(360, 800),
        );
        expect(
          find.byKey(const ValueKey('admin_switch_account_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'desktop avatar opens ProfileScreen showing Switch Account for admins and opens picker dialog',
      (tester) async {
        final adminEnv = await createContainer(isAdmin: true, demoMode: false);
        await pumpRouterApp(
          tester,
          adminEnv.container,
          size: const Size(1280, 800),
        );
        await tester.tap(
          find.byKey(const ValueKey('shell_account_avatar_button')).first,
        );
        await tester.pumpAndSettle();

        final switchBtn = find.byKey(
          const ValueKey('admin_switch_account_button'),
        );
        expect(switchBtn, findsOneWidget);
        expectAccessibleIconButtons(tester);

        // Tapping opens AdminAgentPickerSheet as a dialog; selecting an agent switches & routes to /dashboard.
        await tester.ensureVisible(switchBtn);
        await tester.pumpAndSettle();
        await tester.tap(switchBtn);
        await tester.pumpAndSettle();
        expect(find.byType(AdminAgentPickerSheet), findsOneWidget);
        await tester.tap(find.text(targetAgentA.displayLabel));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('acting_as_banner')), findsOneWidget);
      },
    );

    testWidgets(
      'desktop ProfileScreen hides Switch Account for non-admin agents',
      (tester) async {
        final agentEnv = await createContainer(isAdmin: false, demoMode: false);
        await pumpRouterApp(
          tester,
          agentEnv.container,
          size: const Size(1280, 800),
        );
        await tester.tap(
          find.byKey(const ValueKey('shell_account_avatar_button')).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('admin_switch_account_button')),
          findsNothing,
        );
      },
    );

    testWidgets('desktop ProfileScreen hides Switch Account in Demo Mode', (
      tester,
    ) async {
      final demoEnv = await createContainer(isAdmin: true, demoMode: true);
      await pumpRouterApp(
        tester,
        demoEnv.container,
        size: const Size(1280, 800),
      );
      await tester.tap(
        find.byKey(const ValueKey('shell_account_avatar_button')).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin_switch_account_button')),
        findsNothing,
      );
    });

    testWidgets(
      'ProfileScreen pull-to-refresh re-checks isAdminProvider and reveals Switch Account',
      (tester) async {
        final env = await createContainer(isAdmin: false, demoMode: false);
        await pumpWidgetUnderTest(
          tester,
          env.container,
          const ProfileScreen(),
          size: const Size(360, 800),
        );
        expect(
          find.byKey(const ValueKey('admin_switch_account_button')),
          findsNothing,
        );

        // Simulate admin role granted after initial load, then pull to refresh.
        env.adminRepo.isAdmin = true;
        await tester.fling(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 400),
          1000,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('admin_switch_account_button')),
          findsOneWidget,
        );
      },
    );
  });
}
