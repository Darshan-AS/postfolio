import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_sheet_header.dart';

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

  /// A bottom sheet on a phone, a dialog on a wide window.
  static Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return AppAdaptiveSheet.show<void>(context, builder: builder);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.pageMargin,
          right: AppDimensions.pageMargin,
          bottom: AppDimensions.paddingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: title, onClear: onClearAll),
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
