import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';

part 'one_time_deposits_controller.g.dart';

@riverpod
class OneTimeDepositsController extends _$OneTimeDepositsController {
  @override
  FutureOr<UnmodifiableListView<OneTimeDeposit>> build() async {
    return _fetchOneTimeDeposits();
  }

  Future<UnmodifiableListView<OneTimeDeposit>> _fetchOneTimeDeposits() async {
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final result = await repository.fetchOneTimeDeposits();

    return switch (result) {
      Success(value: final deposits) => UnmodifiableListView(deposits),
      Failure(error: final error) => throw Exception(error),
    };
  }

  Future<Result<void, String>> saveOneTimeDeposit({
    String? id,
    required String rowId,
    required String accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    double interestRate = 0.0,
    required String customerId,
    required OneTimeSchemeType schemeType,
    required double maturityAmount,
    required DateTime startDate,
    required DateTime maturityDate,
    String? linkedSavingsAccountNo,
    List<Nominee> nominees = const [],
  }) async {
    final (error, deposit) = OneTimeDeposit.create(
      id: id ?? '', // FakeRepo will assign a real ID if creating
      rowId: rowId,
      accountNo: accountNo,
      principalAmount: principalAmount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: interestRate,
      customerId: customerId,
      schemeType: schemeType,
      maturityAmount: maturityAmount,
      startDate: startDate,
      maturityDate: maturityDate,
      linkedSavingsAccountNo: linkedSavingsAccountNo,
      nominees: nominees,
    );

    if (error != null || deposit == null) {
      return Failure(error ?? 'Invalid one time deposit data provided');
    }

    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateOneTimeDeposit(deposit)
        : await repository.createOneTimeDeposit(deposit);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf(); // Triggers a re-fetch and rebuild
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final result = await repository.deleteOneTimeDeposit(id);

    return switch (result) {
      Success() => () {
        ref.invalidateSelf();
        return const Success<void, String>(null);
      }(),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}
