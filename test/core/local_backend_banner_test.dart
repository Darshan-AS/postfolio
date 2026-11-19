import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/local_backend_banner.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('visibility rule: shown only on local stack and never in Demo Mode', () {
    expect(
      shouldShowLocalBackendBanner(isLocalBackend: true, isDemoMode: false),
      isTrue,
    );
    expect(
      shouldShowLocalBackendBanner(isLocalBackend: true, isDemoMode: true),
      isFalse,
    );
    expect(
      shouldShowLocalBackendBanner(isLocalBackend: false, isDemoMode: false),
      isFalse,
    );
    expect(
      shouldShowLocalBackendBanner(isLocalBackend: false, isDemoMode: true),
      isFalse,
    );
  });

  testWidgets('does not show off the local stack (production default)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Column(children: [LocalBackendBanner()])),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.common.localBackendActive), findsNothing);
    expect(tester.getSize(find.byType(LocalBackendBanner)).height, 0);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'on the local stack at 360dp and ${textScale}x text: shows whole label '
      'with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800) * 2;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localBackendBannerVisibleProvider.overrideWithValue(true),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: const Scaffold(
                body: Column(children: [LocalBackendBanner()]),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final label = find.text(t.common.localBackendActive);
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
      },
    );
  }

  for (final (name, theme, icons) in [
    ('light', AppTheme.lightTheme, Brightness.dark),
    ('dark', AppTheme.darkTheme, Brightness.light),
  ]) {
    testWidgets('asks for $name-theme status bar icons after a scrim closes', (
      tester,
    ) async {
      final scrim = ValueNotifier(false);
      addTearDown(scrim.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localBackendBannerVisibleProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: theme,
            home: ValueListenableBuilder(
              valueListenable: scrim,
              builder: (context, showScrim, child) => Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  if (showScrim)
                    const AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle.light,
                      child: ColoredBox(color: Colors.black54),
                    ),
                ],
              ),
              child: const Scaffold(
                body: Column(children: [LocalBackendBanner()]),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(t.common.localBackendActive), findsOneWidget);

      scrim.value = true;
      await tester.pumpAndSettle();
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.light,
      );

      scrim.value = false;
      await tester.pumpAndSettle();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, icons);
    });
  }
}
