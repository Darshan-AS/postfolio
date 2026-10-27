import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Shared user-facing ledger actions for the RD Detail schedule.
///
/// Every entry point (inspector, action bar, tile menu) funnels through here so the
/// confirmation copy, `Result` feedback and busy handling can never drift apart.
abstract final class RDScheduleActions {
  /// Confirms (count + total + collected/pocket split) and deposits [installments] at the PO.
  ///
  /// When [offerUndo] is true the success snackbar carries an Undo action that reverts
  /// the same months.
  static Future<bool> confirmAndDepositToPo(
    BuildContext context,
    WidgetRef ref, {
    required String rdId,
    required List<RDInstallment> installments,
    bool offerUndo = false,
  }) async {
    if (installments.isEmpty) return false;
    final actions = t.recurringDeposits.ledger.actions;

    var total = 0.0;
    var collectedCount = 0;
    var collectedAmount = 0.0;
    var pocketCount = 0;
    var pocketAmount = 0.0;
    for (final inst in installments) {
      total += inst.installmentAmount;
      if (inst.isInstallmentPaid) {
        collectedCount++;
        collectedAmount += inst.installmentAmount;
      } else {
        pocketCount++;
        pocketAmount += inst.installmentAmount;
      }
    }

    final summary = actions.depositConfirmContent(
      count: installments.length.toString(),
      amount: total.toRupeeFormat(),
    );
    final content = pocketCount > 0 && collectedCount > 0
        ? '$summary\n\n${actions.depositConfirmBreakdown(
            collectedCount: collectedCount.toString(),
            collectedAmount: collectedAmount.toRupeeFormat(),
            pocketCount: pocketCount.toString(),
            pocketAmount: pocketAmount.toRupeeFormat(),
          )}'
        : summary;

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: actions.depositConfirmTitle,
      content: content,
      confirmText: actions.depositConfirmButton,
    );
    if (confirmed != true || !context.mounted) return false;

    final nos = {for (final inst in installments) inst.installmentNo!};
    final notifier = ref.read(rDLedgerControllerProvider.notifier);
    final result = await notifier.depositToPo(rdId: rdId, installmentNos: nos);
    if (!context.mounted) return result is Success;

    AppFeedback.showResult(
      context,
      result,
      successMessage: actions.depositSuccess(count: nos.length.toString()),
      undoLabel: offerUndo ? actions.undo : null,
      onUndo: offerUndo
          ? () async {
              final undo = await notifier.revertPoDeposit(
                rdId: rdId,
                installmentNos: nos,
              );
              if (!context.mounted) return;
              AppFeedback.showResult(
                context,
                undo,
                successMessage: actions.depositUndone,
              );
            }
          : null,
    );
    return result is Success;
  }

  /// Confirms and reverts the PO deposit for [installments].
  static Future<bool> confirmAndRevertPo(
    BuildContext context,
    WidgetRef ref, {
    required String rdId,
    required List<RDInstallment> installments,
  }) async {
    if (installments.isEmpty) return false;
    final actions = t.recurringDeposits.ledger.actions;
    final scheme = Theme.of(context).colorScheme;
    final count = installments.length.toString();

    final confirmed = await AppDialogs.confirmAction(
      context,
      title: actions.revertConfirmTitle,
      content: actions.revertConfirmContent(count: count),
      confirmText: actions.revert(count: count),
      confirmBackgroundColor: scheme.errorContainer,
      confirmForegroundColor: scheme.onErrorContainer,
    );
    if (confirmed != true || !context.mounted) return false;

    final result = await ref.read(rDLedgerControllerProvider.notifier).revertPoDeposit(
          rdId: rdId,
          installmentNos: {for (final inst in installments) inst.installmentNo!},
        );
    if (!context.mounted) return result is Success;
    AppFeedback.showResult(
      context,
      result,
      successMessage: actions.revertSuccess(count: count),
    );
    return result is Success;
  }

  /// Forgives (with confirmation) or reinstates the default fee for one month.
  static Future<void> setFeeWaiver(
    BuildContext context,
    WidgetRef ref, {
    required String rdId,
    required RDInstallment installment,
    required bool waived,
    required double pendingFeeAmount,
  }) async {
    final actions = t.recurringDeposits.ledger.actions;
    final monthNo = installment.installmentNo!.toString();

    if (waived) {
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: actions.forgiveFeeTitle,
        content: actions.forgiveFeeContent(
          amount: pendingFeeAmount.toRupeeFormat(),
          month: monthNo,
        ),
        confirmText: actions.forgiveFee,
      );
      if (confirmed != true || !context.mounted) return;
    }

    final result = await ref.read(rDLedgerControllerProvider.notifier).setFeeWaiver(
          rdId: rdId,
          installmentNo: installment.installmentNo!,
          waived: waived,
        );
    if (!context.mounted) return;
    AppFeedback.showResult(
      context,
      result,
      successMessage: waived
          ? actions.forgiveFeeSuccess(month: monthNo)
          : actions.reinstateFeeSuccess(month: monthNo),
    );
  }
}
