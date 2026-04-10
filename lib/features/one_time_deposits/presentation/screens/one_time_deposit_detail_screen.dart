import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class OneTimeDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const OneTimeDepositDetailScreen({super.key, required this.depositId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.oneTimeDeposits.deleteDeposit),
        content: Text(t.oneTimeDeposits.deleteDepositConfirmation),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(oneTimeDepositsControllerProvider.notifier)
                  .deleteOneTimeDeposit(depositId);

              if (!context.mounted) return;

              switch (result) {
                case Success():
                  ctx.pop();
                  context.pop();
                case Failure(error: final err):
                  ctx.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.oneTimeDeposits.failedToDeleteDeposit(
                          error: err.toString(),
                        ),
                      ),
                    ),
                  );
              }
            },
            child: Text(
              t.common.delete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(oneTimeDepositsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RouteNames.oneTimeEdit(depositId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.error,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: depositsState.when(
        data: (deposits) {
          final deposit = deposits.where((d) => d.id == depositId).firstOrNull;

          if (deposit == null) {
            return Center(child: Text(t.oneTimeDeposits.depositNotFound));
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              const CircleAvatar(
                radius: AppDimensions.iconXl,
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: AppDimensions.iconXl,
                ),
              ),
              AppSpacings.gapLg,
              Text(
                deposit.accountNo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapXxl,
              Card(
                child: Column(
                  children: [
                    _buildInfoTile(
                      Icons.tag_outlined,
                      t.oneTimeDeposits.fields.rowId,
                      deposit.rowId,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.money_outlined,
                      t.oneTimeDeposits.fields.principalAmount,
                      '₹${deposit.principalAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.info_outline,
                      'Status',
                      deposit.status.displayName,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.category_outlined,
                      t.oneTimeDeposits.fields.schemeType,
                      deposit.schemeType.displayName,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.account_circle_outlined,
                      t.oneTimeDeposits.fields.customerId,
                      deposit.customerId,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.savings_outlined,
                      t.oneTimeDeposits.fields.maturityAmount,
                      '₹${deposit.maturityAmount.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(oneTimeDepositsControllerProvider),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
