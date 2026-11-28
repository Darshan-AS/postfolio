import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/theme/app_widget_themes.dart';
import 'package:skeletonizer/skeletonizer.dart'
    show ShimmerEffect, SkeletonizerConfigData;

/// The app's Material 3 Expressive theme.
///
/// [buildTheme] turns any [ColorScheme] (brand seed, the device's dynamic colours, or the
/// accessible palette) into the full theme, so all four modes share one set of shapes,
/// type roles and component styles.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF1A56DB);

  /// The brand palette, used where the device offers no dynamic colours (web, desktop, iOS,
  /// Android 11 and older) and as the base of the accessible themes.
  ///
  /// The `vibrant` variant keeps the primary colour close to the brand seed while containers
  /// stay pastel. The default variant (`tonalSpot`) mutes the seed to a slate blue.
  static ColorScheme _brandScheme(Brightness brightness) =>
      ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: _seedColor,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      );

  static const PageTransitionsBuilder _desktopPageTransition =
      SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.horizontal,
      );

  /// The transition between two screens, for every platform.
  ///
  /// - Android: the official predictive back transition. It follows the finger during a
  ///   back swipe and fades forwards for a tap. Both screens are drawn live while it runs.
  ///   By default it animates a picture of each, taken on its first frame: a screen whose
  ///   content fades in would be empty until the transition ends, and a row would stay in
  ///   the picture after its avatar and name have set out for the next screen.
  /// - iOS: `material_ui`'s default, the platform's own transition. It brings the swipe back
  ///   from the left edge, which an iPhone needs because it has no back button.
  /// - Desktop: a horizontal shared axis. A platform that is not listed here would fall back
  ///   to the Android 10 zoom.
  static final PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      ...const PageTransitionsTheme().builders,
      TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(
        allowSnapshotting: false,
      ),
      TargetPlatform.macOS: _desktopPageTransition,
      TargetPlatform.windows: _desktopPageTransition,
      TargetPlatform.linux: _desktopPageTransition,
      TargetPlatform.fuchsia: _desktopPageTransition,
    },
  );

  /// Derives shimmer colors directly from the active [ColorScheme] so Dark Mode and Accessible
  /// Mode skeletons never fall back to light `ThemeData.fallback()` bones.
  static SkeletonizerConfigData skeletonizerConfig(ColorScheme colorScheme) {
    return SkeletonizerConfigData(
      effect: ShimmerEffect(
        baseColor: colorScheme.surfaceContainerHighest,
        highlightColor: colorScheme.surfaceContainerLow,
      ),
    );
  }

  static ThemeData buildTheme(
    ColorScheme colorScheme, {
    AppFinancialColors? financialColors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
    );
    final effectiveFinancial =
        financialColors ??
        AppFinancialColors.forBrightness(colorScheme.brightness);
    // `ThemeData.textTheme` holds colours and the font family only; sizes are merged in per
    // locale by `Theme.of`. Component themes replace a widget's default style rather than
    // merge with it, so the styles handed to them need the sizes too.
    final textTheme = AppTypography.withTabularFigures(base.textTheme);
    final sizedTextTheme = base.typography.englishLike.merge(textTheme);
    final emphasized = AppTypography.emphasized(sizedTextTheme);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.page,
      canvasColor: colorScheme.page,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[effectiveFinancial],
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: AppWidgetThemes.appBarTheme(colorScheme, emphasized),
      dividerTheme: AppWidgetThemes.dividerTheme(colorScheme),
      floatingActionButtonTheme: AppWidgetThemes.floatingActionButtonTheme(
        colorScheme,
      ),
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme(
        colorScheme,
        emphasized,
      ),
      filledButtonTheme: AppWidgetThemes.filledButtonTheme(
        colorScheme,
        emphasized,
      ),
      outlinedButtonTheme: AppWidgetThemes.outlinedButtonTheme(
        colorScheme,
        emphasized,
      ),
      textButtonTheme: AppWidgetThemes.textButtonTheme(colorScheme, emphasized),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(colorScheme),
      iconButtonTheme: AppWidgetThemes.iconButtonTheme(colorScheme),
      searchBarTheme: AppWidgetThemes.searchBarTheme(
        colorScheme,
        sizedTextTheme,
      ),
      chipTheme: AppWidgetThemes.chipTheme(colorScheme, emphasized),
      snackBarTheme: AppWidgetThemes.snackBarTheme(colorScheme),
      dialogTheme: AppWidgetThemes.dialogTheme(colorScheme, emphasized),
      bottomSheetTheme: AppWidgetThemes.bottomSheetTheme(colorScheme),
      menuTheme: AppWidgetThemes.menuTheme(colorScheme),
      menuButtonTheme: AppWidgetThemes.menuButtonTheme(
        colorScheme,
        sizedTextTheme,
      ),
      datePickerTheme: AppWidgetThemes.datePickerTheme(colorScheme),
      bannerTheme: AppWidgetThemes.bannerTheme(colorScheme),
      switchTheme: AppWidgetThemes.switchTheme(colorScheme),
      checkboxTheme: AppWidgetThemes.checkboxTheme(colorScheme),
    );
  }

  static ThemeData get lightTheme {
    return buildTheme(
      _brandScheme(Brightness.light),
      financialColors: AppFinancialColors.light,
    );
  }

  static ThemeData get darkTheme {
    return buildTheme(
      _brandScheme(Brightness.dark),
      financialColors: AppFinancialColors.dark,
    );
  }

  static ThemeData get accessibleLightTheme {
    final colorScheme = _brandScheme(Brightness.light).copyWith(
      error: const Color(0xFFB80F57),
      errorContainer: const Color(0xFFFCE4EC),
      onError: Colors.white,
      onErrorContainer: const Color(0xFF7A0938),
      tertiary: const Color(0xFFB84A00),
      tertiaryContainer: const Color(0xFFFFE2CC),
      onTertiary: Colors.white,
      onTertiaryContainer: const Color(0xFF6B2900),
    );
    return buildTheme(
      colorScheme,
      financialColors: AppFinancialColors.accessibleLight,
    );
  }

  static ThemeData get accessibleDarkTheme {
    final colorScheme = _brandScheme(Brightness.dark).copyWith(
      error: const Color(0xFFF48FB1),
      errorContainer: const Color(0xFF5E092C),
      onError: const Color(0xFF4A0420),
      onErrorContainer: const Color(0xFFFDD5E5),
      tertiary: const Color(0xFFFFCA28),
      tertiaryContainer: const Color(0xFF522100),
      onTertiary: const Color(0xFF3E1900),
      onTertiaryContainer: const Color(0xFFFFD8BD),
    );
    return buildTheme(
      colorScheme,
      financialColors: AppFinancialColors.accessibleDark,
    );
  }
}
