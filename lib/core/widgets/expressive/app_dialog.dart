import 'package:material_3_expressive/components/dialogs/m3e_dialogs.dart';
import 'package:material_ui/material_ui.dart';

/// A Material 3 Expressive dialog: it springs in over a scrim, keeps its headline and
/// actions in view while long content scrolls, and stacks its actions when they do not fit
/// side by side.
///
/// It opens on the root navigator, over the navigation bar. Back, and a tap on the scrim
/// when [barrierDismissible] is set, close it with a null result.
abstract final class AppDialog {
  /// [actions] is built with the dialog's own context, the one to pop with a result.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    required List<Widget> Function(BuildContext dialogContext) actions,
    Widget? icon,
    bool barrierDismissible = true,
  }) {
    return M3EDialog.show<T>(
      context,
      barrierDismissible: barrierDismissible,
      dialog: Builder(
        builder: (dialogContext) => M3EDialog(
          title: title,
          icon: icon,
          content: content,
          actions: actions(dialogContext),
        ),
      ),
    );
  }
}
