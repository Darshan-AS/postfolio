import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/local_backend_banner.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';
import 'package:postfolio/features/admin/data/admin_repository.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

import 'marketing_frame.dart';
import 'opaque_png.dart';
import 'screenshot_fonts.dart';

const int _totalPhoneSlides = 8;

final DateTime _anchorDate = DateTime(2026, 11, 20);

Future<ProviderContainer> _createSignedInContainer(
  FakeDataSource source,
) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final authRepo = FakeAuthRepository(
    initialUser: const AuthUser(
      id: 'agent-1',
      email: 'agent@postfolio.com',
      displayName: 'Jim Gordon',
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
  required ThemeData theme,
}) {
  final router = container.read(goRouterProvider);
  final effectiveTheme = ScreenshotFonts.applyTo(theme);
  return UncontrolledProviderScope(
    container: container,
    child: TranslationProvider(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: effectiveTheme,
        darkTheme: ScreenshotFonts.applyTo(AppTheme.darkTheme),
        themeMode: ThemeMode.light,
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

Widget _buildStandalonePhone({
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
      home: _StandaloneShellPhone(selectedIndex: selectedIndex, body: body),
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

Future<void> _saveOrVerifyCroppedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<({String relativePath, int cropX, int cropWidth})> slices,
}) async {
  final finder = find.byKey(boundaryKey);
  final boundary = tester.renderObject(finder) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    try {
      for (final slice in slices) {
        final targetPath = slice.relativePath.replaceFirst('../../', '');
        final targetFile = File(targetPath);
        final bytes = await encodeOpaqueRgbPng(
          image,
          cropX: slice.cropX,
          cropWidth: slice.cropWidth,
        );
        if (autoUpdateGoldenFiles) {
          await targetFile.parent.create(recursive: true);
          await targetFile.writeAsBytes(bytes, flush: true);
        } else {
          expect(
            targetFile.existsSync(),
            isTrue,
            reason: 'Missing golden file: $targetPath',
          );
          final expectedBytes = await targetFile.readAsBytes();
          expect(
            bytes,
            equals(expectedBytes),
            reason: 'Golden mismatch for $targetPath',
          );
        }
      }
    } finally {
      image.dispose();
    }
  });
}

Future<void> _pumpPortraitSlide(
  WidgetTester tester, {
  required String route,
  required String badge,
  required String headline,
  required String subtitle,
  required int slideIndex,
  required CaptionPlacement captionPlacement,
  required String outputFile,
  Widget? callout,
  Alignment calloutAlignment = Alignment.bottomLeft,
  ThemeData? theme,
  Brightness statusBarBrightness = Brightness.light,
  Future<void> Function(ProviderContainer container)? afterRouteSettled,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  debugDisableShadows = false;
  try {
    await LocaleSettings.setLocale(AppLocale.en);
    final source = FakeDataSource.forDate(_anchorDate);
    final container = await _createSignedInContainer(source);

    // Render at exact 1080 x 2160 (18:9) via 1.0 DPR + 3x vector FittedBox.
    final targetSize = kPortraitTallSlideLogicalSize * 3.0;
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
              child: PortraitBleedProSlide(
                badge: badge,
                headline: headline,
                subtitle: subtitle,
                slideIndex: slideIndex,
                totalSlides: _totalPhoneSlides,
                captionPlacement: captionPlacement,
                statusBarBrightness: statusBarBrightness,
                callout: callout,
                calloutAlignment: calloutAlignment,
                child: _buildRouterApp(
                  container: container,
                  theme: theme ?? AppTheme.lightTheme,
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

Future<void> _pumpTabletSlide(
  WidgetTester tester, {
  required String route,
  required String badge,
  required String headline,
  required String subtitle,
  required SlideBackdropStyle style,
  required Size screenLogicalSize,
  required String relativeGoldenPath,
  ThemeData? theme,
  Brightness statusBarBrightness = Brightness.light,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  debugDisableShadows = false;
  try {
    await LocaleSettings.setLocale(AppLocale.en);
    final source = FakeDataSource.forDate(_anchorDate);
    final container = await _createSignedInContainer(source);

    // Render at exact 1920 x 1080 physical pixels via 1.0 DPR + 2x vector FittedBox.
    final targetSize = kTabletSlideLogicalSize * 2.0;
    tester.view.physicalSize = targetSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('store_tablet_root'),
          child: SizedBox(
            width: targetSize.width,
            height: targetSize.height,
            child: FittedBox(
              fit: BoxFit.fill,
              child: TabletMarketingSlide(
                badge: badge,
                headline: headline,
                subtitle: subtitle,
                style: style,
                statusBarBrightness: statusBarBrightness,
                screenLogicalSize: screenLogicalSize,
                child: _buildRouterApp(
                  container: container,
                  theme: theme ?? AppTheme.lightTheme,
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

    await _saveOrVerifyGolden(
      tester,
      boundaryKey: const ValueKey('store_tablet_root'),
      relativeGoldenPath: relativeGoldenPath,
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

  group('Play Store portrait phone screenshots (1080x2160)', () {
    testWidgets('01_02_panoramic_hero_pair', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      debugDisableShadows = false;
      try {
        await LocaleSettings.setLocale(AppLocale.en);
        final source = FakeDataSource.forDate(_anchorDate);
        final leftContainer = await _createSignedInContainer(source);
        final rightContainer = await _createSignedInContainer(source);

        // Render two seamless 1080x2160 slides across 2160x2160 @ 1.0 DPR.
        final targetSize = kPanoramicPairLogicalSize * 3.0;
        tester.view.physicalSize = targetSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          TranslationProvider(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(
                key: const ValueKey('store_panoramic_root'),
                child: SizedBox(
                  width: targetSize.width,
                  height: targetSize.height,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: PanoramicSplitHeroSlide(
                      totalSlides: _totalPhoneSlides,
                      leftBadge: 'CUSTOMER 360°',
                      leftHeadline: 'Customers, nominees\n& linked accounts',
                      leftSubtitle:
                          'KYC details, savings accounts & share splits',
                      leftPhone: _buildStandalonePhone(
                        container: leftContainer,
                        theme: AppTheme.lightTheme,
                        selectedIndex: 3,
                        body: const CustomerDetailScreen(
                          customerId: 'demo-cust-bruce',
                        ),
                      ),
                      rightBadge: 'ALL POSTAL SCHEMES',
                      rightHeadline: 'TD, MIS, NSC & KVP\nin one place',
                      rightSubtitle:
                          'Automatic interest & maturity projections',
                      rightPhone: _buildStandalonePhone(
                        container: rightContainer,
                        theme: AppTheme.lightTheme,
                        selectedIndex: 1,
                        body: const OneTimeDepositsScreen(),
                      ),
                      bridgeCallout: const FloatingMetricCallout(
                        eyebrow: 'ALL 4 SCHEMES',
                        value: 'TD · MIS · NSC · KVP',
                        detail: 'Maturity alerts & payout schedules',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _saveOrVerifyCroppedGolden(
          tester,
          boundaryKey: const ValueKey('store_panoramic_root'),
          slices: const [
            (
              relativePath:
                  '../../docs/store_assets/phone_screenshots/01_customer_profile.png',
              cropX: 0,
              cropWidth: 1080,
            ),
            (
              relativePath:
                  '../../docs/store_assets/phone_screenshots/02_one_time_deposits.png',
              cropX: 1080,
              cropWidth: 1080,
            ),
          ],
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
        debugDisableShadows = true;
      }
    });

    testWidgets('03_rd_passbook', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd/demo-rd-clark?tab=schedule',
        badge: 'PASSBOOK & LEDGER',
        headline: 'Month-by-month\nRD passbook',
        subtitle: 'Payments, default fees & Post Office receipts',
        slideIndex: 2,
        captionPlacement: CaptionPlacement.top,
        callout: const FloatingMetricCallout(
          eyebrow: 'LEDGER AUDIT',
          value: '18 installments',
          detail: 'Auto default fees & PO receipts',
        ),
        outputFile: '03_rd_passbook.png',
      );
    });

    testWidgets('04_dashboard', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/dashboard',
        badge: 'PORTFOLIO OVERVIEW',
        headline: 'Your entire book\nin one clean view',
        subtitle: 'Active customers, schemes & deposit trends',
        slideIndex: 3,
        captionPlacement: CaptionPlacement.bottom,
        outputFile: '04_dashboard.png',
      );
    });

    testWidgets('05_monthly_hub', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd?view=hub',
        badge: 'RD MONTHLY HUB',
        headline: 'Every RD due,\nat a glance',
        subtitle: 'To collect, in hand, paid to PO & from pocket',
        slideIndex: 4,
        captionPlacement: CaptionPlacement.top,
        callout: const FloatingMetricCallout(
          eyebrow: 'CASH IN HAND',
          value: '₹29,500 ready',
          detail: '4 accounts ready for Post Office',
        ),
        outputFile: '05_monthly_hub.png',
      );
    });

    testWidgets('06_rd_transactions_po_deposits', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd/demo-rd-clark?tab=transactions',
        badge: 'PASSBOOK & PO DEPOSITS',
        headline: 'Every customer payment\n& PO visit in sync',
        subtitle: 'Track installments, cash vs digital & PO deposit receipts',
        slideIndex: 5,
        captionPlacement: CaptionPlacement.bottom,
        outputFile: '06_rd_transactions_po_deposits.png',
      );
    });

    testWidgets('07_collect_payment_dark', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/rd?view=hub',
        badge: '1-TAP COLLECTION · DARK',
        headline: 'Log payments &\nfees in seconds',
        subtitle: 'Quick amounts, Cash/UPI/Bank & Dark Mode',
        slideIndex: 6,
        captionPlacement: CaptionPlacement.top,
        theme: AppTheme.darkTheme,
        statusBarBrightness: Brightness.dark,
        outputFile: '07_collect_payment_dark.png',
        afterRouteSettled: (_) async {
          final context = tester.element(find.byType(RecurringDepositsScreen));
          // Open the collect payment sheet for an overdue account in dark theme.
          // ignore: unawaited_futures
          showRDLogPaymentSheet(context, rdId: 'demo-rd-arthur');
        },
      );
    });

    testWidgets('08_otd_projection_accessible', (tester) async {
      await _pumpPortraitSlide(
        tester,
        route: '/deposits/demo-otd-bruce-mis',
        badge: 'PROJECTIONS · HIGH CONTRAST',
        headline: 'Clear payouts for\nevery investor',
        subtitle: 'MIS monthly income & color-blind safe theme',
        slideIndex: 7,
        captionPlacement: CaptionPlacement.bottom,
        theme: AppTheme.accessibleLightTheme,
        statusBarBrightness: Brightness.light,
        outputFile: '08_otd_projection_accessible.png',
      );
    });
  });

  group('Play Store 7-inch tablet screenshots (1920x1080)', () {
    const tablet7Viewport = Size(960, 600);

    testWidgets('01_tablet7_monthly_hub', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/rd?view=hub',
        badge: '7-INCH TABLET',
        headline: 'Monthly Hub with Navigation Rail',
        subtitle: 'Roomy collection ledger built for larger screens',
        style: SlideBackdropStyle.royalBlue,
        screenLogicalSize: tablet7Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_7_screenshots/01_tablet7_monthly_hub.png',
      );
    });

    testWidgets('02_tablet7_one_time_deposits', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/deposits',
        badge: 'ALL POSTAL SCHEMES',
        headline: 'TD, MIS, NSC & KVP Directory',
        subtitle: 'Track maturities & payout schedules on 7-inch tablets',
        style: SlideBackdropStyle.softIce,
        screenLogicalSize: tablet7Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_7_screenshots/02_tablet7_one_time_deposits.png',
      );
    });

    testWidgets('03_tablet7_customer_profile', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/customers/demo-cust-bruce',
        badge: 'CUSTOMER 360°',
        headline: 'KYC, Nominees & Savings Profiles',
        subtitle: 'Complete customer records in a responsive split workspace',
        style: SlideBackdropStyle.royalBlue,
        screenLogicalSize: tablet7Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_7_screenshots/03_tablet7_customer_profile.png',
      );
    });

    testWidgets('04_tablet7_dashboard_dark', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/dashboard',
        badge: 'TABLET DARK THEME',
        headline: 'Portfolio Overview at a Glance',
        subtitle: 'Scheme counts, FY deposit trends & responsive rail',
        style: SlideBackdropStyle.midnight,
        theme: AppTheme.darkTheme,
        statusBarBrightness: Brightness.dark,
        screenLogicalSize: tablet7Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_7_screenshots/04_tablet7_dashboard_dark.png',
      );
    });
  });

  group('Play Store 10-inch tablet screenshots (1920x1080)', () {
    const tablet10Viewport = kPixelTabletScreenSize;

    testWidgets('01_tablet10_monthly_hub', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/rd?view=hub',
        badge: '10-INCH TABLET',
        headline: 'Full Portfolio Workspace',
        subtitle: 'Track installments, cash in hand & arrears side by side',
        style: SlideBackdropStyle.royalBlue,
        screenLogicalSize: tablet10Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_10_screenshots/01_tablet10_monthly_hub.png',
      );
    });

    testWidgets('02_tablet10_one_time_deposits', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/deposits',
        badge: 'ALL POSTAL SCHEMES',
        headline: 'TD, MIS, NSC & KVP Directory',
        subtitle: 'Maturity alerts & scheme filtering on 10-inch displays',
        style: SlideBackdropStyle.softIce,
        screenLogicalSize: tablet10Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_10_screenshots/02_tablet10_one_time_deposits.png',
      );
    });

    testWidgets('03_tablet10_rd_passbook', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/rd/demo-rd-clark?tab=schedule',
        badge: 'PASSBOOK & LEDGER',
        headline: 'Detailed RD Schedule & Receipts',
        subtitle: 'Month-by-month installments, default fees & audit trail',
        style: SlideBackdropStyle.royalBlue,
        screenLogicalSize: tablet10Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_10_screenshots/03_tablet10_rd_passbook.png',
      );
    });

    testWidgets('04_tablet10_dashboard_dark', (tester) async {
      await _pumpTabletSlide(
        tester,
        route: '/dashboard',
        badge: '10-INCH DARK THEME',
        headline: 'Portfolio Analytics in Dark Mode',
        subtitle: 'Active holdings, trends & multi-column executive layout',
        style: SlideBackdropStyle.midnight,
        theme: AppTheme.darkTheme,
        statusBarBrightness: Brightness.dark,
        screenLogicalSize: tablet10Viewport,
        relativeGoldenPath:
            '../../docs/store_assets/tablet_10_screenshots/04_tablet10_dashboard_dark.png',
      );
    });
  });

  group('Play Store Feature Graphic (1024x500)', () {
    testWidgets('feature_graphic_1024x500', (tester) async {
      debugDisableShadows = false;
      try {
        final targetSize = kFeatureGraphicLogicalSize * 2.0;
        tester.view.physicalSize = targetSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: const ValueKey('store_feature_graphic_root'),
              child: SizedBox(
                width: targetSize.width,
                height: targetSize.height,
                child: const FittedBox(
                  fit: BoxFit.fill,
                  child: FeatureGraphicBanner(),
                ),
              ),
            ),
          ),
        );

        await tester.runAsync(() async {
          final element = tester.element(find.byType(FeatureGraphicBanner));
          await precacheImage(
            const AssetImage('assets/branding/app_icon.png'),
            element,
          );
        });
        await tester.pumpAndSettle();

        await _saveOrVerifyGolden(
          tester,
          boundaryKey: const ValueKey('store_feature_graphic_root'),
          relativeGoldenPath:
              '../../docs/store_assets/feature_graphic_1024x500.png',
        );
      } finally {
        debugDisableShadows = true;
      }
    });
  });

  group('Play Store landscape hero (1920x1080)', () {
    testWidgets('01_overview_landscape', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      debugDisableShadows = false;
      try {
        await LocaleSettings.setLocale(AppLocale.en);
        final source = FakeDataSource.forDate(_anchorDate);
        final lightContainer = await _createSignedInContainer(source);
        final darkContainer = await _createSignedInContainer(source);

        // Render at exact 1920 x 1080 physical pixels via 1.0 DPR + 3x vector FittedBox.
        final targetSize = kLandscapeSlideLogicalSize * 3.0;
        tester.view.physicalSize = targetSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

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
                      primaryPhone: _buildStandalonePhone(
                        container: lightContainer,
                        theme: AppTheme.lightTheme,
                        selectedIndex: 2,
                        body: const RecurringDepositsScreen(initialView: 'hub'),
                      ),
                      secondaryPhone: _buildStandalonePhone(
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
