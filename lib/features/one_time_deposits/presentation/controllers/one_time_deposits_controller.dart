import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';

import 'package:uuid/uuid.dart';

part 'one_time_deposits_controller.g.dart';

@riverpod
class OneTimeDepositsController extends _$OneTimeDepositsController {
  @override
  Stream<UnmodifiableListView<OneTimeDeposit>> build() {
    return _watchOneTimeDeposits();
  }

  Stream<UnmodifiableListView<OneTimeDeposit>> _watchOneTimeDeposits() {
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    return repository.watchOneTimeDeposits().map((result) {
      return switch (result) {
        Success(value: final deposits) => UnmodifiableListView(deposits),
        Failure(error: final error) => throw Exception(error),
      };
    });
  }

  Future<Result<void, String>> saveOneTimeDeposit({
    String? id,
    required String accountNo,
    required double principalAmount,
    required int termYears,
    required int termMonths,
    double interestRate = 0.0,
    required String customerId,
    required OneTimeSchemeType schemeType,
    DepositStatus status = DepositStatus.active,
    required DateTime startDate,
    String? linkedSavingsAccountNo,
    List<Nominee> nominees = const [],
  }) async {
    final depositId = id ?? const Uuid().v4();

    final createResult = OneTimeDeposit.create(
      id: depositId,
      accountNo: accountNo,
      principalAmount: principalAmount,
      termYears: termYears,
      termMonths: termMonths,
      interestRate: interestRate,
      customerId: customerId,
      schemeType: schemeType,
      status: status,
      startDate: startDate,
      linkedSavingsAccountNo: linkedSavingsAccountNo,
      nominees: nominees,
    );

    final OneTimeDeposit deposit;
    switch (createResult) {
      case Failure(error: final err):
        return Failure(err);
      case Success(value: final d):
        deposit = d;
    }

    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final Result<void, String> result = id != null
        ? await repository.updateOneTimeDeposit(deposit)
        : await repository.createOneTimeDeposit(deposit);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }

  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    final repository = ref.read(oneTimeDepositRepositoryProvider);
    final result = await repository.deleteOneTimeDeposit(id);

    return switch (result) {
      Success() => const Success<void, String>(null),
      Failure(error: final err) => Failure<void, String>(err),
    };
  }
}

