import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class AppSortBottomSheet<T> extends HookWidget {
  final String title;
  final List<T> options;
  final T selectedOption;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const AppSortBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.labelBuilder,
    required this.onSelected,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T selectedOption,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
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
        options: options,
        selectedOption: selectedOption,
        labelBuilder: labelBuilder,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localSelectedOption = useState<T>(selectedOption);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
            ),
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
          ),
          const Divider(),
          Flexible(
            child: RadioGroup<T>(
              groupValue: localSelectedOption.value,
              onChanged: (value) {
                if (value != null) {
                  localSelectedOption.value = value;
                  onSelected(value);
                }
              },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return RadioListTile<T>(
                    title: Text(labelBuilder(option)),
                    value: option,
                  );
                },
              ),
            ),
          ),
          AppSpacings.gapLg,
        ],
      ),
    );
  }
}
