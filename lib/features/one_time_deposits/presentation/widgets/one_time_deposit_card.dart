import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/models/base_deposit.dart';

import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositCard extends ConsumerWidget {
  final OneTimeDeposit deposit;
  final String? overrideTitle;

  /// Replaces the account number under the title; empty for no line there.
  final String? overrideSubtitle;

  /// Where this row sits in its list (see [EntityListTile.position]).
  final AppGroupPosition position;

  const OneTimeDepositCard({
    super.key,
    required this.deposit,
    this.overrideTitle,
    this.overrideSubtitle,
    this.position = AppGroupPosition.single,
  });

  static Widget skeleton({AppGroupPosition position = AppGroupPosition.single}) {
    final dummy = OneTimeDeposit.dummy;
    return _OneTimeDepositTile(
      deposit: dummy,
      title: dummy.accountNo ?? t.common.loading,
      subtitle: dummy.accountNo ?? t.common.loading,
      urgency: MaturityUrgency.normal,
      relativeTimeText: '',
      position: position,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = (overrideTitle?.isNotEmpty == true ? overrideTitle : null) ??
        (deposit.customerName?.isNotEmpty == true
            ? deposit.customerName
            : null) ??
        deposit.accountNo ??
        t.common.notProvided;

    return _OneTimeDepositTile(
      deposit: deposit,
      title: title,
      subtitle: overrideSubtitle ?? (deposit.accountNo ?? t.common.notProvided),
      urgency: deposit.maturityUrgency,
      relativeTimeText: deposit.maturityRelativeTime,
      position: position,
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
            AppFeedback.showError(
              context,
              t.oneTimeDeposits.failedToDeleteDeposit(
                error: (result as Failure).error.toString(),
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
            AppFeedback.showError(
              context,
              (result as Failure).error.toString(),
            );
          }
        }
      },
    );
  }
}

/// Maps a one-time deposit onto the shared [DepositListTile].
class _OneTimeDepositTile extends StatelessWidget {
  const _OneTimeDepositTile({
    required this.deposit,
    required this.title,
    required this.subtitle,
    required this.urgency,
    required this.relativeTimeText,
    required this.position,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  final OneTimeDeposit deposit;
  final String title;
  final String subtitle;
  final MaturityUrgency urgency;
  final String relativeTimeText;
  final AppGroupPosition position;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DepositListTile(
      position: position,
      title: title,
      subtitle: subtitle,
      avatarText: deposit.schemeType.shortName,
      avatarSubtext: deposit.schemeTermLabel,
      avatarShape: deposit.schemeType.avatarShape,
      avatarBackgroundColor: scheme.primaryContainer,
      avatarForegroundColor: scheme.onPrimaryContainer,
      amount: deposit.principalAmount,
      amountColor: scheme.primary,
      status: deposit.status,
      urgency: urgency,
      relativeTimeText: relativeTimeText,
      maturityDate: deposit.maturityDate,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      onToggleStatus: onToggleStatus,
    );
  }
}
