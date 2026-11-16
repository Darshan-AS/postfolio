import 'dart:async';

import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/one_time_deposits/data/supabase_one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'one_time_deposit_repository.g.dart';

abstract class OneTimeDepositRepository {
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits();
  Stream<Result<OneTimeDeposit, String>> watchOneTimeDepositById(String id);
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit);
  Future<Result<void, String>> updateDepositStatus(
    String id,
    DepositStatus status,
  );
  Future<Result<void, String>> deleteOneTimeDeposit(String id);
}

class FakeOneTimeDepositRepository implements OneTimeDepositRepository {
  FakeOneTimeDepositRepository({
    List<OneTimeDeposit>? deposits,
    this.delay = const Duration(milliseconds: 500),
  }) : _deposits = [...(deposits ?? FakeDataSource().oneTimeDeposits)];

  final Duration delay;

  final _controller =
      StreamController<Result<List<OneTimeDeposit>, String>>.broadcast();

  final List<OneTimeDeposit> _deposits;

  List<OneTimeDeposit> get deposits => List.unmodifiable(_deposits);

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._deposits]));
    }
  }

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Stream<Result<OneTimeDeposit, String>> watchOneTimeDepositById(
    String id,
  ) async* {
    final deposit = _deposits.where((d) => d.id == id).firstOrNull;
    if (deposit != null) {
      yield Success(deposit);
    } else {
      yield const Failure('One Time Deposit not found');
    }

    yield* _controller.stream.map((result) {
      return switch (result) {
        Success(value: final deposits) => () {
          final d = deposits.where((d) => d.id == id).firstOrNull;
          if (d != null) {
            return Success<OneTimeDeposit, String>(d);
          }
          return const Failure<OneTimeDeposit, String>(
            'One Time Deposit not found',
          );
        }(),
        Failure(error: final error) => Failure(error),
      };
    });
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final newDeposit = deposit.copyWith(
      id: deposit.id.isEmpty ? const Uuid().v7() : deposit.id,
    );
    _deposits.add(newDeposit);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index != -1) {
      _deposits[index] = deposit;
      _emit();
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }

  @override
  Future<Result<void, String>> updateDepositStatus(
    String id,
    DepositStatus status,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final index = _deposits.indexWhere((d) => d.id == id);
    if (index != -1) {
      _deposits[index] = _deposits[index].copyWith(status: status);
      _emit();
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }

  @override
  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final initialLength = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length < initialLength) {
      _emit();
      return const Success(null);
    }
    return const Failure('One Time Deposit not found');
  }

  void dispose() {
    _controller.close();
  }
}

@riverpod
OneTimeDepositRepository oneTimeDepositRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    final repo = FakeOneTimeDepositRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseOneTimeDepositRepository(ref.watch(supabaseClientProvider));
}
