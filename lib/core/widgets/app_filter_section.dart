import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppFilterSection<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final List<T> selectedOptions;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const AppFilterSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacings.gapSm,
        Wrap(
          spacing: AppDimensions.paddingSm,
          runSpacing: AppDimensions.paddingXs,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(labelBuilder(option)),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              showCheckmark: true,
            );
          }).toList(),
        ),
      ],
    );
  }
}
