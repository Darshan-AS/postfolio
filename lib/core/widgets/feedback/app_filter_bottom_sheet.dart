import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppFilterBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onClearAll;
  final List<Widget> filterSections;

  const AppFilterBottomSheet({
    super.key,
    required this.title,
    required this.onClearAll,
    required this.filterSections,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
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
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.paddingLg,
          right: AppDimensions.paddingLg,
          bottom: AppDimensions.paddingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearAll,
                  child: Text(t.common.clearFilters),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: AppDimensions.iconMd,
                  ),
                ),
              ],
            ),
            AppSpacings.gapLg,
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < filterSections.length; i++) ...[
                      filterSections[i],
                      if (i < filterSections.length - 1) AppSpacings.gapLg,
                    ],
                  ],
                ),
              ),
            ),
            AppSpacings.gapLg,
          ],
        ),
      ),
    );
  }
}
