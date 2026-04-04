import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositDetailScreen extends ConsumerWidget {
  final String depositId;

  const RecurringDepositDetailScreen({super.key, required this.depositId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.recurringDeposits.deleteDeposit),
        content: Text(t.recurringDeposits.deleteDepositConfirmation),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(recurringDepositsControllerProvider.notifier)
                  .deleteRecurringDeposit(depositId);

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
                        t.recurringDeposits.failedToDeleteDeposit(
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
    final depositsState = ref.watch(recurringDepositsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RouteNames.rdEdit(depositId)),
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
            return Center(child: Text(t.recurringDeposits.depositNotFound));
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              const CircleAvatar(
                radius: AppDimensions.iconXl,
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.surface,
                child: Icon(Icons.loop_outlined, size: AppDimensions.iconXl),
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
                      Icons.money_outlined,
                      t.recurringDeposits.fields.installmentAmount,
                      '₹${deposit.installmentAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.category_outlined,
                      t.recurringDeposits.fields.schemeType,
                      deposit.schemeType.displayName,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.account_circle_outlined,
                      t.recurringDeposits.fields.customerId,
                      deposit.customerId,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.savings_outlined,
                      t.recurringDeposits.fields.maturityAmount,
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
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accent),
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
