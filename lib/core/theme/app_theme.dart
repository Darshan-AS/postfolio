import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Colors.blue; // or Color(0xFF1E88E5)
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Colors.lightBlue;

  // Neutral Colors (Backgrounds & Surfaces)
  static const Color background = Color(0xFFFAFAFA); // grey[50] equivalent
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0); // grey[300] equivalent

  // Semantic Colors (Status/Alerts)
  static const Color error = Color(0xFFEF5350); // red[400] equivalent
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;

  // Text Colors
  static const Color textPrimary = Color(0xDD000000); // black87 equivalent
  static const Color textSecondary = Color(0xFF757575); // grey[600] equivalent
  static const Color textTertiary = Color(
    0xFF9E9E9E,
  ); // grey equivalent for faint icons/labels

  // The Master Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: divider,
        space: 1,
        thickness: 1,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 4,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: divider, width: 1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingLg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
    );
  }
}
