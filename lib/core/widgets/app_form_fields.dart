import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

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
    this.onTap,
    this.maxLines = 1,
    this.suffixIcon,
    this.onChanged,
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
      onTap: onTap,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final IconData? prefixIcon;
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
      prefixIcon: Icons.calendar_today_outlined,
      readOnly: true,
      onTap: onTap,
      isRequired: isRequired,
    );
  }
}
