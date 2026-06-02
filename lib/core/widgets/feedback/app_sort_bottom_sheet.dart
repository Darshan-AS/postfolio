import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/enums/sort_direction.dart';

class AppSortBottomSheet<T> extends HookWidget {
  final String title;
  final List<T> fields;
  final T selectedField;
  final SortDirection selectedDirection;
  final String Function(T) fieldLabelBuilder;
  final String Function(T, SortDirection) directionLabelBuilder;
  final void Function(T, SortDirection) onSelected;

  const AppSortBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.selectedField,
    required this.selectedDirection,
    required this.fieldLabelBuilder,
    required this.directionLabelBuilder,
    required this.onSelected,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    required List<T> fields,
    required T selectedField,
    required SortDirection selectedDirection,
    required String Function(T) fieldLabelBuilder,
    required String Function(T, SortDirection) directionLabelBuilder,
    required void Function(T, SortDirection) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (context) => AppSortBottomSheet<T>(
        title: title,
        fields: fields,
        selectedField: selectedField,
        selectedDirection: selectedDirection,
        fieldLabelBuilder: fieldLabelBuilder,
        directionLabelBuilder: directionLabelBuilder,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentField = useState(selectedField);
    final currentDirection = useState(selectedDirection);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                final isSelected = currentField.value == field;

                return ListTile(
                  title: Text(
                    fieldLabelBuilder(field),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppDimensions.iconSm,
                      )
                      : null,
                  onTap: () {
                    currentField.value = field;
                    onSelected(field, currentDirection.value);
                  },
                );
              },
            ),
          ),
          const Divider(),
          _buildDirectionToggle(context, currentField.value, currentDirection),
          AppSpacings.gapLg,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: AppDimensions.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionToggle(
    BuildContext context,
    T field,
    ValueNotifier<SortDirection> direction,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: SegmentedButton<SortDirection>(
        segments: [
          ButtonSegment(
            value: SortDirection.asc,
            label: Text(directionLabelBuilder(field, SortDirection.asc)),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowUp01,
              size: AppDimensions.iconSm,
            ),
          ),
          ButtonSegment(
            value: SortDirection.desc,
            label: Text(directionLabelBuilder(field, SortDirection.desc)),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: AppDimensions.iconSm,
            ),
          ),
        ],
        selected: {direction.value},
        onSelectionChanged: (selection) {
          final isDesc = selection.first;
          direction.value = isDesc;
          onSelected(field, isDesc);
        },
      ),
    );
  }
}
