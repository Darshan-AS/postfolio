import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';

/// One question in a filter sheet: a title and its options, any number of which can be on.
///
/// The options are a multi-select [AppButtonGroup], the same control as the sort direction
/// and the segmented fields of the forms. They share one row, so this is for a handful of
/// short options; at large text each takes a line.
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.emphasizedOf(context).titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacings.gapXs,
        AppButtonGroup<T>.multi(
          segments: [
            for (final option in options)
              AppSegment(value: option, label: labelBuilder(option)),
          ],
          selected: selectedOptions.toSet(),
          onToggled: onSelected,
        ),
      ],
    );
  }
}
