import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rd_ledger_controller.g.dart';

@riverpod
Stream<List<RDInstallment>> rdInstallmentsStream(Ref ref, String rdId) {
  final repository = ref.watch(recurringDepositRepositoryProvider);
  return repository.watchRDInstallments(rdId).map((result) {
    return switch (result) {
      Success(value: final installments) => installments,
      Failure(error: final error) => throw Exception(error),
    };
  });
}

@riverpod
Stream<List<RDTransaction>> rdTransactionsStream(Ref ref, String rdId) {
  final repository = ref.watch(recurringDepositRepositoryProvider);
  return repository.watchRDTransactions(rdId).map((result) {
    return switch (result) {
      Success(value: final transactions) => transactions,
      Failure(error: final error) => throw Exception(error),
    };
  });
}

@riverpod
Future<bool> rdHasTransactions(Ref ref, String rdId) async {
  final repository = ref.watch(recurringDepositRepositoryProvider);
  final result = await repository.hasTransactions(rdId);
  return switch (result) {
    Success(value: final has) => has,
    Failure(error: final error) => throw Exception(error),
  };
}

@riverpod
class RDLedgerController extends _$RDLedgerController {
  @override
  void build() {
    // No state needed, this is a pure controller for triggering side-effects
  }

  Future<Result<void, String>> recordCustomerPayment({
    required String rdId,
    required double paymentAmount,
    required DateTime paidDate,
    required RDPaymentMode paymentMode,
    required List<RDInstallment> currentSchedule,
  }) async {
    final allocationResult = RDLedgerService.allocateCustomerPayment(
      currentSchedule: currentSchedule,
      paymentAmount: paymentAmount,
      paidDate: paidDate,
      paymentMode: paymentMode,
      rdId: rdId,
    );

    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.recordCustomerPayment(
      allocationResult.transaction,
      allocationResult.updatedInstallments,
    );
  }

  Future<Result<void, String>> deleteCustomerPayment({
    required String transactionId,
    required RecurringDeposit deposit,
    required List<RDInstallment> currentSchedule,
    required List<RDTransaction> currentTransactions,
  }) async {
    final remainingTransactions = currentTransactions
        .where((t) => t.id != transactionId)
        .toList();

    final recomputedSchedule = RDLedgerService.recomputeScheduleFromTransactions(
      currentSchedule: currentSchedule,
      transactions: remainingTransactions,
      initialPaidInstallments: deposit.initialPaidInstallments,
    );

    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.deleteCustomerPayment(
      transactionId,
      recomputedSchedule,
    );
  }

  Future<Result<void, String>> updateCustomerPayment({
    required RDTransaction updatedTransaction,
    required RecurringDeposit deposit,
    required List<RDInstallment> currentSchedule,
    required List<RDTransaction> currentTransactions,
  }) async {
    final updatedTransactions = currentTransactions
        .map((t) => t.id == updatedTransaction.id ? updatedTransaction : t)
        .toList();

    final recomputedSchedule = RDLedgerService.recomputeScheduleFromTransactions(
      currentSchedule: currentSchedule,
      transactions: updatedTransactions,
      initialPaidInstallments: deposit.initialPaidInstallments,
    );

    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.updateCustomerPayment(
      updatedTransaction,
      recomputedSchedule,
    );
  }

  Future<Result<void, String>> recordPoPayments({
    required List<RDInstallment> installments,
  }) async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.recordPoPayments(installments);
  }

  Future<Result<void, String>> revertPoPayments({
    required List<RDInstallment> installments,
  }) async {
    final toUpdate = installments.map((inst) => inst.copyWith(
      poStatus: RDPoStatus.unpaid,
      poPaidDate: null,
    )).toList();

    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.recordPoPayments(toUpdate);
  }
}
