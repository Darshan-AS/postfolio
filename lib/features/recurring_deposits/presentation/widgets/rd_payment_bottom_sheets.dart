import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

enum PaymentSplitMode {
  installmentsOnly,
  includeFees,
  feesOnly,
  custom,
}

class PaymentSplitSelector extends StatelessWidget {
  final PaymentSplitMode splitMode;
  final ValueChanged<PaymentSplitMode> onSplitModeChanged;

  const PaymentSplitSelector({
    super.key,
    required this.splitMode,
    required this.onSplitModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<PaymentSplitMode>(
        selected: {splitMode},
        onSelectionChanged: (selected) {
          onSplitModeChanged(selected.first);
        },
        segments: [
          ButtonSegment(
            value: PaymentSplitMode.installmentsOnly,
            label: Text(ledger.splitModes.installmentsOnly),
            tooltip: ledger.splitModes.installmentsOnlyTooltip,
          ),
          ButtonSegment(
            value: PaymentSplitMode.includeFees,
            label: Text(ledger.splitModes.includeFees),
            tooltip: ledger.splitModes.includeFeesTooltip,
          ),
          ButtonSegment(
            value: PaymentSplitMode.feesOnly,
            label: Text(ledger.splitModes.feesOnly),
            tooltip: ledger.splitModes.feesOnlyTooltip,
          ),
          ButtonSegment(
            value: PaymentSplitMode.custom,
            label: Text(ledger.splitModes.custom),
            tooltip: ledger.splitModes.customTooltip,
          ),
        ],
      ),
    );
  }
}

class CustomSplitFields extends StatelessWidget {
  final TextEditingController installmentController;
  final TextEditingController feeController;

  const CustomSplitFields({
    super.key,
    required this.installmentController,
    required this.feeController,
  });

  @override
  Widget build(BuildContext context) {
    final ledger = t.recurringDeposits.ledger;
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: installmentController,
            labelText: ledger.toInstallment,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: t.format.currencySymbol,
          ),
        ),
        AppSpacings.gapMd,
        Expanded(
          child: AppTextField(
            controller: feeController,
            labelText: ledger.toDefaultFee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: t.format.currencySymbol,
          ),
        ),
      ],
    );
  }
}

class RDAllocationPreviewCard extends StatelessWidget {
  final bool isRecalculation;
  final List<RDInstallment>? installmentsToPreview;
  final List<RDInstallment> currentSchedule;
  final double leftoverAmount;

  const RDAllocationPreviewCard({
    super.key,
    required this.isRecalculation,
    required this.installmentsToPreview,
    required this.currentSchedule,
    this.leftoverAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = t.recurringDeposits.ledger.preview;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedActivity01,
                size: AppDimensions.iconSm,
                color: theme.colorScheme.primary,
              ),
              AppSpacings.gapSm,
              Text(
                isRecalculation ? preview.recalculatedTitle : preview.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacings.gapSm,
          if (installmentsToPreview == null)
            Text(
              isRecalculation ? preview.recalculatedHint : preview.hint,
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Text(
              isRecalculation ? preview.updatedAllocations : preview.willCover,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacings.gapXs,
            ...installmentsToPreview!.map((inst) {
              final monthIdx =
                  currentSchedule.indexWhere((s) => s.id == inst.id);
              final monthNum =
                  monthIdx != -1 ? (monthIdx + 1).toString() : '?';

              final String principalDesc = inst.isInstallmentPaid
                  ? preview.principalCovered(
                      amount: inst.installmentAmount.toRupeeFormat(),
                    )
                  : preview.principalAllocated(
                      paid: inst.customerPaidAmount.toRupeeFormat(),
                      total: inst.installmentAmount.toRupeeFormat(),
                    );

              return Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.paddingSm,
                  top: AppDimensions.paddingXs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: AppDimensions.iconXs,
                          color: theme.colorScheme.outline,
                        ),
                        AppSpacings.gapXs,
                        Text(
                          '${t.recurringDeposits.ledger.installmentDetails.month(month: monthNum)}: $principalDesc',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (inst.lateFee > 0)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimensions.paddingLg,
                          top: 1.0,
                        ),
                        child: Text(
                          inst.isLateFeeWaived
                              ? preview.feeWaived
                              : (inst.paidLateFee >= inst.lateFee
                                  ? preview.feePaid(
                                      amount: inst.lateFee.toRupeeFormat(),
                                    )
                                  : (inst.paidLateFee > 0
                                      ? preview.feePartial(
                                          paid: inst.paidLateFee.toRupeeFormat(),
                                          pending: (inst.lateFee - inst.paidLateFee).toRupeeFormat(),
                                        )
                                      : preview.feePending(
                                          amount: inst.lateFee.toRupeeFormat(),
                                        ))),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: inst.isLateFeeWaived
                                ? theme.colorScheme.secondary
                                : (inst.paidLateFee >= inst.lateFee
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (leftoverAmount > 0) ...[
              AppSpacings.gapSm,
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacings.gapXs,
                  Text(
                    preview.advanceCredit(
                      amount: leftoverAmount.toRupeeFormat(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class RDLogPaymentSheet extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final List<RDInstallment> currentSchedule;

  const RDLogPaymentSheet({
    super.key,
    required this.deposit,
    required this.currentSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = t.recurringDeposits.ledger;
    final amountController = useTextEditingController();
    final paidDate = useState(DateTime.now());
    final paymentMode = useState(RDPaymentMode.cash);
    final splitMode = useState<PaymentSplitMode>(PaymentSplitMode.installmentsOnly);
    final customInstallmentController = useTextEditingController();
    final customFeeController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final theme = Theme.of(context);

    final amountText = useListenable(amountController);
    final double amountValue = double.tryParse(amountText.text.trim()) ?? 0.0;

    final customInstText = useListenable(customInstallmentController);
    final customFeeText = useListenable(customFeeController);
    final customInstValue = double.tryParse(customInstText.text.trim()) ?? 0.0;
    final customFeeValue = double.tryParse(customFeeText.text.trim()) ?? 0.0;

    final (double? effectiveInstComp, double? effectiveFeeComp) = useMemoized(() {
      switch (splitMode.value) {
        case PaymentSplitMode.installmentsOnly:
          return (amountValue, 0.0);
        case PaymentSplitMode.feesOnly:
          return (0.0, amountValue);
        case PaymentSplitMode.includeFees:
          return (null, null);
        case PaymentSplitMode.custom:
          return (customInstValue, customFeeValue);
      }
    }, [splitMode.value, amountValue, customInstValue, customFeeValue]);

    final previewResult = useMemoized(() {
      if (amountValue <= 0.0) return null;
      return RDLedgerService.allocateCustomerPayment(
        currentSchedule: currentSchedule,
        paymentAmount: amountValue,
        installmentComponent: effectiveInstComp,
        lateFeeComponent: effectiveFeeComp,
        paidDate: paidDate.value,
        paymentMode: paymentMode.value,
        rdId: deposit.id,
      );
    }, [amountValue, effectiveInstComp, effectiveFeeComp, paidDate.value, paymentMode.value, currentSchedule, deposit.id]);

    final pendingLateFeesTotal = useMemoized(() {
      return currentSchedule.fold<double>(
        0.0,
        (sum, inst) => sum + inst.outstandingLateFee,
      );
    }, [currentSchedule]);

    final baseInstallment = deposit.installmentAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ledger.logPaymentTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: AppDimensions.iconMd,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (pendingLateFeesTotal > 0) ...[
                  AppSpacings.gapSm,
                  Wrap(
                    spacing: AppDimensions.paddingSm,
                    runSpacing: AppDimensions.paddingXs,
                    children: [
                      ActionChip(
                        avatar: const HugeIcon(
                          icon: HugeIcons.strokeRoundedFlash,
                          size: AppDimensions.iconXs,
                        ),
                        label: Text(
                          ledger.chips.oneInstallment(
                            amount: baseInstallment.toRupeeFormat(),
                          ),
                        ),
                        onPressed: () {
                          amountController.text =
                              baseInstallment.toStringAsFixed(0);
                          splitMode.value = PaymentSplitMode.installmentsOnly;
                        },
                      ),
                      ActionChip(
                        avatar: const HugeIcon(
                          icon: HugeIcons.strokeRoundedEnergy,
                          size: AppDimensions.iconXs,
                        ),
                        label: Text(
                          ledger.chips.feesOnly(
                            amount: pendingLateFeesTotal.toRupeeFormat(),
                          ),
                        ),
                        onPressed: () {
                          amountController.text =
                              pendingLateFeesTotal.toStringAsFixed(0);
                          splitMode.value = PaymentSplitMode.feesOnly;
                        },
                      ),
                      ActionChip(
                        avatar: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: AppDimensions.iconXs,
                        ),
                        label: Text(
                          ledger.chips.clearBoth(
                            amount: (baseInstallment + pendingLateFeesTotal)
                                .toRupeeFormat(),
                          ),
                        ),
                        onPressed: () {
                          amountController.text =
                              (baseInstallment + pendingLateFeesTotal)
                                  .toStringAsFixed(0);
                          splitMode.value = PaymentSplitMode.includeFees;
                        },
                      ),
                    ],
                  ),
                ],
                AppSpacings.gapLg,
                AppTextField(
                  controller: amountController,
                  labelText: ledger.paymentAmount,
                  isRequired: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: t.format.currencySymbol,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return ledger.amountRequired;
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return ledger.enterValidAmount;
                    }
                    return null;
                  },
                ),
                AppSpacings.gapLg,
                Text(
                  ledger.allocationPriority,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacings.gapSm,
                PaymentSplitSelector(
                  splitMode: splitMode.value,
                  onSplitModeChanged: (mode) {
                    splitMode.value = mode;
                    if (mode == PaymentSplitMode.custom) {
                      customInstallmentController.text =
                          amountValue.toStringAsFixed(0);
                      customFeeController.text = '0';
                    }
                  },
                ),
                if (splitMode.value == PaymentSplitMode.custom) ...[
                  AppSpacings.gapMd,
                  CustomSplitFields(
                    installmentController: customInstallmentController,
                    feeController: customFeeController,
                  ),
                ],
                AppSpacings.gapLg,
                Text(
                  ledger.paymentMode,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacings.gapSm,
                SegmentedButton<RDPaymentMode>(
                  selected: {paymentMode.value},
                  onSelectionChanged: (selected) {
                    paymentMode.value = selected.first;
                  },
                  segments: RDPaymentMode.values.map((mode) {
                    List<List<dynamic>> icon;
                    switch (mode) {
                      case RDPaymentMode.cash:
                        icon = HugeIcons.strokeRoundedCoins01;
                        break;
                      case RDPaymentMode.upi:
                        icon = HugeIcons.strokeRoundedCreditCard;
                        break;
                      case RDPaymentMode.cheque:
                        icon = HugeIcons.strokeRoundedTicket01;
                        break;
                      case RDPaymentMode.bankTransfer:
                        icon = HugeIcons.strokeRoundedBank;
                        break;
                    }
                    return ButtonSegment<RDPaymentMode>(
                      value: mode,
                      label: Text(mode.displayName),
                      icon: HugeIcon(icon: icon, size: AppDimensions.iconSm),
                    );
                  }).toList(),
                ),
                AppSpacings.gapLg,
                AppTextField(
                  readOnly: true,
                  labelText: ledger.paymentDate,
                  controller: TextEditingController(
                    text: paidDate.value.toAppFormat(),
                  ),
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: paidDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      paidDate.value = selected;
                    }
                  },
                ),
                AppSpacings.gapXl,
                RDAllocationPreviewCard(
                  isRecalculation: false,
                  installmentsToPreview: previewResult?.updatedInstallments,
                  currentSchedule: currentSchedule,
                  leftoverAmount: previewResult?.leftoverAmount ?? 0.0,
                ),
                AppSpacings.gapXl,
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    if (previewResult == null) return;

                    final Result<void, String> result = await ref
                        .read(rDLedgerControllerProvider.notifier)
                        .recordCustomerPayment(
                          rdId: deposit.id,
                          paymentAmount: amountValue,
                          installmentComponent: effectiveInstComp,
                          lateFeeComponent: effectiveFeeComp,
                          paidDate: paidDate.value,
                          paymentMode: paymentMode.value,
                          currentSchedule: currentSchedule,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (result is Success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(ledger.paymentRecorded),
                          ),
                        );
                      } else if (result is Failure<void, String>) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(result.error),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(ledger.recordPayment),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RDEditPaymentSheet extends HookConsumerWidget {
  final RecurringDeposit deposit;
  final RDTransaction transaction;
  final List<RDTransaction> allTransactions;
  final List<RDInstallment> currentSchedule;

  const RDEditPaymentSheet({
    super.key,
    required this.deposit,
    required this.transaction,
    required this.allTransactions,
    required this.currentSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = t.recurringDeposits.ledger;
    final amountController = useTextEditingController(
      text: transaction.amount.toStringAsFixed(
        transaction.amount.truncateToDouble() == transaction.amount ? 0 : 2,
      ),
    );
    final paidDate = useState(transaction.paidDate);
    final paymentMode = useState(transaction.paymentMode);
    final initialSplitMode = useMemoized(() {
      if (transaction.installmentAmount > 0 && transaction.lateFeeAmount == 0) {
        return PaymentSplitMode.installmentsOnly;
      } else if (transaction.installmentAmount == 0 && transaction.lateFeeAmount > 0) {
        return PaymentSplitMode.feesOnly;
      } else if (transaction.installmentAmount > 0 && transaction.lateFeeAmount > 0) {
        return PaymentSplitMode.custom;
      } else {
        return PaymentSplitMode.includeFees;
      }
    }, [transaction]);

    final splitMode = useState<PaymentSplitMode>(initialSplitMode);
    final customInstallmentController = useTextEditingController(
      text: transaction.installmentAmount > 0
          ? transaction.installmentAmount.toStringAsFixed(
              transaction.installmentAmount.truncateToDouble() ==
                      transaction.installmentAmount
                  ? 0
                  : 2,
            )
          : '',
    );
    final customFeeController = useTextEditingController(
      text: transaction.lateFeeAmount > 0
          ? transaction.lateFeeAmount.toStringAsFixed(
              transaction.lateFeeAmount.truncateToDouble() ==
                      transaction.lateFeeAmount
                  ? 0
                  : 2,
            )
          : '',
    );

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final theme = Theme.of(context);

    final amountText = useListenable(amountController);
    final double amountValue = double.tryParse(amountText.text.trim()) ?? 0.0;

    final customInstText = useListenable(customInstallmentController);
    final customFeeText = useListenable(customFeeController);
    final customInstValue = double.tryParse(customInstText.text.trim()) ?? 0.0;
    final customFeeValue = double.tryParse(customFeeText.text.trim()) ?? 0.0;

    final (double? effectiveInstComp, double? effectiveFeeComp) = useMemoized(() {
      switch (splitMode.value) {
        case PaymentSplitMode.installmentsOnly:
          return (amountValue, 0.0);
        case PaymentSplitMode.feesOnly:
          return (0.0, amountValue);
        case PaymentSplitMode.includeFees:
          return (null, null);
        case PaymentSplitMode.custom:
          return (customInstValue, customFeeValue);
      }
    }, [splitMode.value, amountValue, customInstValue, customFeeValue]);

    final previewSchedule = useMemoized(() {
      if (amountValue <= 0.0) return null;
      final updatedTx = transaction.copyWith(
        amount: amountValue,
        installmentAmount: effectiveInstComp ?? 0.0,
        lateFeeAmount: effectiveFeeComp ?? 0.0,
        paidDate: paidDate.value,
        paymentMode: paymentMode.value,
      );
      final updatedTxs = allTransactions
          .map((t) => t.id == transaction.id ? updatedTx : t)
          .toList();
      return RDLedgerService.recomputeScheduleFromTransactions(
        currentSchedule: currentSchedule,
        transactions: updatedTxs,
        initialPaidInstallments: deposit.initialPaidInstallments,
      );
    }, [amountValue, effectiveInstComp, effectiveFeeComp, paidDate.value, paymentMode.value, currentSchedule, allTransactions, transaction, deposit.initialPaidInstallments]);

    final previewInstallments = useMemoized(() {
      if (previewSchedule == null) return null;
      return previewSchedule
          .where((inst) =>
              inst.customerPaidAmount > 0 ||
              inst.paidLateFee > 0 ||
              inst.isLateFeeWaived)
          .toList();
    }, [previewSchedule]);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ledger.editPaymentTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: AppDimensions.iconMd,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AppSpacings.gapLg,
                AppTextField(
                  controller: amountController,
                  labelText: ledger.paymentAmount,
                  isRequired: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: t.format.currencySymbol,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return ledger.amountRequired;
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return ledger.enterValidAmount;
                    }
                    return null;
                  },
                ),
                AppSpacings.gapLg,
                Text(
                  ledger.allocationPriority,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacings.gapSm,
                PaymentSplitSelector(
                  splitMode: splitMode.value,
                  onSplitModeChanged: (mode) {
                    splitMode.value = mode;
                    if (mode == PaymentSplitMode.custom) {
                      customInstallmentController.text =
                          amountValue.toStringAsFixed(0);
                      customFeeController.text = '0';
                    }
                  },
                ),
                if (splitMode.value == PaymentSplitMode.custom) ...[
                  AppSpacings.gapMd,
                  CustomSplitFields(
                    installmentController: customInstallmentController,
                    feeController: customFeeController,
                  ),
                ],
                AppSpacings.gapLg,
                Text(
                  ledger.paymentMode,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacings.gapSm,
                SegmentedButton<RDPaymentMode>(
                  selected: {paymentMode.value},
                  onSelectionChanged: (selected) {
                    paymentMode.value = selected.first;
                  },
                  segments: RDPaymentMode.values.map((mode) {
                    List<List<dynamic>> icon;
                    switch (mode) {
                      case RDPaymentMode.cash:
                        icon = HugeIcons.strokeRoundedCoins01;
                        break;
                      case RDPaymentMode.upi:
                        icon = HugeIcons.strokeRoundedCreditCard;
                        break;
                      case RDPaymentMode.cheque:
                        icon = HugeIcons.strokeRoundedTicket01;
                        break;
                      case RDPaymentMode.bankTransfer:
                        icon = HugeIcons.strokeRoundedBank;
                        break;
                    }
                    return ButtonSegment<RDPaymentMode>(
                      value: mode,
                      label: Text(mode.displayName),
                      icon: HugeIcon(icon: icon, size: AppDimensions.iconSm),
                    );
                  }).toList(),
                ),
                AppSpacings.gapLg,
                AppTextField(
                  readOnly: true,
                  labelText: ledger.paymentDate,
                  controller: TextEditingController(
                    text: paidDate.value.toAppFormat(),
                  ),
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    size: AppDimensions.iconMd,
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: paidDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      paidDate.value = selected;
                    }
                  },
                ),
                AppSpacings.gapXl,
                RDAllocationPreviewCard(
                  isRecalculation: true,
                  installmentsToPreview: previewInstallments,
                  currentSchedule: currentSchedule,
                ),
                AppSpacings.gapXl,
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    if (previewSchedule == null) return;

                    if (splitMode.value == PaymentSplitMode.custom) {
                      final sum = customInstValue + customFeeValue;
                      if ((sum - amountValue).abs() > 0.01) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              ledger.customSplitMismatch(
                                inst: customInstValue.toRupeeFormat(),
                                fee: customFeeValue.toRupeeFormat(),
                                total: amountValue.toRupeeFormat(),
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    final updatedTx = transaction.copyWith(
                      amount: amountValue,
                      installmentAmount: effectiveInstComp ?? 0.0,
                      lateFeeAmount: effectiveFeeComp ?? 0.0,
                      paidDate: paidDate.value,
                      paymentMode: paymentMode.value,
                      updatedAt: DateTime.now(),
                    );

                    final Result<void, String> result = await ref
                        .read(rDLedgerControllerProvider.notifier)
                        .updateCustomerPayment(
                          updatedTransaction: updatedTx,
                          deposit: deposit,
                          currentSchedule: currentSchedule,
                          currentTransactions: allTransactions,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (result is Success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(ledger.paymentUpdated),
                          ),
                        );
                      } else if (result is Failure<void, String>) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(result.error),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(ledger.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
