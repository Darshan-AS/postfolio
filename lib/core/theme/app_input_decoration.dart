import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppInputDecoration {
  static InputDecoration m3(
    BuildContext context, {
    String? labelText,
    String? hintText,
    String? errorText,
    Widget? prefixIcon,
    String? prefixText,
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

    Widget? finalPrefixIcon;
    if (prefixIcon != null) {
      finalPrefixIcon = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
        ),
        child: IconTheme(
          data: IconThemeData(
            size: AppDimensions.iconMd,
            color: colorScheme.onSurfaceVariant,
          ),
          child: prefixIcon,
        ),
      );
    }

    return InputDecoration(
      label: label,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: finalPrefixIcon,
      prefixText: prefixText,
      prefixStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
    );
  }
}
