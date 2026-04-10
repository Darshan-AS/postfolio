import 'package:flutter/material.dart';

class AppInputDecoration {
  static InputDecoration m3(
    BuildContext context, {
    required String labelText,
    IconData? prefixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }
}
