import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

/// Presents [builder] as a modal bottom sheet on compact screens and as a centred dialog
/// on tablet/desktop widths, per the UI convention "bottom sheets become dialogs on desktop".
///
/// The child is rendered identically in both cases; only the container differs. Callers
/// should build scrollable content and let this helper own safe-area and drag-handle chrome.
abstract final class AppAdaptiveSheet {
  static const double _dialogMaxWidth = 560.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.breakpointTablet;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    if (isCompact(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        isDismissible: isDismissible,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: builder(ctx),
        ),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
          child: builder(ctx),
        ),
      ),
    );
  }
}
