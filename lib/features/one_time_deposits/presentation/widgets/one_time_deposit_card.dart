import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';

import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/core/widgets/entity_list_tile.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';

import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double principalAmount;
  final DepositStatus status;
  final MaturityUrgency urgency;
  final String? relativeTimeText;
  final DateTime? maturityDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleStatus;

  const OneTimeDepositCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.principalAmount,
    required this.status,
    this.urgency = MaturityUrgency.normal,
    this.relativeTimeText,
    this.maturityDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color? indicatorColor;
    if (urgency == MaturityUrgency.matured) {
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
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (relativeTimeText != null &&
                (urgency == MaturityUrgency.maturingSoon ||
                    urgency == MaturityUrgency.matured)) ...[
              if (subtitle.isNotEmpty) AppSpacings.gapXs,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTimer02,
                    size: AppDimensions.iconSm,
                    color: urgency == MaturityUrgency.matured
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    relativeTimeText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: urgency == MaturityUrgency.matured
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
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
            if (maturityDate != null) ...[
              AppSpacings.gapXs,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconSm,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    maturityDate!.toAppFormat(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            AppSpacings.gapXs,
            StatusBadge(
              status: status.displayName,
              compact: true,
              urgency: urgency,
            ),
          ],
        ),
      ),
      actions: [
        if (onToggleStatus != null)
          if (status == DepositStatus.active)
            EntityAction(
              label: t.common.close,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: AppDimensions.iconMd,
              ),
              onTap: onToggleStatus!,
            )
          else if (status == DepositStatus.closed)
            EntityAction(
              label: t.common.reopen,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconMd,
              ),
              onTap: onToggleStatus!,
            ),
        EntityAction.edit(onTap: onEdit),
        EntityAction.delete(onTap: onDelete),
      ],
    );
  }
}
