import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/entity_list_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

class OneTimeDepositCard extends ConsumerWidget {
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
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
        size: AppDimensions.iconMd,
      ),
      leadingBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      leadingForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      title: customerName,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Text(
          '$accountNo${t.format.bulletSeparator}${maturityDate.toAppFormat()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onTap: onTap,
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${t.format.currencySymbol}${principalAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapXs,
            StatusBadge(status: status.displayName, compact: true),
          ],
        ),
      ),
      actions: [
        EntityAction.edit(onTap: onEdit),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}
