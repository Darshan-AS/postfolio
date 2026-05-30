import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/entity_list_tile.dart';
import 'package:postfolio/core/extensions/double_extension.dart';

class OneTimeDepositCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double principalAmount;
  final DepositStatus status;
  final MaturityUrgency urgency;
  final String? relativeTimeText;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OneTimeDepositCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.principalAmount,
    required this.status,
    this.urgency = MaturityUrgency.normal,
    this.relativeTimeText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color? indicatorColor;
    if (urgency == MaturityUrgency.overdue) {
      indicatorColor = Theme.of(context).colorScheme.errorContainer;
    } else if (urgency == MaturityUrgency.maturingSoon) {
      indicatorColor = Theme.of(context).colorScheme.tertiaryContainer;
    }

    return EntityListTile(
      indicatorColor: indicatorColor,
      leadingIcon: const HugeIcon(
        icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
        size: AppDimensions.iconMd,
      ),
      leadingBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      leadingForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      title: title,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
              principalAmount.toRupeeFormat(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapXs,
            StatusBadge(
              status: status.displayName,
              compact: true,
              urgency: urgency,
              relativeTimeText: relativeTimeText,
            ),
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
