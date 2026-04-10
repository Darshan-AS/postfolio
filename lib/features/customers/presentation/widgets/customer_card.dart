import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_dimensions.dart';
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingSm,
      ),
      onTap: onTap,
      leading: CircleAvatar(
        radius: AppDimensions.radiusXxl,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: phone.isNotEmpty && phone != t.common.notProvided
          ? Text(
              phone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.customers.editCustomer,
            color: Theme.of(context).colorScheme.secondary,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: t.customers.actions.call,
            color: Theme.of(context).colorScheme.primary,
            onPressed: onPhoneTapped,
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: AppDimensions.iconMd,
            ),
            tooltip: t.customers.actions.whatsapp,
            color: Theme.of(context).colorScheme.primary,
            onPressed: onWhatsAppTapped,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete();
                  break;
                case 'sms':
                  onSmsTapped();
                  break;
                case 'location':
                  onLocationTapped();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    const Icon(
                      Icons.message_outlined,
                      size: AppDimensions.iconMd,
                    ),
                    AppSpacings.gapSm,
                    Text(t.customers.actions.sms),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppDimensions.iconMd,
                    ),
                    AppSpacings.gapSm,
                    Text('Location'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: AppDimensions.iconMd,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    AppSpacings.gapSm,
                    Text(
                      t.common.delete,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
