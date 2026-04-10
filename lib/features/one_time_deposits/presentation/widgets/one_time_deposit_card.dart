import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositCard extends ConsumerWidget {
  static final _dateFormatter = DateFormat('MMM dd, yyyy');

  final String customerId;
  final String accountNo;
  final double principalAmount;
  final DepositStatus status;
  final DateTime maturityDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OneTimeDepositCard({
    super.key,
    required this.customerId,
    required this.accountNo,
    required this.principalAmount,
    required this.status,
    required this.maturityDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerName =
        ref.watch(customerByIdProvider(customerId))?.name ?? customerId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLg,
        vertical: AppDimensions.paddingSm,
      ),
      leading: CircleAvatar(
        radius: AppDimensions.radiusXxl,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: const Icon(Icons.account_balance_wallet_outlined),
      ),
      title: Text(
        customerName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: accountNo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const WidgetSpan(child: AppSpacings.gapSm),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: StatusBadge(status: status.displayName, compact: true),
            ),
            const WidgetSpan(child: AppSpacings.gapSm),
            TextSpan(
              text: '• ${_dateFormatter.format(maturityDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${principalAmount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: AppDimensions.iconMd),
                    AppSpacings.gapSm,
                    Text(t.common.edit),
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
                      'Delete',
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
