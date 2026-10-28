import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_deposit_draft.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Opens the "Deposit next N installments at the Post Office on `date`" sheet.
/// Resolves `true` when a deposit event was recorded.
///
/// The agent never picks months — the PO ledger is sequential, so only a count and a date
/// are entered, exactly like the DOP agent portal.
Future<bool?> showRDDepositSheet(
  BuildContext context, {
  required String rdId,
  int? initialCount,
}) =>
    AppAdaptiveSheet.show<bool>(
      context,
      builder: (_) => _DepositForm(
        rdId: rdId,
        initialCount: initialCount,
        hostContext: context,
      ),
    );

class _DepositForm extends HookConsumerWidget {
  const _DepositForm({
    required this.rdId,
    required this.hostContext,
    this.initialCount,
  });

  final String rdId;
  final int? initialCount;

  /// The caller's context — still mounted after this sheet pops, so the snackbar's Undo
  /// can report its own outcome.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = useDepositDraft(ref, rdId: rdId, initialCount: initialCount);
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;
    final deposit = draft.facts.value?.deposit;
    final customer = deposit?.customerName;

    final title = (customer != null && customer.isNotEmpty)
        ? ledger.depositTitleFor(
            customer: customer,
            serial: deposit?.serialNo ?? t.common.notProvided,
          )
        : ledger.depositTitle;

    Future<void> handleSubmit() async {
      // Resolve the toast copy before the write: the quote is derived from facts that change
      // the moment the deposit lands.
      final count = draft.count;
      final quote = draft.quote;
      final who = customer ?? t.recurringDeposits.depositNotFound;
      final installments = ledger.installmentsCount(n: count);
      final successMessage = quote == null
          ? ledger.depositDone(installments: installments, customer: who, amount: t.common.notProvided)
          : quote.fee > 0
              ? ledger.depositDoneWithFee(
                  installments: installments,
                  customer: who,
                  amount: quote.amount.toRupeeFormat(),
                  fee: quote.fee.toRupeeFormat(),
                )
              : ledger.depositDone(
                  installments: installments,
                  customer: who,
                  amount: quote.amount.toRupeeFormat(),
                );

      final result = await draft.submit();
      if (!context.mounted) return;
      if (result is Success<void, String>) {
        Navigator.of(context).pop(true);
        if (!hostContext.mounted) return;
        AppFeedback.showResult(
          hostContext,
          result,
          successMessage: successMessage,
          undoLabel: t.recurringDeposits.monthlyOperations.undo,
          onUndo: () async {
            final undone = await draft.undo();
            if (!hostContext.mounted) return;
            AppFeedback.showResult(
              hostContext,
              undone,
              successMessage: ledger.depositUndone,
            );
          },
        );
        return;
      }
      AppFeedback.showResult(context, result, successMessage: successMessage);
    }

    final Widget body;
    if (draft.isLoaded) {
      body = draft.isAllDeposited
          ? Text(
              ledger.depositAllDone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : _DepositBody(draft: draft);
    } else if (draft.facts.hasError || draft.projection.hasError) {
      body = ErrorStateView(
        message: (draft.facts.error ?? draft.projection.error).toString(),
        onRetry: () => ref.invalidate(rdLedgerFactsProvider(rdId)),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLg,
            AppDimensions.paddingSm,
            AppDimensions.paddingSm,
            AppDimensions.paddingNone,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: t.common.close,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: AppDimensions.iconMd,
                ),
                onPressed: () => Navigator.of(context).maybePop(false),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingSm,
            ),
            child: body,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLg,
            AppDimensions.paddingSm,
            AppDimensions.paddingLg,
            AppDimensions.paddingLg,
          ),
          child: FilledButton.icon(
            onPressed: draft.canSubmit ? handleSubmit : null,
            icon: draft.isSubmitting
                ? const SizedBox.square(
                    dimension: AppDimensions.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimensions.strokeWidthSm,
                    ),
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedBuilding03,
                    size: AppDimensions.iconSm,
                  ),
            label: Text(ledger.depositSubmit(n: draft.count)),
          ),
        ),
      ],
    );
  }
}

class _DepositBody extends StatelessWidget {
  const _DepositBody({required this.draft});

  final DepositDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ledger = t.recurringDeposits.ledger;
    final quote = draft.quote;

    final throughText = draft.depositedThroughNo > 0
        ? ledger.depositThrough(month: draft.depositedThroughNo.toString())
        : ledger.depositNothingYet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$throughText${t.format.bulletSeparator}${ledger.depositReady(n: draft.readyCount)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        AppSpacings.gapLg,
        _SectionLabel(text: ledger.depositCount),
        AppSpacings.gapSm,
        _CountStepper(draft: draft),
        AppSpacings.gapLg,
        _DepositDateButton(draft: draft),
        AppSpacings.gapLg,
        if (quote != null)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.fee > 0
                      ? ledger.depositQuote(
                          amount: quote.amount.toRupeeFormat(),
                          fee: quote.fee.toRupeeFormat(),
                        )
                      : ledger.depositQuoteNoFee(amount: quote.amount.toRupeeFormat()),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (draft.isFrontingFromPocket) ...[
                  AppSpacings.gapSm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedWallet02,
                        size: AppDimensions.iconSm,
                        color: scheme.error,
                      ),
                      AppSpacings.gapSm,
                      Expanded(
                        child: Text(
                          ledger.depositFromPocketWarning(
                            amount: draft.fromPocket.toRupeeFormat(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.draft});

  final DepositDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return Row(
      children: [
        IconButton.outlined(
          tooltip: ledger.depositDecrement,
          onPressed: draft.canDecrement ? () => draft.setCount(draft.count - 1) : null,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedMinusSign,
            size: AppDimensions.iconSm,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                draft.count.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                ledger.depositRange(
                  from: draft.fromNo.toString(),
                  to: draft.toNo.toString(),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: ledger.depositIncrement,
          onPressed: draft.canIncrement ? () => draft.setCount(draft.count + 1) : null,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedPlusSign,
            size: AppDimensions.iconSm,
          ),
        ),
      ],
    );
  }
}

class _DepositDateButton extends StatelessWidget {
  const _DepositDateButton({required this.draft});

  final DepositDraftState draft;

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    final current = draft.depositedOn.value;
    final initial = current.isBefore(draft.firstDate)
        ? draft.firstDate
        : (current.isAfter(draft.lastDate) ? draft.lastDate : current);

    Future<void> pick() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: draft.firstDate,
        lastDate: draft.lastDate,
      );
      if (selected == null || !context.mounted) return;
      draft.depositedOn.value = selected;
    }

    return OutlinedButton.icon(
      onPressed: pick,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedCalendar01,
        size: AppDimensions.iconSm,
      ),
      label: Text('${ledger.depositDate}: ${current.toAppFormat()}'),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
