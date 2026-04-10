import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositsScreen extends ConsumerWidget {
  const RecurringDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(recurringDepositsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          children: [
            const Icon(Icons.loop_outlined, color: AppTheme.accent),
            AppSpacings.gapSm,
            Text(
              t.recurringDeposits.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
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
                  onDelete: () {
                    ref
                        .read(recurringDepositsControllerProvider.notifier)
                        .deleteRecurringDeposit(deposit.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => const RecurringDepositCreateRoute().push(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
