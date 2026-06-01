import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import '../../../../i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/extensions/string_extension.dart';

class CustomerCard extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPhoneTapped;
  final VoidCallback onWhatsAppTapped;

  const CustomerCard({
    super.key,
    required this.name,
    this.phone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPhoneTapped,
    required this.onWhatsAppTapped,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.isNotEmpty;

    return EntityListTile(
      leadingText: name.isNotEmpty ? name[0].toUpperCase() : '?',
      title: name,
      subtitle: Text(
        hasPhone ? phone!.toPhoneFormat() : t.common.notProvided,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
      actions: [
        if (hasPhone) ...[
          EntityAction(
            label: t.customers.actions.call,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCall02,
              size: AppDimensions.iconMd,
            ),
            onTap: onPhoneTapped,
            isInline: true,
          ),
          EntityAction(
            label: t.customers.actions.whatsapp,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedWhatsapp,
              size: AppDimensions.iconMd,
            ),
            onTap: onWhatsAppTapped,
            isInline: true,
          ),
        ],
        EntityAction.edit(onTap: onEdit),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}
