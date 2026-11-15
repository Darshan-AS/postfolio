import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_surfaces.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';

export 'package:postfolio/core/widgets/expressive/app_button_group.dart' show AppSegment;

/// Uppercases ASCII characters as the user types (e.g. PAN numbers).
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? prefixText;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.prefixText,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: AppInputDecoration.m3(
        context,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        isRequired: isRequired,
      ).copyWith(suffixIcon: suffixIcon),
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final Widget? prefixIcon;
  final bool isRequired;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.labelText,
    this.prefixIcon,
    this.isRequired = false,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      key: ValueKey<T?>(value),
      initialValue: value,
      decoration: AppInputDecoration.m3(
        context,
        labelText: labelText,
        prefixIcon: prefixIcon,
        isRequired: isRequired,
      ),
      // Without this the button is as wide as its longest item and overflows a narrow field.
      isExpanded: true,
      // The text field's input style; the dropdown's own default is a heavier title role.
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      // The same chevron as the customer picker, in place of the Material arrow glyph.
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        size: AppDimensions.iconMd,
      ),
      borderRadius: BorderRadius.circular(AppShapes.large),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final VoidCallback onTap;
  final bool isRequired;
  final bool enabled;

  const AppDateField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onTap,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      labelText: labelText,
      prefixIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar01,
        size: AppDimensions.iconMd,
      ),
      readOnly: true,
      onTap: enabled ? onTap : null,
      isRequired: isRequired,
      enabled: enabled,
    );
  }
}

/// A labelled single-choice field drawn as a connected button group ([AppButtonGroup]).
class AppSegmentedButtonField<T> extends StatelessWidget {
  final T value;
  final String labelText;
  final Widget? prefixIcon;
  final List<AppSegment<T>> segments;
  final void Function(T) onChanged;
  final bool isRequired;
  final bool enabled;

  const AppSegmentedButtonField({
    super.key,
    required this.value,
    required this.labelText,
    required this.segments,
    required this.onChanged,
    this.prefixIcon,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.paddingXs,
            bottom: AppDimensions.paddingSm,
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: AppDimensions.iconSm,
                    color: scheme.onSurfaceVariant,
                  ),
                  child: prefixIcon!,
                ),
                AppSpacings.gapSm,
              ],
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: labelText,
                    children: [
                      if (isRequired)
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: scheme.error),
                        ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppButtonGroup<T>(
          segments: segments,
          selected: value,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// One section of a create / edit form: a heading in the style of the detail screens, and
/// the section's fields inside one raised container.
///
/// The fields keep the themed tonal fill, which reads as recessed against the container.
/// Callers space the fields themselves.
class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionTitle(title),
        Material(
          color: Theme.of(context).colorScheme.raised,
          shape: AppShapes.rounded(AppShapes.groupOuter),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Supporting text under a form field, aligned with the field's content.
class FormFieldSupportingText extends StatelessWidget {
  final String text;

  /// Uses the primary colour and italics, for a value echoed back from the field (an amount
  /// in words, the full name of the picked option). Plain helper text otherwise.
  final bool isEcho;

  const FormFieldSupportingText(this.text, {super.key, this.isEcho = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.paddingXs,
        left: AppDimensions.paddingLg,
        right: AppDimensions.paddingLg,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isEcho ? scheme.primary : scheme.onSurfaceVariant,
          fontStyle: isEcho ? FontStyle.italic : null,
        ),
      ),
    );
  }
}
