import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/widgets/common/local_backend_banner.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

import 'marketing_frame.dart';
import 'opaque_png.dart';
import 'screenshot_fonts.dart';

final DateTime _anchorDate = DateTime(2026, 11, 20);

Future<ProviderContainer> _createSignedInContainer(
  FakeDataSource source,
  WidgetTester tester,
) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final authRepo = FakeAuthRepository(
    initialUser: const AuthUser(
      id: 'agent-1',
      email: 'agent@postfolio.com',
      displayName: 'Agent',
    ),
  );
  final rdRepo = FakeRecurringDepositRepository(
    deposits: source.recurringDeposits,
  );
  final ledgerRepo = FakeRDLedgerRepository(
    transactions: source.rdTransactions,
    poDeposits: source.rdPoDeposits,
    absorptions: source.rdFeeAbsorptions,
  );
  final cleanCustomers = [
    for (final customer in source.customers) customer.copyWith(notes: null),
  ];
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => _anchorDate),
      authRepositoryProvider.overrideWithValue(authRepo),
      adminRepositoryProvider.overrideWithValue(
        FakeAdminRepository(isAdmin: false),
      ),
      localBackendBannerVisibleProvider.overrideWithValue(false),
      customerRepositoryProvider.overrideWithValue(
        FakeCustomerRepository(customers: cleanCustomers, delay: Duration.zero),
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
  addTearDown(() {
    authRepo.dispose();
    rdRepo.dispose();
    ledgerRepo.dispose();
    container.dispose();
  });
  return container;
}

Widget _buildRouterApp({
  required ProviderContainer container,
  required Brightness brightness,
}) {
  final router = container.read(goRouterProvider);
  final theme = ScreenshotFonts.applyTo(
    brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
  );
  return UncontrolledProviderScope(
    container: container,
    child: TranslationProvider(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: ScreenshotFonts.applyTo(AppTheme.darkTheme),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) {
          final scheme = Theme.of(context).colorScheme;
          return SkeletonizerConfig(
            data: AppTheme.skeletonizerConfig(scheme),
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocaleUtils.supportedLocales,
      ),
    ),
  );
}

Future<void> _saveOrVerifyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required String relativeGoldenPath,
}) async {
  final finder = find.byKey(boundaryKey);
  await expectLater(finder, matchesGoldenFile(relativeGoldenPath));

  if (autoUpdateGoldenFiles) {
    final boundary = tester.renderObject(finder) as RenderRepaintBoundary;
    final targetPath = relativeGoldenPath.replaceFirst('../../', '');
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      try {
        await writeOpaqueRgbPng(File(targetPath), image);
      } finally {
        image.dispose();
      }
    });
  }
}

Future<void> _pumpPortraitSlide(
  WidgetTester tester, {
  required String route,
  required String badge,
  required String headline,
  required String subtitle,
  required SlideBackdropStyle style,
  required String outputFile,
  Brightness brightness = Brightness.light,
  Future<void> Function(ProviderContainer container)? afterRouteSettled,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  debugDisableShadows = false;
  try {
    await LocaleSettings.setLocale(AppLocale.en);
    final source = FakeDataSource.forDate(_anchorDate);
    final container = await _createSignedInContainer(source, tester);

    // Render at exact 1080 x 1920 physical pixels via 1.0 DPR + 3x vector FittedBox.
    final targetSize = kPortraitSlideLogicalSize * 3.0;
    tester.view.physicalSize = targetSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('store_slide_root'),
          child: SizedBox(
            width: targetSize.width,
            height: targetSize.height,
            child: FittedBox(
              fit: BoxFit.fill,
              child: PortraitMarketingSlide(
                badge: badge,
                headline: headline,
                subtitle: subtitle,
                style: style,
                statusBarBrightness: brightness,
                child: _buildRouterApp(
                  container: container,
                  brightness: brightness,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(route);
    await tester.pumpAndSettle();

    if (afterRouteSettled != null) {
      await afterRouteSettled(container);
      await tester.pumpAndSettle();
    }

    await _saveOrVerifyGolden(
      tester,
      boundaryKey: const ValueKey('store_slide_root'),
      relativeGoldenPath:
          '../../docs/store_assets/phone_screenshots/$outputFile',
    );
  } finally {
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }
}

class _StandaloneShellPhone extends ConsumerWidget {
  const _StandaloneShellPhone({
    required this.selectedIndex,
    required this.body,
  });

  final int selectedIndex;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrears = ref.watch(
      globalAgentFloatProvider.select((float) => float.arrearsAccounts),
    );
    final destinations = [
      AppDestination(
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        label: t.nav.dashboard,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
        label: t.nav.oneTimeDeposits,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedTransaction,
        label: t.nav.recurringDeposits,
        badgeCount: arrears > 0 ? arrears : null,
        badgeSemanticLabel: arrears > 0
            ? t.nav.recurringDepositsInArrears(n: arrears)
            : null,
      ),
      AppDestination(
        icon: HugeIcons.strokeRoundedUserMultiple,
        label: t.nav.customers,
      ),
    ];

    return Scaffold(
      body: body,
      bottomNavigationBar: AppNavigationBar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: (_) {},
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ScreenshotFonts.ensureLoaded();
  });

  group('Play Store portrait screenshots (1080x1920)', () {
    testWidgets('01_monthly_hub', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd?view=hub',
        badge: 'RD MONTHLY HUB',
        headline: 'Every RD due,\nat a glance',
        subtitle: 'Settled, in-hand, overdue & fronted accounts',
        style: SlideBackdropStyle.royalBlue,
        outputFile: '01_monthly_hub.png',
      );
    });

    testWidgets('02_dashboard', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/dashboard',
        badge: 'PORTFOLIO OVERVIEW',
        headline: 'Your entire book\nin one clean view',
        subtitle: 'Active customers, schemes & deposit trends',
        style: SlideBackdropStyle.softIce,
        outputFile: '02_dashboard.png',
        afterRouteSettled: (_) async {
          final scrollView = find.descendant(
            of: find.byType(DashboardScreen),
            matching: find.byType(Scrollable),
          );
          if (scrollView.evaluate().isNotEmpty) {
            tester
                .state<ScrollableState>(scrollView.first)
                .position
                .jumpTo(220);
          }
        },
      );
    });

    testWidgets('03_po_visit_planner', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd?view=hub',
        badge: 'BATCH PO VISITS',
        headline: 'Plan Post Office\ndeposit lots easily',
        subtitle: 'Cash & UPI totals, counter fees & ₹20k lot splits',
        style: SlideBackdropStyle.royalBlue,
        outputFile: '03_po_visit_planner.png',
        afterRouteSettled: (container) async {
          container.read(rDPoVisitPlannerProvider.notifier).start();
          final context = tester.element(find.byType(RecurringDepositsScreen));
          // Open the modal bottom sheet without awaiting dismissal.
          // ignore: unawaited_futures
          showRDPoVisitPlanner(context);
        },
      );
    });

    testWidgets('04_rd_passbook', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd/demo-rd-jayant?tab=schedule',
        badge: 'PASSBOOK & LEDGER',
        headline: 'Month-by-month\nRD passbook',
        subtitle: 'Payments, default fees & Post Office receipts',
        style: SlideBackdropStyle.softIce,
        outputFile: '04_rd_passbook.png',
      );
    });

    testWidgets('05_one_time_deposits', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/deposits',
        badge: 'ALL POSTAL SCHEMES',
        headline: 'TD, MIS, NSC & KVP\nin one place',
        subtitle: 'Automatic interest & maturity projections',
        style: SlideBackdropStyle.royalBlue,
        outputFile: '05_one_time_deposits.png',
      );
    });

    testWidgets('06_customer_profile', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/customers/demo-cust-ramesh',
        badge: 'CUSTOMER 360°',
        headline: 'Customers, nominees\n& linked accounts',
        subtitle: 'KYC details, savings accounts & share splits',
        style: SlideBackdropStyle.softIce,
        outputFile: '06_customer_profile.png',
        afterRouteSettled: (_) async {
          final scrollables = find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          );
          if (scrollables.evaluate().isNotEmpty) {
            tester
                .state<ScrollableState>(scrollables.first)
                .position
                .jumpTo(520);
          }
        },
      );
    });

    testWidgets('07_dark_mode', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd?view=hub',
        badge: 'MATERIAL 3 EXPRESSIVE',
        headline: 'Designed for focus,\nday or night',
        subtitle: 'Light, Dark & High-Contrast accessible themes',
        style: SlideBackdropStyle.midnight,
        brightness: Brightness.dark,
        outputFile: '07_dark_mode.png',
      );
    });
  });

  group('Play Store landscape screenshot (1920x1080)', () {
    testWidgets('01_overview_landscape', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      debugDisableShadows = false;
      try {
        await LocaleSettings.setLocale(AppLocale.en);
        final source = FakeDataSource.forDate(_anchorDate);
        final lightContainer = await _createSignedInContainer(source, tester);
        final darkContainer = await _createSignedInContainer(source, tester);

        // Render at exact 1920 x 1080 physical pixels via 1.0 DPR + 3x vector FittedBox.
        final targetSize = kLandscapeSlideLogicalSize * 3.0;
        tester.view.physicalSize = targetSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        Widget buildStandalonePhone({
          required ProviderContainer container,
          required ThemeData theme,
          required int selectedIndex,
          required Widget body,
        }) {
          final effectiveTheme = ScreenshotFonts.applyTo(theme);
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: effectiveTheme,
              builder: (context, child) => SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(
                  Theme.of(context).colorScheme,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocaleUtils.supportedLocales,
              home: _StandaloneShellPhone(
                selectedIndex: selectedIndex,
                body: body,
              ),
            ),
          );
        }

        await tester.pumpWidget(
          TranslationProvider(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(
                key: const ValueKey('store_landscape_root'),
                child: SizedBox(
                  width: targetSize.width,
                  height: targetSize.height,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: LandscapeMarketingSlide(
                      primaryPhone: buildStandalonePhone(
                        container: lightContainer,
                        theme: AppTheme.lightTheme,
                        selectedIndex: 2,
                        body: const RecurringDepositsScreen(initialView: 'hub'),
                      ),
                      secondaryPhone: buildStandalonePhone(
                        container: darkContainer,
                        theme: AppTheme.darkTheme,
                        selectedIndex: 0,
                        body: const DashboardScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.runAsync(() async {
          final element = tester.element(find.byType(LandscapeMarketingSlide));
          await precacheImage(
            const AssetImage('assets/branding/app_icon.png'),
            element,
          );
        });
        await tester.pumpAndSettle();

        await _saveOrVerifyGolden(
          tester,
          boundaryKey: const ValueKey('store_landscape_root'),
          relativeGoldenPath:
              '../../docs/store_assets/landscape_screenshots/01_overview_landscape.png',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
        debugDisableShadows = true;
      }
    });
  });
}
