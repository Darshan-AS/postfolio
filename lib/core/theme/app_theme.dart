import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_widget_themes.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Colors.blue;

  static ThemeData buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppWidgetThemes.appBarTheme(colorScheme),
      dividerTheme: AppWidgetThemes.dividerTheme(colorScheme),
      floatingActionButtonTheme: AppWidgetThemes.floatingActionButtonTheme(
        colorScheme,
      ),
      cardTheme: AppWidgetThemes.cardTheme(colorScheme),
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme(colorScheme),
      filledButtonTheme: AppWidgetThemes.filledButtonTheme(colorScheme),
      segmentedButtonTheme: AppWidgetThemes.segmentedButtonTheme(colorScheme),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(colorScheme),
      iconButtonTheme: AppWidgetThemes.iconButtonTheme(colorScheme),
      searchBarTheme: AppWidgetThemes.searchBarTheme(colorScheme),
      chipTheme: AppWidgetThemes.chipTheme(colorScheme),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: _seedColor,
    );
    return buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: _seedColor,
    );
    return buildTheme(colorScheme);
  }

  static ThemeData get accessibleLightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: _seedColor,
        ).copyWith(
          // Wong/Tol inspired color-blind safe semantic colors
          // Error (Magenta)
          error: const Color(0xFFD81B60),
          errorContainer: const Color(0xFFF8BBD0),
          onError: Colors.white,
          onErrorContainer: const Color(0xFF880E4F),
          // Success/Warning (Orange/Amber) instead of Green/Teal
          tertiary: const Color(0xFFFF8F00),
          tertiaryContainer: const Color(0xFFFFE082),
          onTertiary: Colors.black,
          onTertiaryContainer: const Color(0xFFE65100),
        );
    return buildTheme(colorScheme);
  }

  static ThemeData get accessibleDarkTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: _seedColor,
        ).copyWith(
          // Wong/Tol inspired color-blind safe semantic colors
          // Error (Magenta)
          error: const Color(0xFFF48FB1),
          errorContainer: const Color(0xFF880E4F),
          onError: const Color(0xFF880E4F),
          onErrorContainer: const Color(0xFFFCE4EC),
          // Success/Warning (Orange/Amber) instead of Green/Teal
          tertiary: const Color(0xFFFFCA28),
          tertiaryContainer: const Color(0xFFF57C00),
          onTertiary: const Color(0xFF4E342E),
          onTertiaryContainer: const Color(0xFFFFF8E1),
        );
    return buildTheme(colorScheme);
  }
}
