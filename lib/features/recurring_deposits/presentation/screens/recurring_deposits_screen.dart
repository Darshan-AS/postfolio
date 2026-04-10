import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
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
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(recurringDepositsControllerProvider),
          ),
        ],
      ),
      body: depositsState.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return Center(child: Text(t.recurringDeposits.noDepositsFound));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingSm,
            ),
            itemCount: deposits.length,
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingSm),
                child: RecurringDepositCard(
                  customerId: deposit.customerId,
                  serialNo: deposit.serialNo,
                  accountNo: deposit.accountNo,
                  installmentAmount: deposit.installmentAmount,
                  status: deposit.status,
                  maturityDate: deposit.maturityDate,
                  onTap: () => context.push(RouteNames.rdDetail(deposit.id)),
                  onEdit: () => context.push(RouteNames.rdEdit(deposit.id)),
                  onDelete: () {
                    ref
                        .read(recurringDepositsControllerProvider.notifier)
                        .deleteRecurringDeposit(deposit.id);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.rdCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}
