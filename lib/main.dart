import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/app_error_reporter.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/firebase_options.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool get _supportsCrashlytics =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  Env.assertFlavorSafe(flavor: appFlavor);

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  if (_supportsCrashlytics) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true).ignore();
      return true;
    };
  } else if (kIsWeb) {
    final webReporter = AppErrorReporter.supabase(Supabase.instance.client);
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      webReporter.reportUnawaited(
        platform: 'web',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      webReporter.reportUnawaited(
        platform: 'web',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  final prefs = await SharedPreferences.getInstance();
  await LocaleSettings.useDeviceLocale();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: TranslationProvider(child: const PostfolioApp()),
    ),
  );
}

class PostfolioApp extends ConsumerWidget {
  const PostfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;
    ThemeMode materialThemeMode = ThemeMode.system;

    switch (themeMode) {
      case AppThemeMode.light:
        materialThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        materialThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.accessibleSystem:
        materialThemeMode = ThemeMode.system;
        lightTheme = AppTheme.accessibleLightTheme;
        darkTheme = AppTheme.accessibleDarkTheme;
        break;
      case AppThemeMode.system:
        materialThemeMode = ThemeMode.system;
        break;
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeData effectiveLightTheme = lightTheme;
        ThemeData effectiveDarkTheme = darkTheme;

        // If the user explicitly wants the accessible theme, completely ignore Monet.
        // This ensures the strict high-contrast semantic colors remain readable
        // and aren't ruined by a low-contrast OS dynamic palette.
        if (themeMode == AppThemeMode.accessibleSystem) {
          effectiveLightTheme = AppTheme.accessibleLightTheme;
          effectiveDarkTheme = AppTheme.accessibleDarkTheme;
        } else {
          if (lightDynamic != null) {
            effectiveLightTheme = AppTheme.buildTheme(
              lightDynamic.harmonized(),
            );
          }
          if (darkDynamic != null) {
            effectiveDarkTheme = AppTheme.buildTheme(darkDynamic.harmonized());
          }
        }

        return MaterialApp.router(
          title: t.appTitle,
          theme: effectiveLightTheme,
          darkTheme: effectiveDarkTheme,
          themeMode: materialThemeMode,
          routerConfig: goRouter,
          locale: TranslationProvider.of(context).flutterLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocaleUtils.supportedLocales,
        );
      },
    );
  }
}
