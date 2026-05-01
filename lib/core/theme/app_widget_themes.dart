import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_colors.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppWidgetThemes {
  AppWidgetThemes._();

  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(
      color: AppColors.textPrimary,
      size: AppDimensions.iconMd,
    ),
    actionsIconTheme: IconThemeData(
      color: AppColors.textPrimary,
      size: AppDimensions.iconMd,
    ),
  );

  static DividerThemeData get dividerTheme =>
      const DividerThemeData(color: AppColors.divider, space: 1, thickness: 1);

  static IconButtonThemeData get iconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      iconSize: AppDimensions.iconMd,
      foregroundColor: AppColors.textSecondary,
    ),
  );

  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 4,
      );

  static CardThemeData get cardTheme => CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.divider, width: 1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    ),
  );

  static ElevatedButtonThemeData get elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  static FilledButtonThemeData get filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      );
}
