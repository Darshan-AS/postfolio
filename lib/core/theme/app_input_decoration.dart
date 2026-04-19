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
    );
  }
}
