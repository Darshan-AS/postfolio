import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';

/// App bar of a create / edit form: back, the form's title and a filled confirm button that
/// turns into a loading indicator while the form is saving.
class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onBack;

  const FormAppBar({
    super.key,
    required this.title,
    required this.isSaving,
    required this.onSave,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AppBarTitle(title),
      leading: onBack != null ? BackButton(onPressed: onBack) : null,
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
            child: Center(child: AppLoadingIndicator.inline()),
          )
        else
          IconButton.filled(
            // An app bar wraps its actions in an `IconTheme`, and `IconButton` takes that
            // theme's colour as its foreground ahead of the filled variant's own default,
            // which would draw this icon in `onSurfaceVariant` on `primary`.
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: t.common.confirm,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              size: AppDimensions.iconMd,
            ),
            onPressed: onSave,
          ),
        const SizedBox(width: AppDimensions.paddingSm),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
