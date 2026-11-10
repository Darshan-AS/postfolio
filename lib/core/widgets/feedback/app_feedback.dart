import 'package:material_ui/material_ui.dart';
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final scheme = Theme.of(context).colorScheme;
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            action: (undoLabel != null && onUndo != null)
                ? SnackBarAction(label: undoLabel, onPressed: onUndo)
                : null,
          ),
        );
      case Failure(:final error):
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: scheme.error,
          ),
        );
    }
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
