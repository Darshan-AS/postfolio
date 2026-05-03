import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final int? maxLines;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.maxLines = 1,
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
        isRequired: isRequired,
      ).copyWith(suffixIcon: suffixIcon),
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      maxLines: maxLines,
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
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: AppInputDecoration.m3(
        context,
        labelText: labelText,
        prefixIcon: prefixIcon,
        isRequired: isRequired,
      ),
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

  const AppDateField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onTap,
    this.isRequired = false,
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
      onTap: onTap,
      isRequired: isRequired,
    );
  }
}

class AppSegmentedButtonField<T> extends StatelessWidget {
  final T value;
  final String labelText;
  final Widget? prefixIcon;
  final List<ButtonSegment<T>> segments;
  final void Function(T) onChanged;
  final bool isRequired;

  const AppSegmentedButtonField({
    super.key,
    required this.value,
    required this.labelText,
    required this.segments,
    required this.onChanged,
    this.prefixIcon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: prefixIcon!,
                ),
                AppSpacings.gapSm,
              ],
              Text(
                labelText + (isRequired ? ' *' : ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        SegmentedButton<T>(
          segments: segments,
          selected: {value},
          onSelectionChanged: (Set<T> newSelection) {
            onChanged(newSelection.first);
          },
        ),
      ],
    );
  }
}
