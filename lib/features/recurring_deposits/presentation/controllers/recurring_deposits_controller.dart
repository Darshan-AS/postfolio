import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';

part 'recurring_deposits_controller.g.dart';

@riverpod
class RecurringDepositsController extends _$RecurringDepositsController {
  @override
  FutureOr<UnmodifiableListView<RecurringDeposit>> build() async {
    return _fetchRecurringDeposits();
  }

  Future<UnmodifiableListView<RecurringDeposit>> _fetchRecurringDeposits() async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    final result = await repository.fetchRecurringDeposits();

    return switch (result) {
      Success(value: final deposits) => UnmodifiableListView(deposits),
      Failure(error: final error) => throw Exception(error),
    };
  }

  Future<Result<void, String>> saveRecurringDeposit({
    String? id,
    required String accountNo,
    required double installmentAmount,
    required int termYears,
    required int termMonths,
    required double interestRate,
    required String customerId,
    required RecurringSchemeType schemeType,
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedAutoDebitAccountNo,
    List<Nominee> nominees = const [],
  }) async {
    final (error, deposit) = RecurringDeposit.create(
      id: id ?? '', // FakeRepo will assign a real ID if creating
      accountNo: accountNo,
      installmentAmount: installmentAmount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: interestRate,
      customerId: customerId,
      schemeType: schemeType,
      maturityAmount: maturityAmount,
      startDate: startDate,
      maturityDate: maturityDate,
      linkedAutoDebitAccountNo: linkedAutoDebitAccountNo,
      nominees: nominees,
    );

    if (error != null || deposit == null) {
      return Failure(error ?? 'Invalid recurring deposit data provided');
    }

    final repository = ref.read(recurringDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateRecurringDeposit(deposit)
        : await repository.createRecurringDeposit(deposit);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf(); // Triggers a re-fetch and rebuild
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    final repository = ref.read(recurringDepositRepositoryProvider);
    final result = await repository.deleteRecurringDeposit(id);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf();
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}
