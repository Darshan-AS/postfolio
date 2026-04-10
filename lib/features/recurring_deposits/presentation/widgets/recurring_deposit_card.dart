import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

class RecurringDepositCard extends ConsumerWidget {
  static final _dateFormatter = DateFormat('MMM dd, yyyy');

  final String customerId;
  final String serialNo;
  final String accountNo;
  final double installmentAmount;
  final DepositStatus status;
  final DateTime maturityDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecurringDepositCard({
    super.key,
    required this.customerId,
    required this.serialNo,
    required this.accountNo,
    required this.installmentAmount,
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
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.loop_outlined),
      ),
      title: Text(
        customerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: serialNo.isNotEmpty ? '($serialNo) $accountNo' : accountNo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const WidgetSpan(child: SizedBox(width: 8.0)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: StatusBadge(status: status.displayName, compact: true),
            ),
            const WidgetSpan(child: SizedBox(width: 8.0)),
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
            '₹${installmentAmount.toStringAsFixed(0)} / mo',
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
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
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
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
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
