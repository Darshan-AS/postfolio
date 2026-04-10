import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/app_dialogs.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositsScreen extends ConsumerWidget {
  const OneTimeDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(oneTimeDepositsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppSpacings.gapSm,
            Text(
              t.oneTimeDeposits.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: depositsState.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return Center(child: Text(t.oneTimeDeposits.noDepositsFound));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(oneTimeDepositsControllerProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.listBottomPaddingFAB,
              ),
              itemCount: deposits.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final deposit = deposits[index];
                return OneTimeDepositCard(
                  customerId: deposit.customerId,
                  accountNo: deposit.accountNo,
                  principalAmount: deposit.principalAmount,
                  status: deposit.status,
                  maturityDate: deposit.maturityDate,
                  onTap: () =>
                      OneTimeDepositDetailRoute(deposit.id).push(context),
                  onEdit: () =>
                      OneTimeDepositEditRoute(deposit.id).push(context),
                  onDelete: () async {
                    final confirmed = await AppDialogs.confirmDelete(
                      context,
                      title: t.oneTimeDeposits.deleteDeposit,
                      content: t.oneTimeDeposits.deleteDepositConfirmation,
                    );
                    if (confirmed == true) {
                      ref
                          .read(oneTimeDepositsControllerProvider.notifier)
                          .deleteOneTimeDeposit(deposit.id);
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => const OneTimeDepositCreateRoute().push(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
