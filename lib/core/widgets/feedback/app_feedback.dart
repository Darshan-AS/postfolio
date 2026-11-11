import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/utils/result.dart';

/// One place that turns a `Result` into user feedback, so no call site can forget the
/// failure arm. Safe to call after an `await` — the messenger is resolved from [context]
/// only if it is still mounted.
abstract final class AppFeedback {
  static void showResult(
    BuildContext context,
    Result<void, String> result, {
    required String successMessage,
    String? undoLabel,
    VoidCallback? onUndo,
  }) {
    if (!context.mounted) return;
    switch (result) {
      case Success():
        showSuccess(
          context,
          successMessage,
          undoLabel: undoLabel,
          onUndo: onUndo,
        );
      case Failure(:final error):
        showError(context, error);
    }
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final scheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: scheme.inverseSurface,
        content: Text(
          message,
          style: TextStyle(color: scheme.onInverseSurface),
        ),
        action: (undoLabel != null && onUndo != null)
            ? SnackBarAction(
                label: undoLabel,
                textColor: scheme.inversePrimary,
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final overdue = AppFinancialColors.of(context).overdue;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: overdue.container,
        closeIconColor: overdue.onContainer,
        content: Text(
          message,
          style: TextStyle(
            color: overdue.onContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
