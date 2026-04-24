import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

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
}
