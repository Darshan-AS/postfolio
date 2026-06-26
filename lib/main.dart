import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:postfolio/firebase_options.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/core/env/env.dart';

const bool useFirebaseEmulator = bool.fromEnvironment(
  'USE_EMULATOR',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Enable Firestore cache specifically for Web
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  // Initialize Analytics
  FirebaseAnalytics.instance;

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  if (useFirebaseEmulator) {
    try {
      final String host;
      if (kIsWeb) {
        host = 'localhost';
      } else if (Platform.isAndroid) {
        host = '10.0.2.2';
      } else {
        host = 'localhost';
      }
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      debugPrint('Connected to Firebase Emulator');
    } catch (e) {
      debugPrint('Failed to connect to Firebase Emulator: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  LocaleSettings.useDeviceLocale();

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
          // Otherwise, apply the OS dynamic colors if they are available.
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
