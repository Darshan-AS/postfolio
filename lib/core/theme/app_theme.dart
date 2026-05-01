import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_colors.dart';
import 'package:postfolio/core/theme/app_widget_themes.dart';

class AppTheme {
  AppTheme._();

  // The Master Theme Data
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: AppWidgetThemes.appBarTheme,
      dividerTheme: AppWidgetThemes.dividerTheme,
      floatingActionButtonTheme: AppWidgetThemes.floatingActionButtonTheme,
      cardTheme: AppWidgetThemes.cardTheme,
      elevatedButtonTheme: AppWidgetThemes.elevatedButtonTheme,
      filledButtonTheme: AppWidgetThemes.filledButtonTheme,
      segmentedButtonTheme: AppWidgetThemes.segmentedButtonTheme(colorScheme),
      inputDecorationTheme: AppWidgetThemes.inputDecorationTheme(colorScheme),
      iconButtonTheme: AppWidgetThemes.iconButtonTheme,
    );
  }
}
