import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/demo_banner.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  // In demo mode the banner is under the status bar, where a tab's app bar would be. An app
  // bar asks for the status bar icons that suit it; nothing did for the banner, so after a
  // dialog (whose scrim asks for light icons) the clock stayed white on the light page.
  for (final (name, theme, icons) in [
    ('light', AppTheme.lightTheme, Brightness.dark),
    ('dark', AppTheme.darkTheme, Brightness.light),
  ]) {
    testWidgets('the demo banner asks for $name-theme status bar icons', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // A scrim over the whole screen that asks for light icons, as an open dialog does.
      final scrim = ValueNotifier(false);
      addTearDown(scrim.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
              child: const Scaffold(body: Column(children: [DemoBanner()])),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(t.common.demoModeActive), findsOneWidget);

      scrim.value = true;
      await tester.pumpAndSettle();
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.light,
      );

      // The scrim goes; the banner's own request is what is left.
      scrim.value = false;
      await tester.pumpAndSettle();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, icons);
    });
  }
}
