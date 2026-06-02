import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/enums/sort_direction.dart';

import 'package:postfolio/i18n/strings.g.dart';

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
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                final isSelected = selectedField == field;

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
                    onSelected(field, selectedDirection);
                  },
                );
              },
            ),
          ),
          const Divider(),
          _buildDirectionToggle(context, selectedField, selectedDirection),
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
          if (onReset != null)
            TextButton(
              onPressed: onReset!,
              child: Text(t.common.clear),
            ),
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
    SortDirection direction,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: SegmentedButton<SortDirection>(
        segments: [
          ButtonSegment(
            value: SortDirection.asc,
            label: Text(directionLabelBuilder(field, SortDirection.asc)),
          ),
          ButtonSegment(
            value: SortDirection.desc,
            label: Text(directionLabelBuilder(field, SortDirection.desc)),
          ),
        ],
        selected: {direction},
        onSelectionChanged: (selection) {
          final isDesc = selection.first;
          onSelected(field, isDesc);
        },
      ),
    );
  }
}
