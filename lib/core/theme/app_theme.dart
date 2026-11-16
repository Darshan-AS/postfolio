import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_widget_themes.dart';
import 'package:skeletonizer/skeletonizer.dart' show ShimmerEffect, SkeletonizerConfigData;

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF1A56DB);

  static TextTheme _withTabularFigures(TextTheme base) {
    TextStyle? tabular(TextStyle? style) => style?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return base.copyWith(
      displayLarge: tabular(base.displayLarge),
      displayMedium: tabular(base.displayMedium),
      displaySmall: tabular(base.displaySmall),
      headlineLarge: tabular(base.headlineLarge),
      headlineMedium: tabular(base.headlineMedium),
      headlineSmall: tabular(base.headlineSmall),
      titleLarge: tabular(base.titleLarge),
      titleMedium: tabular(base.titleMedium),
      titleSmall: tabular(base.titleSmall),
      bodyLarge: tabular(base.bodyLarge),
      bodyMedium: tabular(base.bodyMedium),
      bodySmall: tabular(base.bodySmall),
      labelLarge: tabular(base.labelLarge),
      labelMedium: tabular(base.labelMedium),
      labelSmall: tabular(base.labelSmall),
    );
  }

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
    );
    final effectiveFinancial =
        financialColors ?? AppFinancialColors.forBrightness(colorScheme.brightness);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _withTabularFigures(base.textTheme),
      extensions: <ThemeExtension<dynamic>>[effectiveFinancial],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
        },
      ),
      appBarTheme: AppWidgetThemes.appBarTheme(colorScheme),
      dividerTheme: AppWidgetThemes.dividerTheme(colorScheme),
      floatingActionButtonTheme: AppWidgetThemes.floatingActionButtonTheme(
        colorScheme,
      ),
      cardTheme: AppWidgetThemes.cardTheme(colorScheme),
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme(colorScheme),
      filledButtonTheme: AppWidgetThemes.filledButtonTheme(colorScheme),
      outlinedButtonTheme: AppWidgetThemes.outlinedButtonTheme(colorScheme),
      textButtonTheme: AppWidgetThemes.textButtonTheme(colorScheme),
      segmentedButtonTheme: AppWidgetThemes.segmentedButtonTheme(colorScheme),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(colorScheme),
      iconButtonTheme: AppWidgetThemes.iconButtonTheme(colorScheme),
      searchBarTheme: AppWidgetThemes.searchBarTheme(colorScheme),
      chipTheme: AppWidgetThemes.chipTheme(colorScheme),
      expansionTileTheme: AppWidgetThemes.expansionTileTheme(colorScheme),
      snackBarTheme: AppWidgetThemes.snackBarTheme(colorScheme),
      radioTheme: AppWidgetThemes.radioTheme(colorScheme),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: _seedColor,
    );
    return buildTheme(colorScheme, financialColors: AppFinancialColors.light);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: _seedColor,
    );
    return buildTheme(colorScheme, financialColors: AppFinancialColors.dark);
  }

  static ThemeData get accessibleLightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: _seedColor,
        ).copyWith(
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
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: _seedColor,
        ).copyWith(
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
