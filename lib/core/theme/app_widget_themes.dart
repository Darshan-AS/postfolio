import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppWidgetThemes {
  AppWidgetThemes._();

  static AppBarTheme appBarTheme(ColorScheme colorScheme) => AppBarTheme(
    backgroundColor: colorScheme.surface,
    foregroundColor: colorScheme.onSurface,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(
      color: colorScheme.onSurface,
      size: AppDimensions.iconMd,
    ),
    actionsIconTheme: IconThemeData(
      color: colorScheme.onSurface,
      size: AppDimensions.iconMd,
    ),
  );

  static DividerThemeData dividerTheme(ColorScheme colorScheme) =>
      DividerThemeData(
        color: colorScheme.outlineVariant,
        space: AppDimensions.dividerHeight,
        thickness: AppDimensions.dividerThickness,
      );

  static IconButtonThemeData iconButtonTheme(ColorScheme colorScheme) =>
      IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: AppDimensions.iconMd,
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      );

  static FloatingActionButtonThemeData floatingActionButtonTheme(
    ColorScheme colorScheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primaryContainer,
    foregroundColor: colorScheme.onPrimaryContainer,
    elevation: 4,
  );

  static CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
    color: colorScheme.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: colorScheme.outlineVariant,
        width: AppDimensions.borderSm,
      ),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    ),
  );

  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  static FilledButtonThemeData filledButtonTheme(ColorScheme colorScheme) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  static OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  static TextButtonThemeData textButtonTheme(ColorScheme colorScheme) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  static SegmentedButtonThemeData segmentedButtonTheme(
    ColorScheme colorScheme,
  ) => SegmentedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.outlineVariant),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primaryContainer;
        }
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      }),
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
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppDimensions.borderMd,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppDimensions.borderMd,
          ),
        ),
      );

  static SearchBarThemeData searchBarTheme(ColorScheme colorScheme) =>
      SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );

  static ChipThemeData chipTheme(ColorScheme colorScheme) => ChipThemeData(
    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    selectedColor: colorScheme.primaryContainer,
    secondarySelectedColor: colorScheme.primaryContainer,
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingSm,
      vertical: AppDimensions.paddingXs,
    ),
    labelStyle: TextStyle(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: TextStyle(
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    ),
    brightness: colorScheme.brightness,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      side: BorderSide(color: colorScheme.outlineVariant),
    ),
    showCheckmark: true,
    checkmarkColor: colorScheme.primary,
  );

  static ExpansionTileThemeData expansionTileTheme(ColorScheme colorScheme) =>
      ExpansionTileThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        collapsedBackgroundColor: Colors.transparent,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        shape: const Border(),
        collapsedShape: const Border(),
      );

  static SnackBarThemeData snackBarTheme(ColorScheme colorScheme) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      );

  static RadioThemeData radioTheme(ColorScheme colorScheme) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.onSurface.withValues(alpha: 0.38);
      }
      return colorScheme.onSurfaceVariant;
    }),
  );
}
