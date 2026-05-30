import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppFilterChipBar<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selectedOptions;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const AppFilterChipBar({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.filterBarHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => AppSpacings.gapSm,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedOptions.contains(option);

          return FilterChip(
            label: Text(labelBuilder(option)),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: true,
          );
        },
      ),
    );
  }
}
