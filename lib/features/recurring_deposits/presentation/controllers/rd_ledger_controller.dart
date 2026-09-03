import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
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

  Future<Result<void, String>> recordPoPayments({
    required List<RDInstallment> installments,
  }) async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    return await repository.recordPoPayments(installments);
  }
}
