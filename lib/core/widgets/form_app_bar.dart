import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/theme/app_dimensions.dart';

class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSaving;
  final VoidCallback onSave;

  const FormAppBar({
    super.key,
    required this.title,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
            child: Center(
              child: SizedBox(
                width: AppDimensions.iconMd,
                height: AppDimensions.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedTick01),
            onPressed: onSave,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
