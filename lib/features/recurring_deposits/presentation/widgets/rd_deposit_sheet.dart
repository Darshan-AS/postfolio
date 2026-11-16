import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/hooks/use_deposit_draft.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_sheet_parts.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_account_identity.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Opens the "Deposit next N installments at the Post Office on `date`" sheet.
/// Resolves `true` when a deposit event was recorded.
///
/// The agent never picks months — the PO ledger is sequential, so only a count and a date
/// are entered, exactly like the DOP agent portal, with an optional override when the
/// counter charges a different default fee (e.g. Sunday/holiday waiver).
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
    final count = draft.count.toString();

    final title = (customer != null && customer.isNotEmpty)
        ? ledger.depositTitleFor(n: count, customer: customer)
        : ledger.depositTitle(n: count);

    Future<void> handleSubmit() async {
      final who = customer ?? t.recurringDeposits.depositNotFound;
      final result = await draft.submit();
      if (!context.mounted) return;
      switch (result) {
        case Failure(:final error):
          AppFeedback.showError(context, error);
        case Success(value: final saved):
          // The toast describes the deposit as stored. After a retry that is what the first
          // attempt saved, even if the sheet has since moved on to the following months.
          final installments = ledger.installmentsCount(n: saved.installmentCount);
          final successMessage = saved.feePaid > 0
              ? ledger.depositDoneWithFee(
                  installments: installments,
                  customer: who,
                  amount: saved.amount.toRupeeFormat(),
                  fee: saved.feePaid.toRupeeFormat(),
                )
              : ledger.depositDone(
                  installments: installments,
                  customer: who,
                  amount: saved.amount.toRupeeFormat(),
                );
          Navigator.of(context).pop(true);
          if (!hostContext.mounted) return;
          AppFeedback.showSuccess(
            hostContext,
            successMessage,
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
      }
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
        child: Center(child: AppLoadingIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RDSheetHeader(
          title: title,
          subtitle: deposit == null ? null : rdAccountIdentity(deposit),
          onClose: () => Navigator.of(context).maybePop(false),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pageMargin,
              vertical: AppDimensions.paddingSm,
            ),
            child: body,
          ),
        ),
        RDSheetFooter(
          children: [
            RDSheetPrimaryAction(
              label: ledger.depositSubmit(n: count),
              icon: HugeIcons.strokeRoundedBuilding03,
              isLoading: draft.isSubmitting,
              onPressed: draft.canSubmit ? handleSubmit : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _DepositBody extends HookWidget {
  const _DepositBody({required this.draft});

  final DepositDraftState draft;

  /// The hint carries the formula's fee; at large text it wraps instead of being cut.
  static const int _feeHintMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final ledger = t.recurringDeposits.ledger;
    final quote = draft.quote;
    final feeController = useTextEditingController();
    // Rebuild as the fee is typed: the currency prefix shows only next to a typed value.
    useListenable(feeController);

    final throughText = draft.depositedThroughNo > 0
        ? ledger.depositThrough(month: draft.depositedThroughNo.toString())
        : ledger.depositNothingYet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ledger.depositStatusLine(
            through: throughText,
            ready: ledger.depositReady(n: draft.readyCount),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        AppSpacings.gapLg,
        RDSheetSectionLabel(ledger.depositCount),
        AppSpacings.gapSm,
        // How many, and on which date: one group of two rows.
        _CountStepper(draft: draft),
        const SizedBox(height: AppShapes.groupGap),
        _DepositDateTile(draft: draft),
        AppSpacings.gapLg,
        TextFormField(
          key: const ValueKey('deposit_counter_fee_override_field'),
          controller: feeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: AppInputDecoration.m3(
            context,
            labelText: ledger.counterFeeOverrideLabel,
            hintText: ledger.counterFeeOverrideHint(
              amount: draft.statutoryFee.toRupeeFormat(),
            ),
            // Not beside the hint, which would then read "₹Formula: ₹60".
            prefixText: feeController.text.isEmpty ? null : t.format.currencySymbol,
          ).copyWith(
            // The label is long. Kept floating, it fits on the field's edge and leaves the
            // inside to the hint, which states the fee the formula gives.
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintMaxLines: _feeHintMaxLines,
            suffixIcon: draft.feeOverride != null
                ? IconButton(
                    tooltip: t.common.clear,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: AppDimensions.iconSm,
                    ),
                    onPressed: () {
                      feeController.clear();
                      draft.setFeeOverride(null);
                    },
                  )
                : null,
          ),
          onChanged: (raw) {
            final trimmed = raw.trim();
            if (trimmed.isEmpty) {
              draft.setFeeOverride(null);
              return;
            }
            final parsed = double.tryParse(trimmed);
            if (parsed != null) {
              draft.setFeeOverride(parsed);
            }
          },
        ),
        AppSpacings.gapLg,
        if (quote != null)
          RDSheetBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // What the counter will ask for: the figure of this sheet.
                RDSheetFigure(
                  quote.fee > 0
                      ? ledger.depositQuote(
                          amount: quote.amount.toRupeeFormat(),
                          fee: quote.fee.toRupeeFormat(),
                        )
                      : ledger.depositQuoteNoFee(amount: quote.amount.toRupeeFormat()),
                  style: emphasized.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                  figure: quote.amount.toRupeeFormat(),
                  figureStyle: emphasized.headlineMedium?.copyWith(color: scheme.onSurface),
                ),
                if (draft.isFrontingFromPocket) ...[
                  AppSpacings.gapSm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The agent's own money: the fronted colour, as on the Hub and the
                      // passbook. Red is for what is overdue.
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedWallet02,
                        size: AppDimensions.iconSm,
                        color: AppFinancialColors.of(context).fronted.onContainer,
                      ),
                      AppSpacings.gapSm,
                      Expanded(
                        child: Text(
                          ledger.depositFromPocketWarning(
                            amount: draft.fromPocket.toRupeeFormat(),
                          ),
                          style: emphasized.bodySmall?.copyWith(
                            color: AppFinancialColors.of(context).fronted.onContainer,
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

/// The count of installments with its − / + buttons: the first row of the group that ends
/// with the deposit date.
class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.draft});

  final DepositDraftState draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = t.recurringDeposits.ledger;

    return AppGroupTile(
      position: AppGroupPosition.first,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingSm,
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: ledger.depositDecrement,
              onPressed: draft.canDecrement ? () => draft.setCount(draft.count - 1) : null,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMinusSign,
                size: AppDimensions.iconMd,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    draft.count.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.emphasizedOf(context).displaySmall,
                  ),
                  Text(
                    ledger.depositRange(
                      from: draft.fromNo.toString(),
                      to: draft.toNo.toString(),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: ledger.depositIncrement,
              onPressed: draft.canIncrement ? () => draft.setCount(draft.count + 1) : null,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                size: AppDimensions.iconMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositDateTile extends StatelessWidget {
  const _DepositDateTile({required this.draft});

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

    return RDSheetPickerTile(
      icon: HugeIcons.strokeRoundedCalendar01,
      label: ledger.depositDateValue(date: current.toAppFormat()),
      onTap: pick,
      position: AppGroupPosition.last,
    );
  }
}
