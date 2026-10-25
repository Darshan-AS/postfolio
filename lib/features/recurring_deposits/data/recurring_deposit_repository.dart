import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:postfolio/core/constants/firestore_keys.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_payment_allocation_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
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
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(String id);
  Future<Result<void, String>> saveRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> schedule = const [],
  });
  Future<Result<void, String>> deleteRecurringDeposit(String id);

  // RD Ledger & Transaction Tracking
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId);
  Stream<Result<List<RDInstallment>, String>> watchAllSparseInstallments();
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId);
  Future<Result<bool, String>> hasTransactions(String rdId);
  Future<Result<bool, String>> hasPoPaidInstallments(String rdId);
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments, {
    List<RDPaymentAllocation> allocations = const [],
  });
  Future<Result<void, String>> deleteCustomerPayment(
    String transactionId,
    List<RDInstallment> updatedInstallments,
  );
  Future<Result<void, String>> updateCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  );
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  );
  Future<Result<void, String>> toggleLateFeeWaiver({
    required String installmentId,
    required bool isWaived,
    RDInstallment? installment,
  });
  Stream<Result<List<RDInstallment>, String>> watchInstallmentsForMonth(DateTime month);
  Future<Result<List<RDInstallment>, String>> getUnpaidInstallmentsBefore(DateTime date);
  Future<Result<List<RDInstallment>, String>> getRDInstallments(String rdId);
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
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(
    String id,
  ) {
    return _deposits.doc(id).snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) {
          return const Failure('Recurring Deposit not found');
        }
        return Success(snapshot.data()!);
      } catch (e) {
        return Failure(e.toString());
      }
    });
  }

  @override
  Future<Result<void, String>> saveRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> schedule = const [],
  }) async {
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
  Stream<Result<List<RDInstallment>, String>> watchAllSparseInstallments() {
    return Stream.value(const Success([]));
  }

  @override
  Future<Result<List<RDInstallment>, String>> getRDInstallments(String rdId) async {
    // Firestore does not support the relational RD ledger feature (Supabase only)
    return const Success([]);
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) {
    // Firestore does not support the relational RD ledger feature (Supabase only)
    return Stream.value(const Success([]));
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments, {
    List<RDPaymentAllocation> allocations = const [],
  }) async {
    return const Failure('Firestore repository does not support RD ledger payments');
  }

  @override
  Future<Result<void, String>> deleteCustomerPayment(
    String transactionId,
    List<RDInstallment> updatedInstallments,
  ) async {
    return const Failure('Firestore repository does not support RD ledger payments');
  }

  @override
  Future<Result<void, String>> updateCustomerPayment(
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

  @override
  Future<Result<bool, String>> hasTransactions(String rdId) async {
    return const Success(false);
  }

  @override
  Future<Result<bool, String>> hasPoPaidInstallments(String rdId) async {
    return const Success(false);
  }

  @override
  Future<Result<void, String>> toggleLateFeeWaiver({
    required String installmentId,
    required bool isWaived,
    RDInstallment? installment,
  }) async {
    return const Failure('Firestore repository does not support RD ledger');
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchInstallmentsForMonth(DateTime month) {
    return Stream.value(const Success([]));
  }

  @override
  Future<Result<List<RDInstallment>, String>> getUnpaidInstallmentsBefore(DateTime date) async {
    return const Success([]);
  }
}

class FakeRecurringDepositRepository implements RecurringDepositRepository {
  final _controller =
      StreamController<Result<List<RecurringDeposit>, String>>.broadcast();
  final _sparseInstallmentsController =
      StreamController<Result<List<RDInstallment>, String>>.broadcast();

  final List<RecurringDeposit> _deposits = FakeDataSource().recurringDeposits
      .toList();

  final Map<String, List<RDInstallment>> _fakeInstallments = {
    for (var entry in FakeDataSource().rdInstallments.entries)
      entry.key: [...entry.value],
  };
  final Map<String, List<RDTransaction>> _fakeTransactions = {};
  final Map<String, List<RDPaymentAllocation>> _fakeAllocations = {};

  final _installmentsControllers = <String, StreamController<Result<List<RDInstallment>, String>>>{};
  final _transactionsControllers = <String, StreamController<Result<List<RDTransaction>, String>>>{};
  final _monthInstallmentsControllers = <String, StreamController<Result<List<RDInstallment>, String>>>{};

  String _monthKey(DateTime m) => '${m.year}-${m.month}';

  StreamController<Result<List<RDInstallment>, String>> _getMonthController(DateTime m) {
    return _monthInstallmentsControllers.putIfAbsent(_monthKey(m), () {
      return StreamController<Result<List<RDInstallment>, String>>.broadcast();
    });
  }

  List<RDInstallment> _getAllSparseInstallments() {
    final list = <RDInstallment>[];
    for (final entry in _fakeInstallments.entries) {
      final deposit = _deposits.where((d) => d.id == entry.key).firstOrNull;
      final sparse = RDLedgerService.extractSparseInstallments(
        entry.value,
        initialPaidInstallments: deposit?.initialPaidInstallments ?? 0,
      );
      list.addAll(sparse);
    }
    return list;
  }

  List<RDInstallment> _getInstallmentsForMonth(DateTime m) {
    final list = <RDInstallment>[];
    final processedRdIds = <String>{};

    for (final deposit in _deposits) {
      processedRdIds.add(deposit.id);
      final insts = _getHydratedInstallments(deposit.id);
      for (final inst in insts) {
        if (inst.installmentDate.year == m.year &&
            inst.installmentDate.month == m.month) {
          list.add(inst);
        }
      }
    }

    for (final entry in _fakeInstallments.entries) {
      if (processedRdIds.contains(entry.key)) continue;
      for (final inst in entry.value) {
        if (inst.installmentDate.year == m.year &&
            inst.installmentDate.month == m.month) {
          list.add(inst);
        }
      }
    }
    return list;
  }

  void _emitMonthInstallments() {
    if (!_sparseInstallmentsController.isClosed) {
      _sparseInstallmentsController.add(Success(_getAllSparseInstallments()));
    }
    for (final entry in _monthInstallmentsControllers.entries) {
      final parts = entry.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final date = DateTime(y, m);
      if (!entry.value.isClosed) {
        entry.value.add(Success(_getInstallmentsForMonth(date)));
      }
    }
  }

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

  List<RDInstallment> _getInstallments(String rdId) {
    return _fakeInstallments.putIfAbsent(rdId, () => []);
  }

  List<RDInstallment> _getHydratedInstallments(String rdId) {
    final stored = _getInstallments(rdId);
    final deposit = _deposits.where((d) => d.id == rdId).firstOrNull;
    if (deposit == null) return [...stored];
    if (stored.length == deposit.totalMonths) {
      return [...stored];
    }
    final hydrated = RDLedgerService.hydrateSchedule(
      deposit: deposit,
      sparseInstallments: stored,
    );
    return hydrated;
  }

  void _upsertInstallmentsInMemory(
    String rdId,
    List<RDInstallment> updatedInstallments,
  ) {
    final currentInsts = _getInstallments(rdId);
    if (currentInsts.isEmpty) {
      final deposit = _deposits.where((d) => d.id == rdId).firstOrNull;
      if (deposit != null) {
        currentInsts.addAll(
          RDLedgerService.generateInitialSchedule(
            rdId: deposit.id,
            startDate: deposit.startDate,
            installmentAmount: deposit.installmentAmount,
            termYears: deposit.termYears,
            termMonths: deposit.termMonths,
            initialPaidInstallments: deposit.initialPaidInstallments,
          ),
        );
      }
    }

    for (final updated in updatedInstallments) {
      var idx = currentInsts.indexWhere((inst) => inst.id == updated.id);
      if (idx == -1) {
        idx = currentInsts.indexWhere(
          (inst) =>
              inst.installmentDate.year == updated.installmentDate.year &&
              inst.installmentDate.month == updated.installmentDate.month,
        );
      }
      if (idx != -1) {
        currentInsts[idx] = updated;
      } else {
        currentInsts.add(updated);
      }
    }
    currentInsts.sort((a, b) => a.installmentDate.compareTo(b.installmentDate));
  }

  List<RDTransaction> _getTransactions(String rdId) {
    return _fakeTransactions.putIfAbsent(rdId, () => []);
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
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(
    String id,
  ) async* {
    final deposit = _deposits.where((d) => d.id == id).firstOrNull;
    if (deposit != null) {
      yield Success(deposit);
    } else {
      yield const Failure('Recurring Deposit not found');
    }

    yield* _controller.stream.map((result) {
      return switch (result) {
        Success(value: final deposits) => () {
          final d = deposits.where((d) => d.id == id).firstOrNull;
          if (d != null) {
            return Success<RecurringDeposit, String>(d);
          }
          return const Failure<RecurringDeposit, String>(
            'Recurring Deposit not found',
          );
        }(),
        Failure(error: final error) => Failure(error),
      };
    });
  }

  @override
  Future<Result<void, String>> saveRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> schedule = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index != -1) {
      final existing = _deposits[index];
      final transactions = _getTransactions(deposit.id);
      final validation = RecurringDeposit.validateUpdate(
        existing: existing,
        updated: deposit,
        hasPayments: transactions.isNotEmpty,
      );
      if (validation case Failure(error: final err)) {
        return Failure(err);
      }
      _deposits[index] = deposit;

      if (transactions.isEmpty) {
        final currentInsts = _getInstallments(deposit.id);
        currentInsts.clear();
        if (schedule.isNotEmpty) {
          currentInsts.addAll(schedule);
        }
        _getInstallmentsController(
          deposit.id,
        ).add(Success(_getHydratedInstallments(deposit.id)));
        _emitMonthInstallments();
      }

      _emit();
      return const Success(null);
    } else {
      final newDeposit = deposit.copyWith(
        id: deposit.id.isEmpty ? const Uuid().v4() : deposit.id,
      );
      _deposits.add(newDeposit);
      final insts = _getInstallments(newDeposit.id);
      insts.clear();
      if (schedule.isNotEmpty) {
        insts.addAll(schedule);
      }
      _getInstallmentsController(
        newDeposit.id,
      ).add(Success(_getHydratedInstallments(newDeposit.id)));
      _emitMonthInstallments();
      _emit();
      return const Success(null);
    }
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _deposits.length;
    _deposits.removeWhere((d) => d.id == id);
    if (_deposits.length < initialLength) {
      _fakeInstallments.remove(id);
      _fakeTransactions.remove(id);
      _fakeAllocations.remove(id);
      _emitMonthInstallments();
      _emit();
      return const Success(null);
    }
    return const Failure('Recurring Deposit not found');
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId) async* {
    yield Success(_getHydratedInstallments(rdId));
    yield* _getInstallmentsController(rdId).stream;
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchAllSparseInstallments() async* {
    yield Success(_getAllSparseInstallments());
    yield* _sparseInstallmentsController.stream;
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) async* {
    yield Success(_getTransactions(rdId));
    yield* _getTransactionsController(rdId).stream;
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments, {
    List<RDPaymentAllocation> allocations = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rdId = transaction.rdId;

    final txs = _getTransactions(rdId);
    txs.insert(0, transaction);
    _getTransactionsController(rdId).add(Success([...txs]));

    if (allocations.isNotEmpty) {
      final list = _fakeAllocations.putIfAbsent(rdId, () => []);
      list.removeWhere((a) => a.transactionId == transaction.id);
      list.addAll(allocations);
    }

    _upsertInstallmentsInMemory(rdId, updatedInstallments);
    _getInstallmentsController(rdId).add(Success(_getHydratedInstallments(rdId)));
    _emitMonthInstallments();

    return const Success(null);
  }

  @override
  Future<Result<void, String>> deleteCustomerPayment(
    String transactionId,
    List<RDInstallment> updatedInstallments,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    String? targetRdId;
    for (final entry in _fakeTransactions.entries) {
      if (entry.value.any((t) => t.id == transactionId)) {
        targetRdId = entry.key;
        break;
      }
    }

    if (targetRdId == null) {
      return const Failure('Transaction not found');
    }

    final txs = _getTransactions(targetRdId);
    txs.removeWhere((t) => t.id == transactionId);
    _getTransactionsController(targetRdId).add(Success([...txs]));

    _fakeAllocations[targetRdId]?.removeWhere(
      (a) => a.transactionId == transactionId,
    );

    _upsertInstallmentsInMemory(targetRdId, updatedInstallments);
    _getInstallmentsController(targetRdId).add(
      Success(_getHydratedInstallments(targetRdId)),
    );
    _emitMonthInstallments();

    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rdId = transaction.rdId;

    final txs = _getTransactions(rdId);
    final txIdx = txs.indexWhere((t) => t.id == transaction.id);
    if (txIdx != -1) {
      txs[txIdx] = transaction;
    } else {
      txs.insert(0, transaction);
    }
    _getTransactionsController(rdId).add(Success([...txs]));

    _upsertInstallmentsInMemory(rdId, updatedInstallments);
    _getInstallmentsController(rdId).add(Success(_getHydratedInstallments(rdId)));
    _emitMonthInstallments();

    return const Success(null);
  }

  @override
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (installments.isEmpty) return const Success(null);

    final byRd = <String, List<RDInstallment>>{};
    for (final inst in installments) {
      byRd.putIfAbsent(inst.rdId, () => []).add(inst);
    }

    for (final entry in byRd.entries) {
      _upsertInstallmentsInMemory(entry.key, entry.value);
      _getInstallmentsController(entry.key).add(
        Success(_getHydratedInstallments(entry.key)),
      );
    }
    _emitMonthInstallments();

    return const Success(null);
  }

  @override
  Future<Result<bool, String>> hasTransactions(String rdId) async {
    final hasTx = _getTransactions(rdId).isNotEmpty;
    return Success(hasTx);
  }

  @override
  Future<Result<bool, String>> hasPoPaidInstallments(String rdId) async {
    final deposit = _deposits.where((d) => d.id == rdId).firstOrNull;
    final initialPaid = deposit?.initialPaidInstallments ?? 0;
    final insts = _getHydratedInstallments(rdId);
    for (int i = 0; i < insts.length; i++) {
      if (i >= initialPaid && insts[i].poStatus == RDPoStatus.paid) {
        return const Success(true);
      }
    }
    return const Success(false);
  }

  @override
  Future<Result<void, String>> toggleLateFeeWaiver({
    required String installmentId,
    required bool isWaived,
    RDInstallment? installment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final deposit in _deposits) {
      final hydrated = _getHydratedInstallments(deposit.id);
      final idx = hydrated.indexWhere((inst) => inst.id == installmentId);
      if (idx != -1) {
        final existing = hydrated[idx];
        if (isWaived &&
            existing.paidLateFee >= existing.lateFee &&
            existing.lateFee > 0) {
          return const Failure(
            'Cannot forgive an already paid default fee. Edit payment transaction to reallocate funds.',
          );
        }
        final updated = existing.copyWith(
          isLateFeeWaived: isWaived,
          updatedAt: DateTime.now(),
        );
        _upsertInstallmentsInMemory(deposit.id, [updated]);
        _getInstallmentsController(deposit.id).add(
          Success(_getHydratedInstallments(deposit.id)),
        );
        _emitMonthInstallments();
        return const Success(null);
      }
    }

    for (final entry in _fakeInstallments.entries) {
      final list = entry.value;
      final idx = list.indexWhere((inst) => inst.id == installmentId);
      if (idx != -1) {
        final existing = list[idx];
        if (isWaived &&
            existing.paidLateFee >= existing.lateFee &&
            existing.lateFee > 0) {
          return const Failure(
            'Cannot forgive an already paid default fee. Edit payment transaction to reallocate funds.',
          );
        }
        list[idx] = existing.copyWith(
          isLateFeeWaived: isWaived,
          updatedAt: DateTime.now(),
        );
        _getInstallmentsController(entry.key).add(
          Success(_getHydratedInstallments(entry.key)),
        );
        _emitMonthInstallments();
        return const Success(null);
      }
    }
    return const Failure('Installment not found');
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchInstallmentsForMonth(DateTime month) async* {
    yield Success(_getInstallmentsForMonth(month));
    yield* _getMonthController(month).stream;
  }

  @override
  Future<Result<List<RDInstallment>, String>> getUnpaidInstallmentsBefore(DateTime date) async {
    final list = <RDInstallment>[];
    final processedRdIds = <String>{};
    for (final deposit in _deposits) {
      processedRdIds.add(deposit.id);
      for (final inst in _getHydratedInstallments(deposit.id)) {
        if (inst.installmentDate.isBefore(date) && !inst.isInstallmentPaid) {
          list.add(inst);
        }
      }
    }
    for (final entry in _fakeInstallments.entries) {
      if (processedRdIds.contains(entry.key)) continue;
      for (final inst in entry.value) {
        if (inst.installmentDate.isBefore(date) && !inst.isInstallmentPaid) {
          list.add(inst);
        }
      }
    }
    return Success(list);
  }

  @override
  Future<Result<List<RDInstallment>, String>> getRDInstallments(String rdId) async {
    return Success(_getHydratedInstallments(rdId));
  }

  void dispose() {
    _controller.close();
    _sparseInstallmentsController.close();
    for (final ctrl in _installmentsControllers.values) {
      ctrl.close();
    }
    for (final ctrl in _transactionsControllers.values) {
      ctrl.close();
    }
    for (final ctrl in _monthInstallmentsControllers.values) {
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
