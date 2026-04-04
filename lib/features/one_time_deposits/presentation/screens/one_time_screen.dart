import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
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
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.primary,
            ),
            AppSpacings.gapSm,
            Text(
              t.oneTimeDeposits.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(oneTimeDepositsControllerProvider),
          ),
        ],
      ),
      body: depositsState.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return Center(child: Text(t.oneTimeDeposits.noDepositsFound));
          }
          return ListView.separated(
            itemCount: deposits.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              return OneTimeDepositCard(
                accountNo: deposit.accountNo,
                schemeName: deposit.schemeType.displayName,
                principalAmount: deposit.principalAmount,
                onTap: () => context.push(RouteNames.oneTimeDetail(deposit.id)),
                onEdit: () => context.push(RouteNames.oneTimeEdit(deposit.id)),
                onDelete: () {
                  ref
                      .read(oneTimeDepositsControllerProvider.notifier)
                      .deleteOneTimeDeposit(deposit.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.oneTimeCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}
