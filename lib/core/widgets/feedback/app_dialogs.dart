import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_dialog.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

class AppDialogs {
  static Future<bool?> confirmDelete(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return AppDialog.show<bool>(
      context,
      icon: AppIcon(
        HugeIcons.strokeRoundedAlert02,
        size: AppDimensions.iconLg,
        color: theme.colorScheme.error,
      ),
      title: title,
      content: Text(content),
      actions: (ctx) => [
        AppButton.text(
          label: t.common.cancel,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppButton.tonal(
          label: t.common.delete,
          isDestructive: true,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    );
  }

  static Future<bool?> confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    bool isDestructive = false,
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    List<List<dynamic>>? icon,
  }) {
    final theme = Theme.of(context);
    final resolvedIconColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AppDialog.show<bool>(
      context,
      icon: icon != null
          ? AppIcon(icon, size: AppDimensions.iconLg, color: resolvedIconColor)
          : null,
      title: title,
      content: Text(content),
      actions: (ctx) => [
        AppButton.text(
          label: t.common.cancel,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppButton.tonal(
          label: confirmText ?? t.common.ok,
          isDestructive: isDestructive,
          backgroundColor: isDestructive ? null : confirmBackgroundColor,
          foregroundColor: isDestructive ? null : confirmForegroundColor,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return AppDialog.show<void>(
      context,
      icon: AppIcon(
        HugeIcons.strokeRoundedAlertCircle,
        size: AppDimensions.iconLg,
        color: theme.colorScheme.error,
      ),
      title: title,
      content: Text(message),
      actions: (ctx) => [
        AppButton.text(
          label: t.common.ok,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    );
  }
}
