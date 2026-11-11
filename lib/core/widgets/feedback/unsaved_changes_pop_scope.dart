import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';

/// Tracks whether a form's live inputs have diverged from their initial baseline snapshot.
bool useIsFormDirty(
  List<Listenable> listenables,
  String Function() snapshot,
) {
  final baseline = useMemoized(snapshot, const []);
  final merged = useMemoized(() => Listenable.merge(listenables), listenables);
  useListenable(merged);
  return snapshot() != baseline;
}

/// Prompts for confirmation before discarding unsaved form edits on system/AppBar Back
/// (`Navigator.maybePop`), while allowing programmatic `Navigator.pop()` after Save.
class UnsavedChangesPopScope extends StatelessWidget {
  const UnsavedChangesPopScope({
    super.key,
    required this.isDirty,
    required this.child,
  });

  final bool isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final scheme = Theme.of(context).colorScheme;
        final discard = await AppDialogs.confirmAction(
          context,
          title: 'Discard unsaved changes?',
          content: 'You have unsaved edits. Leave this form without saving?',
          confirmText: 'Discard',
          confirmBackgroundColor: scheme.errorContainer,
          confirmForegroundColor: scheme.onErrorContainer,
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }
}
