import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/investment_projection.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/domain/deposit_list_tile.dart';
import 'package:postfolio/core/widgets/domain/nominees_detail_section.dart';
import 'package:postfolio/core/widgets/domain/wealth_accumulation_grid.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installments_section.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_transactions_section.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum RDDetailTab {
  info('info'),
  ledger('schedule'),
  transactions('transactions');

  const RDDetailTab(this.queryValue);

  /// Value accepted by the `?tab=` query parameter.
  final String queryValue;

  static RDDetailTab? fromQuery(String? value) {
    for (final tab in values) {
      if (tab.queryValue == value) return tab;
    }
    return null;
  }
}

class RecurringDepositDetailScreen extends HookConsumerWidget {
  final String depositId;
  final String? initialTab;

  /// Where the row that opened the screen is, when a row did (`EntityHero.tagFrom`).
  final String? openedFrom;

  const RecurringDepositDetailScreen({
    super.key,
    required this.depositId,
    this.initialTab,
    this.openedFrom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deep link (`?tab=info|schedule|transactions`) wins on first build; the hook keeps
    // the user's subsequent choice. `maybeOf` keeps the screen usable outside a router.
    final tabFromRoute = RDDetailTab.fromQuery(
      initialTab ?? GoRouter.maybeOf(context)?.state.uri.queryParameters['tab'],
    );
    final activeTab = useState(tabFromRoute ?? RDDetailTab.info);
    final projectionAsync = ref.watch(rdLedgerProjectionProvider(depositId));

    final record = ref.watch(recurringDepositByIdProvider(depositId));

    return AsyncSingleEntityBuilder<RecurringDeposit>(
      state: record,
      // Opened from a row, the screen has the list's record of the deposit at once. It
      // lacks only the nominees, so nothing here is a placeholder meanwhile: their section
      // arrives with the full record.
      seed: ref.watch(recurringDepositInListProvider(depositId)),
      notFoundMessage: t.recurringDeposits.depositNotFound,
      onRetry: () => ref.invalidate(recurringDepositByIdProvider(depositId)),
      dummyEntity: RecurringDeposit.dummy,
      builder: (deposit) {
        // The list's record or the full one. The placeholder of a cold start is neither.
        final isKnown = deposit.id == depositId;
        // The avatar, the customer's name, the account number and the installment travel
        // here from the row.
        final heroTag = isKnown
            ? EntityHero.tagFrom(openedFrom, depositId)
            : null;
        final accountNo = deposit.accountNo ?? t.common.notProvided;
        final theme = Theme.of(context);
        final tabs = t.recurringDeposits.detailTabs;
        final fields = t.recurringDeposits.fields;
        final customerName = (deposit.customerName?.isNotEmpty ?? false)
            ? deposit.customerName!
            : ref.watch(customerByIdProvider(deposit.customerId)).value?.name;
        final resolvedCustomerName = customerName ?? deposit.customerId;
        final rateLabel = fields.ratePercent(
          rate: deposit.interestRate.toStringAsFixed(2),
        );

        return EntityDetailScaffold(
          appBarTitle: t.common.depositDetails,
          onRefresh: () async {
            // The account and the three streams its ledger is projected from.
            ref.invalidate(recurringDepositByIdProvider(depositId));
            ref.invalidate(rdTransactionsStreamProvider(depositId));
            ref.invalidate(rdPoDepositsStreamProvider(depositId));
            ref.invalidate(rdFeeAbsorptionsStreamProvider(depositId));
            await ref.read(rdLedgerProjectionProvider(depositId).future);
          },
          // In the menu, with its label, as on the deposit's row in the list. It was a bare
          // seal icon in the app bar.
          menuActions: [
            EntityAction(
              icon: HugeIcon(
                icon: deposit.status == DepositStatus.active
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconSm,
              ),
              label: deposit.status == DepositStatus.active
                  ? t.common.closeDeposit
                  : t.common.reopenDeposit,
              onTap: () async {
                final isActive = deposit.status == DepositStatus.active;
                final confirmed = await AppDialogs.confirmAction(
                  context,
                  title: isActive
                      ? t.common.closeDeposit
                      : t.common.reopenDeposit,
                  content: isActive
                      ? t.recurringDeposits.closeDepositConfirmation
                      : t.recurringDeposits.reopenDepositConfirmation,
                  confirmText: isActive ? t.common.close : t.common.reopen,
                );
                if (confirmed != true || !context.mounted) return;

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
                if (!context.mounted) return;
                if (result case Failure(:final error)) {
                  AppFeedback.showError(context, error.toString());
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
            return switch (result) {
              Failure(:final error) =>
                t.recurringDeposits.failedToDeleteDeposit(
                  error: error.toString(),
                ),
              Success() => null,
            };
          },
          header: EntityDetailHeader(
            heroTag: heroTag,
            avatarBackgroundColor: theme.colorScheme.secondaryContainer,
            avatarForegroundColor: theme.colorScheme.onSecondaryContainer,
            avatarText: deposit.avatarLabel,
            avatarShape: deposit.schemeType.avatarShape,
            // Headed as its row in the list is: whose deposit it is, then which. A deposit
            // without a named customer is titled by its number there too.
            title: customerName ?? accountNo,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // An account number broken across two lines reads as two numbers.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: EntityHero(
                    tag: heroTag,
                    part: EntityHeroPart.subtitle,
                    child: Text(
                      accountNo,
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Text(
                  deposit.schemeType.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // The way to the customer from any tab. The title already says the name.
                AppButton.text(
                  label: t.customers.customerDetails,
                  icon: HugeIcons.strokeRoundedUser,
                  size: AppButtonSize.extraSmall,
                  flushStart: true,
                  onPressed: () =>
                      CustomerDetailRoute(deposit.customerId).push(context),
                ),
              ],
            ),
            footer: _LedgerProgress(
              projectionAsync: projectionAsync,
              totalMonths: deposit.totalMonths,
            ),
            badge: StatusBadge(
              status: deposit.status.displayName,
              depositStatus: deposit.status,
            ),
          ),
          body: [
            AppButtonGroup<RDDetailTab>(
              selected: activeTab.value,
              onChanged: (tab) => activeTab.value = tab,
              segments: [
                AppSegment(value: RDDetailTab.info, label: tabs.info),
                AppSegment(value: RDDetailTab.ledger, label: tabs.ledger),
                AppSegment(
                  value: RDDetailTab.transactions,
                  label: tabs.transactions,
                ),
              ],
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
                  DetailStatRow(
                    children: [
                      DetailAmountCard(
                        title: t.recurringDeposits.fields.installmentAmount,
                        amount: deposit.installmentAmount,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                        heroTag: heroTag,
                      ),
                      DetailStatCard(
                        title: t.recurringDeposits.fields.interestRate,
                        value: rateLabel,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
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
                  AppSpacings.gapLg,
                  DetailSection(
                    title: t.recurringDeposits.sections.investmentDetails,
                    children: [
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.termYears,
                        value: fields.termDisplay(
                          years: deposit.termYears.toString(),
                          months: deposit.termMonths.toString(),
                        ),
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
                      if (deposit.accountNo != null &&
                          deposit.accountNo!.isNotEmpty) ...[
                        DetailItem(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedTicket01,
                            size: AppDimensions.iconMd,
                          ),
                          label: t.recurringDeposits.fields.accountNo,
                          value: deposit.accountNo,
                          copyValue: deposit.accountNo,
                        ),
                      ],
                      DetailItem(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedTag01,
                          size: AppDimensions.iconMd,
                        ),
                        label: t.recurringDeposits.fields.serialNo,
                        value: deposit.serialNo ?? t.common.notProvided,
                        copyValue: deposit.serialNo,
                      ),
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

/// Header subtitle: "Collected through #N" / "At PO #M" (+ "k months from pocket" when the PO
/// is ahead of the customer), the money the customer owes / has in credit / the agent has
/// paid from pocket, and a collected-through progress bar.
class _LedgerProgress extends StatelessWidget {
  final AsyncValue<RDLedgerProjection> projectionAsync;
  final int totalMonths;

  const _LedgerProgress({
    required this.projectionAsync,
    required this.totalMonths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tabs = t.recurringDeposits.detailTabs;
    final projection = projectionAsync.value;
    final isFirstLoad = projectionAsync.isLoading && projection == null;
    final summary = projection?.summary;
    final paidThrough = summary?.paidThroughNo ?? 0;
    final depositedThrough = summary?.depositedThroughNo ?? 0;
    final fromPocketMonths = depositedThrough - paidThrough;
    final total = totalMonths > 0
        ? totalMonths
        : (projection?.installments.length ?? 0);
    final progress = total > 0 ? (paidThrough / total).clamp(0.0, 1.0) : 0.0;

    final owed = summary?.owedByCustomer ?? 0.0;
    final credit = summary?.customerCredit ?? 0.0;
    final receivable = summary?.receivable ?? 0.0;
    final feeDue = summary?.feeDue ?? 0.0;
    final isSettled =
        projection != null && projection.nextDue == null && owed <= 0;

    final moneyLines = <({String text, Color color})>[
      if (owed > 0)
        (
          text: feeDue > 0
              ? tabs.owesWithFee(
                  amount: owed.toRupeeFormat(),
                  fee: feeDue.toRupeeFormat(),
                )
              : tabs.owes(amount: owed.toRupeeFormat()),
          color: scheme.error,
        ),
      if (credit > 0)
        (
          text: tabs.credit(amount: credit.toRupeeFormat()),
          color: scheme.primary,
        ),
      if (receivable > 0)
        (
          text: tabs.receivable(amount: receivable.toRupeeFormat()),
          color: scheme.secondary,
        ),
      if (isSettled) (text: tabs.allSettled, color: scheme.primary),
    ];

    final emphasized = AppTypography.emphasizedOf(context);
    final counterStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLinearProgress(
          // Indeterminate only while the very first projection is loading.
          value: isFirstLoad ? null : progress,
          semanticsLabel: tabs.collectedThrough(n: paidThrough.toString()),
        ),
        AppSpacings.gapXs,
        Wrap(
          spacing: AppDimensions.paddingMd,
          children: [
            Text(
              tabs.collectedThrough(n: paidThrough.toString()),
              style: counterStyle,
            ),
            Text(
              tabs.atPo(n: depositedThrough.toString()),
              style: counterStyle,
            ),
            if (fromPocketMonths > 0)
              Text(
                tabs.monthsFromPocket(n: fromPocketMonths),
                style: emphasized.bodySmall?.copyWith(color: scheme.secondary),
              ),
          ],
        ),
        if (moneyLines.isNotEmpty) ...[
          AppSpacings.gapXxs,
          Wrap(
            spacing: AppDimensions.paddingSm,
            children: [
              for (final line in moneyLines)
                Text(
                  line.text,
                  style: emphasized.labelLarge?.copyWith(color: line.color),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
