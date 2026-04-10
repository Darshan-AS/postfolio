import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
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
            onPressed: () => OneTimeDepositEditRoute(depositId).push(context),
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

          final dateFormat = DateFormat('MMM dd, yyyy');

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: AppDimensions.radiusXxxl,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: AppDimensions.iconLg,
                      ),
                    ),
                    AppSpacings.gapLg,
                    Text(
                      deposit.accountNo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacings.gapSm,
                    Text(
                      deposit.schemeType.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacings.gapMd,
                    StatusBadge(status: deposit.status.displayName),
                  ],
                ),
              ),
              AppSpacings.gapXxl,
              Row(
                children: [
                  DetailAmountCard(
                    title: t.oneTimeDeposits.fields.principalAmount,
                    amount: deposit.principalAmount,
                  ),
                  AppSpacings.gapLg,
                  DetailAmountCard(
                    title: t.oneTimeDeposits.fields.maturityAmount,
                    amount: deposit.maturityAmount,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer,
                    textColor: Theme.of(
                      context,
                    ).colorScheme.onTertiaryContainer,
                  ),
                ],
              ),
              AppSpacings.gapXxl,
              DetailSection(
                title: 'Investment Details',
                children: [
                  DetailItem(
                    icon: Icons.calendar_today_outlined,
                    label: t.oneTimeDeposits.fields.termYears,
                    value:
                        '${deposit.termYears} Years, ${deposit.termMonths} Months',
                  ),
                  const Divider(height: 1),
                  DetailItem(
                    icon: Icons.percent_outlined,
                    label: 'Interest Rate',
                    value: '${deposit.interestRate.toStringAsFixed(2)}%',
                  ),
                ],
              ),
              AppSpacings.gapLg,
              DetailSection(
                title: 'Timeline',
                children: [
                  DetailItem(
                    icon: Icons.date_range_outlined,
                    label: 'Deposit Date',
                    value: dateFormat.format(deposit.startDate),
                  ),
                  const Divider(height: 1),
                  DetailItem(
                    icon: Icons.event_available_outlined,
                    label: 'Maturity Date',
                    value: dateFormat.format(deposit.maturityDate),
                  ),
                ],
              ),
              AppSpacings.gapLg,
              DetailSection(
                title: 'Account Information',
                children: [
                  DetailItem(
                    icon: Icons.account_circle_outlined,
                    label: t.oneTimeDeposits.fields.customerId,
                    value:
                        ref
                            .watch(customersControllerProvider)
                            .value
                            ?.where((c) => c.id == deposit.customerId)
                            .firstOrNull
                            ?.name ??
                        deposit.customerId,
                  ),
                  const Divider(height: 1),
                  if (deposit.linkedSavingsAccountNo != null &&
                      deposit.linkedSavingsAccountNo!.isNotEmpty) ...[
                    DetailItem(
                      icon: Icons.account_balance_outlined,
                      label: 'Linked Savings Account',
                      value: deposit.linkedSavingsAccountNo!,
                    ),
                    const Divider(height: 1),
                  ],
                ],
              ),
              if (deposit.nominees.isNotEmpty) ...[
                AppSpacings.gapLg,
                DetailSection(
                  title: 'Nominees',
                  children: [
                    for (int i = 0; i < deposit.nominees.length; i++) ...[
                      DetailItem(
                        icon: Icons.person_outline,
                        label: deposit.nominees[i].relationship,
                        value:
                            '${deposit.nominees[i].name} (${deposit.nominees[i].percentage}%)',
                      ),
                      if (i < deposit.nominees.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ],
              AppSpacings.gapXxl,
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
}
