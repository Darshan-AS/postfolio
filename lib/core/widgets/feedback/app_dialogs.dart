import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
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
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAlert02,
          size: AppDimensions.iconLg,
          color: theme.colorScheme.error,
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
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
    List<List<dynamic>>? icon,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: icon != null
            ? HugeIcon(
                icon: icon,
                size: AppDimensions.iconLg,
                color: theme.colorScheme.primary,
              )
            : null,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
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
            onPressed: () => Navigator.of(ctx).pop(true),
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
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          size: AppDimensions.iconLg,
          color: theme.colorScheme.error,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
  }
}
