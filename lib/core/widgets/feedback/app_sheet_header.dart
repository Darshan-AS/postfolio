import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Header shared by the sort and filter sheets: title, a "clear" action and close.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title, this.onClear});

  final String title;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.emphasizedOf(context).titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onClear != null)
          AppButton.text(label: t.common.clear, onPressed: onClear),
        IconButton(
          tooltip: t.common.close,
          onPressed: () => Navigator.of(context).pop(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: AppDimensions.iconMd,
          ),
        ),
      ],
    );
  }
}
