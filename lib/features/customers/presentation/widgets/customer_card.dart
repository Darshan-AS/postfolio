import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/entity_list_tile.dart';
import '../../../../i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

class CustomerCard extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPhoneTapped;
  final VoidCallback onWhatsAppTapped;
  final VoidCallback onSmsTapped;
  final VoidCallback onLocationTapped;

  const CustomerCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPhoneTapped,
    required this.onWhatsAppTapped,
    required this.onSmsTapped,
    required this.onLocationTapped,
  });

  @override
  Widget build(BuildContext context) {
    return EntityListTile(
      leadingText: name.isNotEmpty ? name[0].toUpperCase() : '?',
      title: name,
      subtitle: phone.isNotEmpty && phone != t.common.notProvided
          ? Text(
              phone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: onTap,
      actions: [
        EntityAction.edit(onTap: onEdit, isInline: true),
        EntityAction(
          type: EntityActionType.call,
          label: t.customers.actions.call,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCall02,
            size: AppDimensions.iconMd,
          ),
          onTap: onPhoneTapped,
          isInline: true,
        ),
        EntityAction(
          type: EntityActionType.whatsapp,
          label: t.customers.actions.whatsapp,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedWhatsapp,
            size: AppDimensions.iconMd,
          ),
          onTap: onWhatsAppTapped,
          isInline: true,
        ),
        EntityAction(
          type: EntityActionType.sms,
          label: t.customers.actions.sms,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedComment01,
            size: AppDimensions.iconMd,
          ),
          onTap: onSmsTapped,
        ),
        EntityAction(
          type: EntityActionType.location,
          label: t.customers.actions.location,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            size: AppDimensions.iconMd,
          ),
          onTap: onLocationTapped,
        ),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}
