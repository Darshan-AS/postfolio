import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/intent_service.dart';
import '../../../../i18n/strings.g.dart';

class CustomerCard extends ConsumerWidget {
  final String name;
  final String phone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingXs,
      ),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
            onPressed: () => ref.read(intentServiceProvider).launchPhone(phone),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
            tooltip: t.customers.actions.whatsapp,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () =>
                ref.read(intentServiceProvider).launchWhatsApp(phone),
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
                  ref.read(intentServiceProvider).launchSms(phone);
                  break;
                case 'location':
                  ref.read(intentServiceProvider).launchMapSearch(name);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    const Icon(Icons.message_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(t.customers.actions.sms),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20),
                    SizedBox(width: 12),
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
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.common.delete,
                      style: TextStyle(
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
