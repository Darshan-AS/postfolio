import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/widgets/entity_list_tile.dart';
import '../../../../i18n/strings.g.dart';

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
          icon: Icons.phone_outlined,
          onTap: onPhoneTapped,
          isInline: true,
        ),
        EntityAction(
          type: EntityActionType.whatsapp,
          label: t.customers.actions.whatsapp,
          customIcon: const FaIcon(FontAwesomeIcons.whatsapp, size: 24.0),
          onTap: onWhatsAppTapped,
          isInline: true,
        ),
        EntityAction(
          type: EntityActionType.sms,
          label: t.customers.actions.sms,
          icon: Icons.message_outlined,
          onTap: onSmsTapped,
        ),
        EntityAction(
          type: EntityActionType.location,
          label: t.customers.actions.location,
          icon: Icons.location_on_outlined,
          onTap: onLocationTapped,
        ),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}

