import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/domain/nominees_detail_section.dart';
import 'package:postfolio/core/widgets/domain/wealth_accumulation_grid.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installments_section.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_transactions_section.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum RDDetailTab { ledger, transactions, info }

class RecurringDepositDetailScreen extends HookConsumerWidget {
  final String depositId;

  const RecurringDepositDetailScreen({super.key, required this.depositId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = useState(RDDetailTab.ledger);

    return AsyncSingleEntityBuilder<RecurringDeposit>(
      state: ref.watch(recurringDepositByIdProvider(depositId)),
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositByIdProvider(depositId)),
      dummyEntity: RecurringDeposit.dummy,
      builder: (deposit) {
        final theme = Theme.of(context);
        final tabs = t.recurringDeposits.detailTabs;
        final resolvedCustomerName = (deposit.customerName?.isNotEmpty ?? false)
            ? deposit.customerName!
            : (ref.watch(customerByIdProvider(deposit.customerId)).value?.name ??
                deposit.customerId);

        return EntityDetailScaffold(
          appBarTitle: t.common.depositDetails,
          customActions: [
            IconButton(
              icon: HugeIcon(
                icon: deposit.status == DepositStatus.active
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconMd,
              ),
              tooltip: deposit.status == DepositStatus.active
                  ? t.common.close
                  : t.common.reopen,
              onPressed: () async {
                final isActive = deposit.status == DepositStatus.active;
                final confirmed = await AppDialogs.confirmAction(
                  context,
                  title: isActive ? t.common.close : t.common.reopen,
                  content: isActive
                      ? t.recurringDeposits.closeDepositConfirmation
                      : t.recurringDeposits.reopenDepositConfirmation,
                  confirmText: isActive ? t.common.close : t.common.reopen,
                );
                if (confirmed == true && context.mounted) {
                  final newStatus = isActive
                      ? DepositStatus.closed
                      : DepositStatus.active;
                  final result = await ref
                      .read(recurringDepositsControllerProvider.notifier)
                      .toggleDepositStatus(
                        depositId,
                        newStatus,
                        deposit: deposit,
                      );

                  if (result is Failure && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text((result as Failure).error.toString()),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          onEdit: () => RecurringDepositEditRoute(depositId).push(context),
          deleteDialogTitle: t.recurringDeposits.deleteDeposit,
          deleteDialogContent: t.recurringDeposits.deleteDepositConfirmation,
          onDelete: () async {
            final result = await ref
                .read(recurringDepositsControllerProvider.notifier)
                .deleteRecurringDeposit(depositId);
            return result is Failure
                ? t.recurringDeposits.failedToDeleteDeposit(
                    error: (result as Failure).error.toString(),
                  )
                : null;
          },
          header: EntityDetailHeader(
            avatarBackgroundColor: theme.colorScheme.secondaryContainer,
            avatarForegroundColor: theme.colorScheme.onSecondaryContainer,
            avatarText: deposit.avatarLabel,
            title: deposit.accountNo ?? t.common.notProvided,
            subtitle: Column(
              children: [
                Text(
                  deposit.schemeType.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacings.gapXs,
                InkWell(
                  onTap: () =>
                      CustomerDetailRoute(deposit.customerId).push(context),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingXs,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          size: AppDimensions.iconXs,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacings.gapXs,
                        Text(
                          resolvedCustomerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacings.gapXs,
                Text(
                  tabs.headerSubtitle(
                    amount: deposit.installmentAmount.toRupeeFormat(),
                    rate: deposit.interestRate.toStringAsFixed(2),
                    maturityDate: deposit.maturityDate.toCompactFormat(),
                    maturityAmount: deposit.maturityAmount.toRupeeFormat(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            badge: StatusBadge(status: deposit.status.displayName),
          ),
          body: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<RDDetailTab>(
                segments: [
                  ButtonSegment(
                    value: RDDetailTab.ledger,
                    label: Text(tabs.ledger),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      size: AppDimensions.iconSm,
                    ),
                  ),
                  ButtonSegment(
                    value: RDDetailTab.transactions,
                    label: Text(tabs.transactions),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInvoice01,
                      size: AppDimensions.iconSm,
                    ),
                  ),
                  ButtonSegment(
                    value: RDDetailTab.info,
                    label: Text(tabs.info),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: AppDimensions.iconSm,
                    ),
                  ),
                ],
                selected: {activeTab.value},
                onSelectionChanged: (selection) {
                  activeTab.value = selection.first;
                },
              ),
            ),
            AppSpacings.gapLg,
            switch (activeTab.value) {
              RDDetailTab.ledger => RDInstallmentsSection(
                deposit: deposit,
                isEmbeddedTab: true,
              ),
              RDDetailTab.transactions => RDTransactionsSection(
                deposit: deposit,
                isEmbeddedTab: true,
              ),
              RDDetailTab.info => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DetailAmountCard(
                        title: t.recurringDeposits.fields.installmentAmount,
                        amount: deposit.installmentAmount,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      AppSpacings.gapLg,
                      DetailStatCard(
                        title: t.recurringDeposits.fields.interestRate,
                        value: '${deposit.interestRate.toStringAsFixed(2)}%',
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  AppSpacings.gapXxl,
                  switch (deposit.projection) {
                    WealthAccumulation(
                      :final totalInvested,
                      :final maturityAmount,
                      :final totalInterestEarned,
                    ) =>
                      WealthAccumulationGrid(
                        totalInvested: totalInvested,
                        projectedInterest: totalInterestEarned,
                        maturityAmount: maturityAmount,
                      ),
                    IncomeGeneration() => const SizedBox.shrink(),
                  },
                  AppSpacings.gapXxl,
                  DetailSection(
                    title: t.recurringDeposits.sections.investmentDetails,
                    children: [
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.termYears,
                        value:
                            '${deposit.termYears} Years, ${deposit.termMonths} Months',
                      ),
                      const Divider(height: AppDimensions.dividerHeight),
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPercent,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.interestRate,
                        value: '${deposit.interestRate.toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
                  DetailSection(
                    title: t.recurringDeposits.sections.timeline,
                    children: [
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar02,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.startDate,
                        value: deposit.startDate.toAppFormat(),
                      ),
                      const Divider(height: AppDimensions.dividerHeight),
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.maturityDate,
                        value: deposit.maturityDate.toAppFormat(),
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
                  DetailSection(
                    title: t.recurringDeposits.sections.accountInformation,
                    children: [
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedTag01,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.serialNo,
                        value: deposit.serialNo ?? t.common.notProvided,
                      ),
                      const Divider(height: AppDimensions.dividerHeight),
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.customerId,
                        value: resolvedCustomerName,
                        onTap: () => CustomerDetailRoute(
                          deposit.customerId,
                        ).push(context),
                      ),
                    ],
                  ),
                  if (deposit.nominees.isNotEmpty) ...[
                    AppSpacings.gapLg,
                    NomineesDetailSection(nominees: deposit.nominees),
                  ],
                ],
              ),
            },
          ],
        );
      },
    );
  }
}
