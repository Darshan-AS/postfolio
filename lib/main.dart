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
import 'package:postfolio/core/providers/app_preferences_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/app_error_reporter.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_expressive_theme.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/widgets/common/demo_banner.dart';
import 'package:postfolio/core/widgets/common/local_backend_banner.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/admin/presentation/widgets/acting_as_banner.dart';
import 'package:postfolio/firebase_options.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true)
          .ignore();
      return true;
    };
    // Errors a repository turned into a generic message (unreadable rows, unknown database
    // codes) are handled, not crashes: record them as non-fatal so the cause is not lost.
    SupabaseErrorMapper.onUnexpected = (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: false)
          .ignore();
    };
  } else if (kIsWeb) {
    final webReporter = AppErrorReporter.supabase(Supabase.instance.client);
    SupabaseErrorMapper.onUnexpected = (error, stack) {
      webReporter.reportUnawaited(
        platform: 'web',
        error: error,
        stackTrace: stack,
      );
    };
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
    final prefs = ref.watch(appPreferencesProvider);

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

        // If the user explicitly wants the accessible theme or disables wallpaper colors,
        // ignore Monet so strict high-contrast / brand colors stay intact.
        if (themeMode == AppThemeMode.accessibleSystem) {
          effectiveLightTheme = AppTheme.accessibleLightTheme;
          effectiveDarkTheme = AppTheme.accessibleDarkTheme;
        } else if (prefs.useDynamicColor) {
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
          builder: (context, child) {
            final scheme = Theme.of(context).colorScheme;
            return AppExpressiveTheme(
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(scheme),
                child: _AppBannerFrame(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
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

/// Pins environment/mode banners ([ActingAsBanner], [DemoBanner], [LocalBackendBanner]) above
/// the root navigator so they stay visible on pushed detail, form, profile, and settings
/// routes, removing redundant top safe-area padding below each visible banner while keeping
/// the router subtree topology invariant.
class _AppBannerFrame extends ConsumerWidget {
  const _AppBannerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActingAs = ref.watch(
      actingAsControllerProvider.select((state) => state.isActingAs),
    );
    final isDemoMode = ref.watch(demoModeProvider);
    final showLocalBanner = ref.watch(localBackendBannerVisibleProvider);
    final hasAnyBanner = isActingAs || isDemoMode || showLocalBanner;

    return Column(
      children: [
        const ActingAsBanner(),
        MediaQuery.removePadding(
          context: context,
          removeTop: isActingAs,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [DemoBanner(), LocalBackendBanner()],
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: hasAnyBanner,
            child: child,
          ),
        ),
      ],
    );
  }
}
