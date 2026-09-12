import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RDTransactionsSection extends HookConsumerWidget {
  final RecurringDeposit deposit;

  const RDTransactionsSection({super.key, required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ExpansionTile(
        title: Text(
          t.recurringDeposits.ledger.transactionsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar01,
          size: AppDimensions.iconMd,
        ),
        onExpansionChanged: (val) {
          isExpanded.value = val;
        },
        children: [
          if (isExpanded.value)
            _RDTransactionsContent(deposit: deposit)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RDTransactionsContent extends ConsumerWidget {
  final RecurringDeposit deposit;

  const _RDTransactionsContent({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(rdTransactionsStreamProvider(deposit.id));
    final installments =
        ref.watch(rdInstallmentsStreamProvider(deposit.id)).value ?? const [];
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Center(
              child: Text(ledger.noPayments),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) =>
              const Divider(height: AppDimensions.dividerHeight),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return RDTransactionTile(
              deposit: deposit,
              transaction: tx,
              allTransactions: transactions,
              currentSchedule: installments,
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Center(
          child: Text(
            '${t.common.error}: $err',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class RDTransactionTile extends ConsumerWidget {
  final RecurringDeposit deposit;
  final RDTransaction transaction;
  final List<RDTransaction> allTransactions;
  final List<RDInstallment> currentSchedule;

  const RDTransactionTile({
    super.key,
    required this.deposit,
    required this.transaction,
    required this.allTransactions,
    required this.currentSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final tx = transaction;

    List<List<dynamic>> modeIcon;
    switch (tx.paymentMode) {
      case RDPaymentMode.cash:
        modeIcon = HugeIcons.strokeRoundedCoins01;
        break;
      case RDPaymentMode.upi:
        modeIcon = HugeIcons.strokeRoundedCreditCard;
        break;
      case RDPaymentMode.cheque:
        modeIcon = HugeIcons.strokeRoundedTicket01;
        break;
      case RDPaymentMode.bankTransfer:
        modeIcon = HugeIcons.strokeRoundedBank;
        break;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSm),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: modeIcon,
          size: AppDimensions.iconSm,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        tx.amount.toRupeeFormat(),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        ledger.installmentDetails.paidOnVia(
          date: tx.paidDate.toAppFormat(),
          mode: tx.paymentMode.displayName,
        ),
      ),
      trailing: MenuAnchor(
        builder: (context, controller, child) {
          return IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              size: AppDimensions.iconMd,
            ),
            tooltip: t.common.moreOptions,
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          );
        },
        menuChildren: [
          MenuItemButton(
            leadingIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: AppDimensions.iconSm,
            ),
            child: Text(ledger.actions.editPayment),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => RDEditPaymentSheet(
                  deposit: deposit,
                  transaction: tx,
                  allTransactions: allTransactions,
                  currentSchedule: currentSchedule,
                ),
              );
            },
          ),
          MenuItemButton(
            leadingIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: AppDimensions.iconSm,
              color: theme.colorScheme.error,
            ),
            child: Text(
              ledger.actions.deletePayment,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onPressed: () async {
              final confirmed = await AppDialogs.confirmAction(
                context,
                title: ledger.actions.deletePaymentTitle,
                content: ledger.actions.deletePaymentContent(
                  amount: tx.amount.toRupeeFormat(),
                  date: tx.paidDate.toAppFormat(),
                ),
                confirmText: t.common.delete,
                confirmBackgroundColor: theme.colorScheme.errorContainer,
                confirmForegroundColor: theme.colorScheme.onErrorContainer,
              );

              if (confirmed == true && context.mounted) {
                final result = await ref
                    .read(rDLedgerControllerProvider.notifier)
                    .deleteCustomerPayment(
                      transactionId: tx.id,
                      deposit: deposit,
                      currentSchedule: currentSchedule,
                      currentTransactions: allTransactions,
                    );

                if (context.mounted) {
                  if (result is Success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(ledger.paymentDeleted),
                      ),
                    );
                  } else if (result is Failure<void, String>) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(result.error),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

