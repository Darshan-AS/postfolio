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
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';

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
      body: switch (depositsState) {
        AsyncData(:final value) => _buildDataState(context, ref, value),
        AsyncError(:final error) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
        _ => _buildLoadingState(),
      },
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => const RecurringDepositCreateRoute().push(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: AppDimensions.iconMd,
        ),
        label: Text(t.recurringDeposits.newDeposit),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    WidgetRef ref,
    List<RecurringDeposit> deposits,
  ) {
    if (deposits.isEmpty) {
      return Center(child: Text(t.recurringDeposits.noDepositsFound));
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(recurringDepositsControllerProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: deposits.length,
        separatorBuilder: (context, index) => const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final deposit = deposits[index];
          return Consumer(
            builder: (context, ref, child) {
              final customerAsync =
                  ref.watch(customerByIdProvider(deposit.customerId));
              final customerName =
                  customerAsync.value?.name ?? deposit.accountNo;

              return RecurringDepositCard(
                title: customerName,
                subtitle: deposit.serialNo.isNotEmpty
                    ? '(${deposit.serialNo}) ${deposit.accountNo}'
                    : deposit.accountNo,
                installmentAmount: deposit.installmentAmount,
                status: deposit.status,
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
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.listBottomPaddingFAB,
        ),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(height: AppDimensions.dividerHeight),
        itemBuilder: (context, index) {
          final dummy = RecurringDeposit.dummy;
          return RecurringDepositCard(
            title: dummy.accountNo,
            subtitle: dummy.accountNo,
            installmentAmount: dummy.installmentAmount,
            status: dummy.status,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
          );
        },
      ),
    );
  }
}
