import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/widgets/deposit_detail_cards.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
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

          final dateFormat = DateFormat('MMM dd, yyyy');

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.loop_outlined, size: 32),
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
                    title: t.recurringDeposits.fields.installmentAmount,
                    amount: deposit.installmentAmount,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    textColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                  ),
                  AppSpacings.gapLg,
                  DetailAmountCard(
                    title: t.recurringDeposits.fields.maturityAmount,
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
                    label: t.recurringDeposits.fields.termYears,
                    value:
                        '${deposit.termYears} Years, ${deposit.termMonths} Months',
                  ),
                  const Divider(height: 1),
                  DetailItem(
                    icon: Icons.percent_outlined,
                    label: t.recurringDeposits.fields.interestRate,
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
                    label: 'Start Date',
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
                    label: t.recurringDeposits.fields.customerId,
                    value: ref.watch(customersControllerProvider).value?.where((c) => c.id == deposit.customerId).firstOrNull?.name ?? deposit.customerId,
                  ),
                  if (deposit.linkedAutoDebitAccountNo != null &&
                      deposit.linkedAutoDebitAccountNo!.isNotEmpty) ...[
                    const Divider(height: 1),
                    DetailItem(
                      icon: Icons.account_balance_outlined,
                      label: 'Linked Auto Debit Account',
                      value: deposit.linkedAutoDebitAccountNo!,
                    ),
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
          onRetry: () => ref.invalidate(recurringDepositsControllerProvider),
        ),
      ),
    );
  }
}
