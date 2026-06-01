import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/models/base_deposit.dart';

import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class _OneTimeDepositCardView extends StatelessWidget {
  final String title;
  final String subtitle;
  final double principalAmount;
  final DepositStatus status;
  final MaturityUrgency urgency;
  final String relativeTimeText;
  final DateTime maturityDate;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const _OneTimeDepositCardView({
    required this.title,
    required this.subtitle,
    required this.principalAmount,
    required this.status,
    required this.urgency,
    required this.relativeTimeText,
    required this.maturityDate,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
            if (urgency == MaturityUrgency.maturingSoon ||
                urgency == MaturityUrgency.matured) ...[
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
                    relativeTimeText,
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
            ...[
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
                    maturityDate.toAppFormat(),
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
        if (onEdit != null) EntityAction.edit(onTap: onEdit!),
        if (onDelete != null) EntityAction.delete(onTap: onDelete!),
      ],
    );
  }
}

class OneTimeDepositCard extends ConsumerWidget {
  final OneTimeDeposit deposit;
  final String? overrideTitle;

  const OneTimeDepositCard({
    super.key,
    required this.deposit,
    this.overrideTitle,
  });

  static Widget skeleton() {
    final dummy = OneTimeDeposit.dummy;
    return _OneTimeDepositCardView(
      title: dummy.accountNo ?? 'Loading...',
      subtitle: dummy.accountNo ?? 'Loading...',
      principalAmount: dummy.principalAmount,
      status: dummy.status,
      urgency: MaturityUrgency.normal,
      relativeTimeText: '',
      maturityDate: dummy.maturityDate,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = overrideTitle ?? '';
    if (title.isEmpty) {
      final customerAsync = ref.watch(customerByIdProvider(deposit.customerId));
      title =
          customerAsync.value?.name ??
          (deposit.accountNo ?? t.common.notProvided);
    }

    return _OneTimeDepositCardView(
      title: title,
      subtitle: deposit.accountNo ?? t.common.notProvided,
      principalAmount: deposit.principalAmount,
      status: deposit.status,
      urgency: deposit.maturityUrgency,
      relativeTimeText: deposit.maturityRelativeTime,
      maturityDate: deposit.maturityDate,
      onTap: () => OneTimeDepositDetailRoute(deposit.id).push(context),
      onEdit: () => OneTimeDepositEditRoute(deposit.id).push(context),
      onDelete: () async {
        final confirmed = await AppDialogs.confirmDelete(
          context,
          title: t.oneTimeDeposits.deleteDeposit,
          content: t.oneTimeDeposits.deleteDepositConfirmation,
        );
        if (confirmed == true && context.mounted) {
          final result = await ref
              .read(oneTimeDepositsControllerProvider.notifier)
              .deleteOneTimeDeposit(deposit.id);

          if (result is Failure && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.oneTimeDeposits.failedToDeleteDeposit(
                    error: (result as Failure).error.toString(),
                  ),
                ),
              ),
            );
          }
        }
      },
      onToggleStatus: () async {
        final isActive = deposit.status == DepositStatus.active;
        final confirmed = await AppDialogs.confirmAction(
          context,
          title: isActive ? t.common.close : t.common.reopen,
          content: isActive
              ? t.oneTimeDeposits.closeDepositConfirmation
              : t.oneTimeDeposits.reopenDepositConfirmation,
          confirmText: isActive ? t.common.close : t.common.reopen,
        );
        if (confirmed == true && context.mounted) {
          final newStatus = isActive
              ? DepositStatus.closed
              : DepositStatus.active;
          final result = await ref
              .read(oneTimeDepositsControllerProvider.notifier)
              .toggleDepositStatus(deposit.id, newStatus);

          if (result is Failure && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text((result as Failure).error.toString())),
            );
          }
        }
      },
    );
  }
}
