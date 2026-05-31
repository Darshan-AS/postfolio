import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_widget_themes.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Colors.blue;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: _seedColor,
    );

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

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: _seedColor,
    );

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
}
