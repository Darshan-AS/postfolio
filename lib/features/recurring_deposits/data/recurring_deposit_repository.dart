import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:uuid/uuid.dart';

import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_deposit_repository.g.dart';

abstract class RecurringDepositRepository {
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits();
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> initialSchedule = const [],
  });
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit);
  Future<Result<void, String>> deleteRecurringDeposit(String id);

  // RD Ledger & Transaction Tracking
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId);
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId);
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  );
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  );
}

class FirestoreRecurringDepositRepository
    implements RecurringDepositRepository {
  final firestore.FirebaseFirestore _firestore;
  final String _agentId;

  FirestoreRecurringDepositRepository(this._firestore, this._agentId);

  firestore.CollectionReference<RecurringDeposit> get _deposits => _firestore
      .collection(FirestoreCollections.users)
      .doc(_agentId)
      .collection(FirestoreCollections.recurringDeposits)
      .withConverter<RecurringDeposit>(
        fromFirestore: (snapshot, _) {
          final data = snapshot.data()!;
          data[FirestoreKeys.id] = snapshot.id;
          return RecurringDeposit.fromJson(data);
        },
        toFirestore: (deposit, _) {
          final data = deposit.toJson();
          data.remove(FirestoreKeys.id);
          if (deposit.createdAt == null) {
            data[FirestoreKeys.createdAt] =
                firestore.FieldValue.serverTimestamp();
          }
          data[FirestoreKeys.updatedAt] =
              firestore.FieldValue.serverTimestamp();
          return data;
        },
      );

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    return _deposits.snapshots().map((snapshot) {
      try {
        final deposits = snapshot.docs.map((doc) => doc.data()).toList();
        return Success(deposits);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> initialSchedule = const [],
  }) async {
    try {
      _deposits.doc(deposit.id).set(deposit);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    try {
      _deposits.doc(deposit.id).set(deposit, firestore.SetOptions(merge: true));
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    try {
      _deposits.doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId) {
    // Firestore does not support the relational RD ledger feature (Supabase only)
    return Stream.value(const Success([]));
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) {
    // Firestore does not support the relational RD ledger feature (Supabase only)
    return Stream.value(const Success([]));
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  ) async {
    return const Failure('Firestore repository does not support RD ledger payments');
  }

  @override
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  ) async {
    return const Failure('Firestore repository does not support RD ledger payments');
  }
}

class FakeRecurringDepositRepository implements RecurringDepositRepository {
  final _controller =
      StreamController<Result<List<RecurringDeposit>, String>>.broadcast();

  final List<RecurringDeposit> _deposits = FakeDataSource().recurringDeposits
      .toList();

  final Map<String, List<RDInstallment>> _fakeInstallments = {};
  final Map<String, List<RDTransaction>> _fakeTransactions = {};

  final _installmentsControllers = <String, StreamController<Result<List<RDInstallment>, String>>>{};
  final _transactionsControllers = <String, StreamController<Result<List<RDTransaction>, String>>>{};

  StreamController<Result<List<RDInstallment>, String>> _getInstallmentsController(String rdId) {
    return _installmentsControllers.putIfAbsent(rdId, () {
      return StreamController<Result<List<RDInstallment>, String>>.broadcast();
    });
  }

  StreamController<Result<List<RDTransaction>, String>> _getTransactionsController(String rdId) {
    return _transactionsControllers.putIfAbsent(rdId, () {
      return StreamController<Result<List<RDTransaction>, String>>.broadcast();
    });
  }

  List<RDInstallment> _getOrGenerateInstallments(String rdId) {
    if (!_fakeInstallments.containsKey(rdId)) {
      final rdIndex = _deposits.indexWhere((d) => d.id == rdId);
      final rd = rdIndex != -1 ? _deposits[rdIndex] : _deposits.first;
      final schedule = RDLedgerService.generateInitialSchedule(
        rdId: rd.id,
        startDate: rd.startDate,
        installmentAmount: rd.installmentAmount,
        termYears: rd.termYears,
        termMonths: rd.termMonths,
        initialPaidInstallments: rd.initialPaidInstallments,
      );
      _fakeInstallments[rdId] = schedule;
    }
    return _fakeInstallments[rdId]!;
  }

  List<RDTransaction> _getOrGenerateTransactions(String rdId) {
    if (!_fakeTransactions.containsKey(rdId)) {
      _fakeTransactions[rdId] = [];
    }
    return _fakeTransactions[rdId]!;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._deposits]));
    }
  }

  @override
  Stream<Result<List<RecurringDeposit>, String>>
  watchRecurringDeposits() async* {
    yield Success([..._deposits]);
    yield* _controller.stream;
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> initialSchedule = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeposit = deposit.copyWith(
      id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id,
    );
    _deposits.add(newDeposit);
    if (initialSchedule.isNotEmpty) {
      final insts = _getOrGenerateInstallments(newDeposit.id);
      insts.clear();
      insts.addAll(initialSchedule);
      _getInstallmentsController(newDeposit.id).add(Success([...insts]));
    }
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index != -1) {
      _deposits[index] = deposit;
      _emit();
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length < initialLength) {
      _emit();
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId) async* {
    yield Success(_getOrGenerateInstallments(rdId));
    yield* _getInstallmentsController(rdId).stream;
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) async* {
    yield Success(_getOrGenerateTransactions(rdId));
    yield* _getTransactionsController(rdId).stream;
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rdId = transaction.rdId;

    final txs = _getOrGenerateTransactions(rdId);
    txs.insert(0, transaction);
    _getTransactionsController(rdId).add(Success([...txs]));

    final currentInsts = _getOrGenerateInstallments(rdId);
    for (final updated in updatedInstallments) {
      final idx = currentInsts.indexWhere((inst) => inst.id == updated.id);
      if (idx != -1) {
        currentInsts[idx] = updated;
      }
    }
    _getInstallmentsController(rdId).add(Success([...currentInsts]));

    return const Success(null);
  }

  @override
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (installments.isEmpty) return const Success(null);
    final rdId = installments.first.rdId;

    final currentInsts = _getOrGenerateInstallments(rdId);
    for (final updated in installments) {
      final idx = currentInsts.indexWhere((inst) => inst.id == updated.id);
      if (idx != -1) {
        currentInsts[idx] = updated;
      }
    }
    _getInstallmentsController(rdId).add(Success([...currentInsts]));

    return const Success(null);
  }

  void dispose() {
    _controller.close();
    for (final ctrl in _installmentsControllers.values) {
      ctrl.close();
    }
    for (final ctrl in _transactionsControllers.values) {
      ctrl.close();
    }
  }
}

// Global Provider for the Repository.
@riverpod
RecurringDepositRepository recurringDepositRepository(Ref ref) {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    final repo = FakeRecurringDepositRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }

  if (Env.useSupabase) {
    return SupabaseRecurringDepositRepository(ref.watch(supabaseClientProvider));
  }

  final authState = ref.watch(authControllerProvider);
  final agentId = switch (authState) {
    AuthStateAuthenticated state => state.user.id,
    _ => null,
  };

  if (agentId == null) {
    throw StateError(
      'Agent is not authenticated. Cannot access RecurringDepositRepository.',
    );
  }

  return FirestoreRecurringDepositRepository(
    firestore.FirebaseFirestore.instance,
    agentId,
  );
}
