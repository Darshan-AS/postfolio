import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';

import 'package:uuid/uuid.dart';

part 'recurring_deposits_controller.g.dart';

@riverpod
class RecurringDepositsController extends _$RecurringDepositsController {
  @override
  Stream<UnmodifiableListView<RecurringDeposit>> build() {
    return _watchRecurringDeposits();
  }

  Stream<UnmodifiableListView<RecurringDeposit>> _watchRecurringDeposits() {
    final repository = ref.watch(recurringDepositRepositoryProvider);
    return repository.watchRecurringDeposits().map((result) {
      return switch (result) {
        Success(value: final deposits) => UnmodifiableListView(deposits),
        Failure(error: final error) => throw Exception(error),
      };
    });
  }

  Future<Result<void, String>> saveRecurringDeposit({
    String? id,
    String? serialNo,
    required String accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    required RecurringSchemeType schemeType,
    DepositStatus status = DepositStatus.active,
    required DateTime startDate,
    String? linkedAutoDebitAccountNo,
    List<Nominee> nominees = const [],
  }) async {
    final depositId = id ?? const Uuid().v4();

    final createResult = RecurringDeposit.create(
      id: depositId,
      serialNo: serialNo,
      accountNo: accountNo,
      installmentAmount: installmentAmount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: interestRate,
      customerId: customerId,
      schemeType: schemeType,
      status: status,
      startDate: startDate,
      linkedAutoDebitAccountNo: linkedAutoDebitAccountNo,
      nominees: nominees,
    );

    final RecurringDeposit deposit;
    switch (createResult) {
      case Failure(error: final err):
        return Failure(err);
      case Success(value: final d):
        deposit = d;
    }

    final repository = ref.read(recurringDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateRecurringDeposit(deposit)
        : await repository.createRecurringDeposit(deposit);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    final result = await repository.deleteRecurringDeposit(id);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}
