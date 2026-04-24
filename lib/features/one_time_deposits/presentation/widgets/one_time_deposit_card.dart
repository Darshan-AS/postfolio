import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/core/widgets/entity_list_tile.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

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

    return EntityListTile(
      leadingIcon: const HugeIcon(icon: HugeIcons.strokeRoundedMoneyReceiveSquare),
      leadingBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      leadingForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      title: customerName,
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
      trailing: Text(
        '₹${principalAmount.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        EntityAction.edit(onTap: onEdit),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}
