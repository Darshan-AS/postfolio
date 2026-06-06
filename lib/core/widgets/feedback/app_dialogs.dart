import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppDialogs {
  static Future<bool?> confirmDelete(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning, color: theme.colorScheme.error),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            onPressed: () => ctx.pop(true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  static Future<bool?> confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: icon != null
            ? Icon(icon, color: theme.colorScheme.primary)
            : null,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor:
                  confirmBackgroundColor ?? theme.colorScheme.primaryContainer,
              foregroundColor:
                  confirmForegroundColor ??
                  theme.colorScheme.onPrimaryContainer,
            ),
            onPressed: () => ctx.pop(true),
            child: Text(confirmText ?? t.common.ok),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.ok)),
        ],
      ),
    );
  }
}
