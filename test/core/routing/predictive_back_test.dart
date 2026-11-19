import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android's predictive back, driven the way the engine drives it: `flutter/backgesture`
/// messages for the swipe, and `SystemNavigator.setFrameworkHandlesBack` to tell Android
/// whether the app or the system (back-to-home) answers the next swipe.
void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('the Android manifest opts the app in to predictive back', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    // Without the flag, Android 13 to 15 send a plain back key and never the gesture.
    // From Android 16 an app that targets API 36 is opted in by default.
    expect(
      RegExp(
        r'<application\b[^>]*android:enableOnBackInvokedCallback="true"',
      ).hasMatch(manifest),
      isTrue,
    );
  });

  group('Predictive back through the router', () {
    Future<({_Router router, List<bool> handlesBack})> pumpSignedIn(
      WidgetTester tester,
    ) async {
      final authRepo = FakeAuthRepository(
        initialUser: const AuthUser(
          id: 'agent-1',
          email: 'agent@postfolio.com',
          displayName: 'Agent',
        ),
      );
      final rdRepo = FakeRecurringDepositRepository(deposits: const []);
      final ledgerRepo = FakeRDLedgerRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
          authRepositoryProvider.overrideWithValue(authRepo),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(
              customers: const [
                Customer(id: 'cust-1', name: 'Ramesh Rao', phone: '9876543210'),
              ],
              delay: Duration.zero,
            ),
          ),
          oneTimeDepositRepositoryProvider.overrideWithValue(
            FakeOneTimeDepositRepository(
              deposits: const [],
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

      final handlesBack = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            handlesBack.add(call.arguments as bool);
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

      // A phone: sheets are bottom sheets and the destinations sit in a bottom bar.
      tester.view.physicalSize = const Size(412, 915) * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      // The framework reports to Android only once the app is in the foreground.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      final router = container.read(goRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
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
      return (
        router: (
          location: () => router.state.uri.toString(),
          root: () => router.configuration.navigatorKey.currentState!,
        ),
        handlesBack: handlesBack,
      );
    }

    Future<void> openCustomer(WidgetTester tester) async {
      await tester.tap(find.text('Ramesh Rao'));
      await tester.pumpAndSettle();
      expect(find.byType(CustomerDetailScreen), findsOneWidget);
    }

    testWidgets('a swipe on a detail screen shows the list and a release goes back', (
      tester,
    ) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);
      expect(router.location(), '/customers');
      // At a tab's root the system answers the swipe with its back-to-home animation.
      expect(handlesBack.last, isFalse);

      await openCustomer(tester);
      expect(router.location(), '/customers/cust-1');
      expect(handlesBack.last, isTrue);

      await _sendBack(tester, 'startBackGesture', _swipe(0));
      await tester.pump();
      await _sendBack(tester, 'updateBackGestureProgress', _swipe(0.6));
      await tester.pump();

      // The detail screen follows the finger: the route is mid-gesture, not popped yet.
      expect(router.root().userGestureInProgress, isTrue);
      expect(find.byType(CustomerDetailScreen), findsOneWidget);
      expect(router.location(), '/customers/cust-1');

      await _sendBack(tester, 'commitBackGesture');
      await tester.pumpAndSettle();

      expect(router.root().userGestureInProgress, isFalse);
      expect(find.byType(CustomerDetailScreen), findsNothing);
      expect(router.location(), '/customers');
      expect(handlesBack.last, isFalse);

      // The list is live again, not a frozen snapshot of the transition.
      await openCustomer(tester);
      expect(router.location(), '/customers/cust-1');
    });

    testWidgets('a swipe that is dragged back to the edge stays on the detail screen', (
      tester,
    ) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);
      await openCustomer(tester);

      await _sendBack(tester, 'startBackGesture', _swipe(0));
      await tester.pump();
      await _sendBack(tester, 'updateBackGestureProgress', _swipe(0.4));
      await tester.pump();
      expect(router.root().userGestureInProgress, isTrue);
      await _sendBack(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();

      expect(router.root().userGestureInProgress, isFalse);
      expect(find.byType(CustomerDetailScreen), findsOneWidget);
      expect(router.location(), '/customers/cust-1');
      expect(handlesBack.last, isTrue);

      // Still interactive: the app bar's back button returns to the list.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(router.location(), '/customers');
    });

    testWidgets('a swipe on a form with unsaved input asks before it discards', (
      tester,
    ) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);
      // ignore: unawaited_futures
      const CustomerCreateRoute().push<void>(router.root().context);
      await tester.pumpAndSettle();
      expect(find.byType(CustomerFormScreen), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Sita');
      await tester.pumpAndSettle();
      // The app keeps the swipe so that it can ask first.
      expect(handlesBack.last, isTrue);

      await _sendBack(tester, 'startBackGesture', _swipe(0));
      await tester.pump();
      await _sendBack(tester, 'updateBackGestureProgress', _swipe(0.6));
      await tester.pump();
      // No preview of the list while the form refuses to pop.
      expect(router.root().userGestureInProgress, isFalse);

      await _sendBack(tester, 'commitBackGesture');
      await tester.pumpAndSettle();

      expect(find.text(t.common.unsavedChanges.title), findsOneWidget);
      expect(find.byType(CustomerFormScreen), findsOneWidget);
    });

    testWidgets('a swipe with a sheet open closes the sheet and nothing else', (
      tester,
    ) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);
      await tester.tap(find.byTooltip(t.sorting.title));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      // A tab root with a sheet open is no longer a place to leave the app from.
      expect(handlesBack.last, isTrue);

      await _sendBack(tester, 'startBackGesture', _swipe(0));
      await tester.pump();
      await _sendBack(tester, 'commitBackGesture');
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(CustomersScreen), findsOneWidget);
      expect(router.location(), '/customers');
      expect(handlesBack.last, isFalse);
    });

    testWidgets('a swipe with a row\'s menu open closes the menu and stays in the app', (
      tester,
    ) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);
      await tester.tap(find.byTooltip(t.common.moreOptions).first);
      await tester.pumpAndSettle();
      expect(find.text(t.common.delete), findsOneWidget);
      // The official menu left this false: back went to the system and closed the app.
      expect(handlesBack.last, isTrue);

      await _sendBack(tester, 'startBackGesture', _swipe(0));
      await tester.pump();
      await _sendBack(tester, 'commitBackGesture');
      await tester.pumpAndSettle();

      expect(find.text(t.common.delete), findsNothing);
      expect(find.byType(CustomersScreen), findsOneWidget);
      expect(router.location(), '/customers');
      expect(handlesBack.last, isFalse);
    });

    testWidgets('every tab root leaves the swipe to the system', (tester) async {
      final (:router, :handlesBack) = await pumpSignedIn(tester);

      for (final label in [
        t.nav.dashboard,
        t.nav.oneTimeDeposits,
        t.nav.recurringDeposits,
        t.nav.customers,
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(handlesBack.last, isFalse, reason: label);
      }
      expect(find.byType(CustomersScreen), findsOneWidget);
      expect(router.location(), '/customers');
    });
  });
}

/// The two things the tests ask the router: where it is, and its root navigator, which
/// holds every detail and form screen.
typedef _Router = ({
  String Function() location,
  NavigatorState Function() root,
});

Map<String, Object?> _swipe(double progress) => <String, Object?>{
  'touchOffset': <double>[5, 300],
  'progress': progress,
  'swipeEdge': 0,
};

Future<void> _sendBack(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
}
