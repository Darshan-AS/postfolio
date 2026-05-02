import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RecurringDepositsScreen extends ConsumerWidget {
  const RecurringDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(recurringDepositsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            size: AppDimensions.iconMd,
          ),
          onPressed: () {},
        ),
        title: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTransaction,
              size: AppDimensions.iconMd,
              color: Theme.of(context).colorScheme.secondary,
            ),
            AppSpacings.gapSm,
            Text(
              t.recurringDeposits.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: AppDimensions.iconMd,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: depositsState.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return Center(child: Text(t.recurringDeposits.noDepositsFound));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(recurringDepositsControllerProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.listBottomPaddingFAB,
              ),
              itemCount: deposits.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final deposit = deposits[index];
                return RecurringDepositCard(
                  customerId: deposit.customerId,
                  serialNo: deposit.serialNo,
                  accountNo: deposit.accountNo,
                  installmentAmount: deposit.installmentAmount,
                  status: deposit.status,
                  maturityDate: deposit.maturityDate,
                  onTap: () =>
                      RecurringDepositDetailRoute(deposit.id).push(context),
                  onEdit: () =>
                      RecurringDepositEditRoute(deposit.id).push(context),
                  onDelete: () async {
                    final confirmed = await AppDialogs.confirmDelete(
                      context,
                      title: t.recurringDeposits.deleteDeposit,
                      content: t.recurringDeposits.deleteDepositConfirmation,
                    );
                    if (confirmed == true) {
                      final result = await ref
                          .read(recurringDepositsControllerProvider.notifier)
                          .deleteRecurringDeposit(deposit.id);

                      if (result is Failure && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t.recurringDeposits.failedToDeleteDeposit(
                                error: (result as Failure).error.toString(),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(
              bottom: AppDimensions.listBottomPaddingFAB,
            ),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dummy = RecurringDeposit.dummy;
              return RecurringDepositCard(
                customerId: dummy.customerId,
                serialNo: dummy.serialNo,
                accountNo: dummy.accountNo,
                installmentAmount: dummy.installmentAmount,
                status: dummy.status,
                maturityDate: dummy.maturityDate,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              );
            },
          ),
        ),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const RecurringDepositCreateRoute().push(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: AppDimensions.iconMd,
        ),
        label: Text(t.recurringDeposits.newDeposit),
      ),
    );
  }
}
