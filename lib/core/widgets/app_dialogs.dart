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
}
