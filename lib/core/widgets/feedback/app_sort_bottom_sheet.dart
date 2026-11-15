import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_sheet_header.dart';

class AppSortBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<T> fields;
  final T selectedField;
  final SortDirection selectedDirection;
  final String Function(T) fieldLabelBuilder;
  final String Function(T, SortDirection) directionLabelBuilder;
  final void Function(T, SortDirection) onSelected;
  final VoidCallback? onReset;

  const AppSortBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.selectedField,
    required this.selectedDirection,
    required this.fieldLabelBuilder,
    required this.directionLabelBuilder,
    required this.onSelected,
    this.onReset,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet(context: context, builder: builder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = AppTypography.emphasizedOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pageMargin,
          0,
          AppDimensions.pageMargin,
          AppDimensions.paddingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: title, onClear: onReset),
            AppSpacings.gapMd,
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: fields.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppShapes.groupGap),
                itemBuilder: (context, index) {
                  final field = fields[index];
                  final isSelected = selectedField == field;

                  return AppGroupTile(
                    position: AppGroupPosition.at(index, fields.length),
                    selected: isSelected,
                    onTap: () => onSelected(field, selectedDirection),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                        vertical: AppDimensions.paddingLg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              fieldLabelBuilder(field),
                              style: isSelected
                                  ? emphasized.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSecondaryContainer,
                                    )
                                  : theme.textTheme.bodyLarge,
                            ),
                          ),
                          if (isSelected)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: AppDimensions.iconMd,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            AppSpacings.gapLg,
            AppButtonGroup<SortDirection>(
              selected: selectedDirection,
              onChanged: (direction) => onSelected(selectedField, direction),
              segments: [
                AppSegment(
                  value: SortDirection.asc,
                  label: directionLabelBuilder(selectedField, SortDirection.asc),
                ),
                AppSegment(
                  value: SortDirection.desc,
                  label: directionLabelBuilder(selectedField, SortDirection.desc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
