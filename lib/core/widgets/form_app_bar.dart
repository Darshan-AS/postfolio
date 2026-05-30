import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/theme/app_dimensions.dart';

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
      title: Text(title),
      leading: onBack != null ? BackButton(onPressed: onBack) : null,
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
            child: Center(
              child: SizedBox(
                width: AppDimensions.iconMd,
                height: AppDimensions.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: AppDimensions.strokeWidthSm,
                ),
              ),
            ),
          )
        else
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              size: AppDimensions.iconMd,
            ),
            onPressed: onSave,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
