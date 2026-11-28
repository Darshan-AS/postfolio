import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/models/base_deposit.dart';

import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositCard extends ConsumerWidget {
  final RecurringDeposit deposit;

  /// Title the row by its account number instead of the customer's name, with no second
  /// line. For rows on the customer's screen: the customer is the screen.
  final bool titleByAccount;

  /// Where this row is, for the avatar and the account number that travel to the head of
  /// the deposit's screen (`EntityHero.tagFrom`).
  final String heroOrigin;

  /// Where this row sits in its list (see [EntityListTile.position]).
  final AppGroupPosition position;

  const RecurringDepositCard({
    super.key,
    required this.deposit,
    this.titleByAccount = false,
    this.heroOrigin = EntityHero.ownList,
    this.position = AppGroupPosition.single,
  });

  static Widget skeleton({
    AppGroupPosition position = AppGroupPosition.single,
  }) {
    final dummy = RecurringDeposit.dummy;
    return _RecurringDepositTile(
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
    final today = ref.watch(currentDateProvider);
    final accountNo = deposit.accountNo ?? t.common.notProvided;
    final customerName = deposit.customerName ?? '';

    return _RecurringDepositTile(
      deposit: deposit,
      title: titleByAccount || customerName.isEmpty ? accountNo : customerName,
      subtitle: titleByAccount ? '' : accountNo,
      urgency: deposit.maturityUrgencyAt(today),
      relativeTimeText: deposit.maturityRelativeTimeAt(today),
      position: position,
      heroTag: EntityHero.tagFrom(heroOrigin, deposit.id),
      titleIsAccount: titleByAccount,
      onTap: () => RecurringDepositDetailRoute(
        deposit.id,
        $extra: heroOrigin,
      ).push(context),
      onEdit: () => RecurringDepositEditRoute(deposit.id).push(context),
      onDelete: () async {
        final confirmed = await AppDialogs.confirmDelete(
          context,
          title: t.recurringDeposits.deleteDeposit,
          content: t.recurringDeposits.deleteDepositConfirmation,
        );
        if (confirmed == true && context.mounted) {
          final result = await ref
              .read(recurringDepositsControllerProvider.notifier)
              .deleteRecurringDeposit(deposit.id);

          if (result is Failure && context.mounted) {
            AppFeedback.showError(
              context,
              t.recurringDeposits.failedToDeleteDeposit(
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
          title: isActive ? t.common.closeDeposit : t.common.reopenDeposit,
          content: isActive
              ? t.recurringDeposits.closeDepositConfirmation
              : t.recurringDeposits.reopenDepositConfirmation,
          confirmText: isActive ? t.common.close : t.common.reopen,
        );
        if (confirmed == true && context.mounted) {
          final newStatus = isActive
              ? DepositStatus.closed
              : DepositStatus.active;
          final result = await ref
              .read(recurringDepositsControllerProvider.notifier)
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

/// Maps a recurring deposit onto the shared [DepositListTile].
class _RecurringDepositTile extends StatelessWidget {
  const _RecurringDepositTile({
    required this.deposit,
    required this.title,
    required this.subtitle,
    required this.urgency,
    required this.relativeTimeText,
    required this.position,
    this.heroTag,
    this.titleIsAccount = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  final Object? heroTag;
  final bool titleIsAccount;

  final RecurringDeposit deposit;
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
      heroTag: heroTag,
      titleIsAccount: titleIsAccount,
      title: title,
      subtitle: subtitle,
      avatarText: deposit.avatarLabel,
      avatarShape: RecurringSchemeType.recurringDeposit.avatarShape,
      avatarBackgroundColor: scheme.secondaryContainer,
      avatarForegroundColor: scheme.onSecondaryContainer,
      amount: deposit.installmentAmount,
      amountColor: scheme.secondary,
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
