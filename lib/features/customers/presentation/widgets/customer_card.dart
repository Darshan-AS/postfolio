import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import '../../../../i18n/strings.g.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

class _CustomerCardView extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPhoneTapped;
  final VoidCallback? onWhatsAppTapped;

  const _CustomerCardView({
    required this.name,
    this.phone,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPhoneTapped,
    this.onWhatsAppTapped,
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
        if (hasPhone && onPhoneTapped != null)
          EntityAction(
            label: t.customers.actions.call,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCall02,
              size: AppDimensions.iconMd,
            ),
            onTap: onPhoneTapped!,
            isInline: true,
          ),
        if (hasPhone && onWhatsAppTapped != null)
          EntityAction(
            label: t.customers.actions.whatsapp,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedWhatsapp,
              size: AppDimensions.iconMd,
            ),
            onTap: onWhatsAppTapped!,
            isInline: true,
          ),
        if (onEdit != null) EntityAction.edit(onTap: onEdit!),
        if (onDelete != null) EntityAction.delete(onTap: onDelete!),
      ],
    );
  }
}

class CustomerCard extends ConsumerWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

  static Widget skeleton() {
    final dummy = Customer.dummy;
    return _CustomerCardView(name: dummy.name, phone: dummy.phone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CustomerCardView(
      name: customer.name,
      phone: customer.phone,
      onTap: () => CustomerDetailRoute(customer.id).push(context),
      onEdit: () => CustomerEditRoute(customer.id).push(context),
      onPhoneTapped: () =>
          ref.read(intentServiceProvider).launchPhone(customer.phone ?? ''),
      onWhatsAppTapped: () =>
          ref.read(intentServiceProvider).launchWhatsApp(customer.phone ?? ''),
      onDelete: () async {
        final confirmed = await AppDialogs.confirmDelete(
          context,
          title: t.customers.deleteCustomer,
          content: t.customers.deleteCustomerConfirmation,
        );
        if (confirmed == true && context.mounted) {
          final result = await ref
              .read(customersControllerProvider.notifier)
              .deleteCustomer(customer.id);

          if (result is Failure && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.customers.failedToDeleteCustomer(
                    error: (result as Failure).error.toString(),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
