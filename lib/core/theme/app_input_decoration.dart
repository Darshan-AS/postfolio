import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:flutter/material.dart';

class AppInputDecoration {
  static InputDecoration m3(
    BuildContext context, {
    String? labelText,
    String? hintText,
    String? errorText,
    IconData? prefixIcon,
    bool isRequired = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget? label;
    if (labelText != null) {
      label = isRequired
          ? RichText(
              text: TextSpan(
                text: labelText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            )
          : Text(labelText);
    }

    return InputDecoration(
      label: label,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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
}
