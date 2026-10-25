import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_payment_allocation_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseRecurringDepositRepository implements RecurringDepositRepository {
  final SupabaseClient _supabaseClient;

  SupabaseRecurringDepositRepository(this._supabaseClient);

  String get _agentId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  static const _listColumns =
      'id,agent_id,customer_id,customer_name,status,scheme_type,account_no,'
      'serial_no,installment_amount,interest_rate,term_years,term_months,'
      'start_date,initial_paid_installments,created_at,updated_at';

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    return _supabaseClient
        .from('account_identities')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _agentId)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('recurring_deposit_details_view')
                .select(_listColumns)
                .eq('agent_id', _agentId);
            final deposits =
                data.map((json) => RecurringDeposit.fromJson(json)).toList();
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
    return _supabaseClient
        .from('account_identities')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('recurring_deposit_details_view')
                .select()
                .eq('id', id)
                .maybeSingle();
            if (data == null) {
              return const Failure<RecurringDeposit, String>(
                'Recurring Deposit not found',
              );
            }
            if (data['agent_id'] != _agentId) {
              return const Failure<RecurringDeposit, String>('Unauthorized');
            }
            return Success(RecurringDeposit.fromJson(data));
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
    return _saveRecurringDeposit(deposit, initialSchedule: schedule);
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    try {
      await _supabaseClient.from('account_identities').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchAllSparseInstallments() {
    return _supabaseClient
        .from('rd_installments')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _agentId)
        .map((data) {
          try {
            final installments =
                data.map((json) => RDInstallment.fromJson(json)).toList();
            return Success(installments);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId) {
    return _supabaseClient
        .from('rd_installments')
        .stream(primaryKey: ['id'])
        .eq('rd_id', rdId)
        .asyncMap((data) async {
          try {
            final sparse =
                data.map((json) => RDInstallment.fromJson(json)).toList();
            final rdData = await _supabaseClient
                .from('recurring_deposit_details_view')
                .select(_listColumns)
                .eq('id', rdId)
                .maybeSingle();
            if (rdData != null) {
              final deposit = RecurringDeposit.fromJson(rdData);
              final hydrated = RDLedgerService.hydrateSchedule(
                deposit: deposit,
                sparseInstallments: sparse,
              );
              return Success(hydrated);
            }
            sparse.sort(
              (a, b) => a.installmentDate.compareTo(b.installmentDate),
            );
            return Success(sparse);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Stream<Result<List<RDInstallment>, String>> watchInstallmentsForMonth(
    DateTime month,
  ) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final startStr = startOfMonth.toIso8601String().split('T').first;
    final endStr = endOfMonth.toIso8601String().split('T').first;

    return _supabaseClient
        .from('rd_installments')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _agentId)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('rd_installments')
                .select()
                .eq('agent_id', _agentId)
                .gte('installment_date', startStr)
                .lte('installment_date', endStr);
            final installments =
                data.map((json) => RDInstallment.fromJson(json)).toList();
            installments.sort(
              (a, b) => a.installmentDate.compareTo(b.installmentDate),
            );
            return Success(installments);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<List<RDInstallment>, String>> getUnpaidInstallmentsBefore(
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final data = await _supabaseClient
          .from('rd_installments')
          .select()
          .eq('agent_id', _agentId)
          .lt('installment_date', dateStr)
          .neq('customer_status', 'fullyPaid');
      final installments =
          data.map((json) => RDInstallment.fromJson(json)).toList();
      return Success(installments);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<RDInstallment>, String>> getRDInstallments(
    String rdId,
  ) async {
    try {
      final data = await _supabaseClient
          .from('rd_installments')
          .select()
          .eq('rd_id', rdId)
          .eq('agent_id', _agentId);
      final sparse = data.map((json) => RDInstallment.fromJson(json)).toList();
      final rdData = await _supabaseClient
          .from('recurring_deposit_details_view')
          .select(_listColumns)
          .eq('id', rdId)
          .maybeSingle();
      if (rdData != null) {
        final deposit = RecurringDeposit.fromJson(rdData);
        return Success(
          RDLedgerService.hydrateSchedule(
            deposit: deposit,
            sparseInstallments: sparse,
          ),
        );
      }
      sparse.sort((a, b) => a.installmentDate.compareTo(b.installmentDate));
      return Success(sparse);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) {
    return _supabaseClient
        .from('rd_transactions')
        .stream(primaryKey: ['id'])
        .eq('rd_id', rdId)
        .map((data) {
          try {
            final transactions =
                data.map((json) => RDTransaction.fromJson(json)).toList();
            transactions.sort((a, b) => b.paidDate.compareTo(a.paidDate));
            return Success(transactions);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<bool, String>> hasTransactions(String rdId) async {
    try {
      final response = await _supabaseClient
          .from('rd_transactions')
          .select('id')
          .eq('rd_id', rdId)
          .limit(1)
          .maybeSingle();
      return Success(response != null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<bool, String>> hasPoPaidInstallments(String rdId) async {
    try {
      final response = await _supabaseClient
          .from('rd_installments')
          .select('id')
          .eq('rd_id', rdId)
          .eq('po_status', 'paid')
          .limit(1)
          .maybeSingle();
      return Success(response != null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Map<String, dynamic> _serializeInstallmentForRpc(RDInstallment inst) {
    final json = inst.toJson();
    return {
      'id': inst.id,
      'rd_id': inst.rdId,
      if (inst.installmentNo != null) 'installment_no': inst.installmentNo,
      'installment_date': inst.installmentDate.toIso8601String().split('T').first,
      'due_date': inst.dueDate.toIso8601String().split('T').first,
      'installment_amount': inst.installmentAmount,
      'customer_paid_amount': inst.customerPaidAmount,
      'customer_status': json['customer_status'],
      'po_status': json['po_status'],
      'po_paid_date': inst.poPaidDate?.toIso8601String().split('T').first,
      'late_fee': inst.lateFee,
      'paid_late_fee': inst.paidLateFee,
      'is_late_fee_waived': inst.isLateFeeWaived,
    };
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments, {
    List<RDPaymentAllocation> allocations = const [],
  }) async {
    try {
      final txJson = transaction.toJson();
      final transactionJson = {
        'id': transaction.id,
        'rd_id': transaction.rdId,
        'paid_date': transaction.paidDate.toIso8601String().split('T').first,
        'amount': transaction.amount,
        'payment_mode': txJson['payment_mode'],
        'split_mode': txJson['split_mode'],
        'installment_amount': transaction.installmentAmount,
        'late_fee_amount': transaction.lateFeeAmount,
      };

      final installmentsJson =
          updatedInstallments.map(_serializeInstallmentForRpc).toList();

      final allocationsJson = allocations
          .map(
            (a) => {
              'id': a.id,
              'transaction_id': a.transactionId,
              'rd_id': a.rdId,
              'installment_no': a.installmentNo,
              'principal_amount': a.principalAmount,
              'late_fee_amount': a.lateFeeAmount,
            },
          )
          .toList();

      await _supabaseClient.rpc(
        'record_rd_customer_payment_allocated',
        params: {
          'p_transaction': transactionJson,
          'p_installments': installmentsJson,
          'p_allocations': allocationsJson,
        },
      );

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> deleteCustomerPayment(
    String transactionId,
    List<RDInstallment> updatedInstallments,
  ) async {
    try {
      final installmentsJson =
          updatedInstallments.map(_serializeInstallmentForRpc).toList();

      await _supabaseClient.rpc(
        'delete_rd_transaction',
        params: {
          'p_transaction_id': transactionId,
          'p_installments': installmentsJson,
        },
      );

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  ) async {
    try {
      final txJson = transaction.toJson();
      final transactionJson = {
        'id': transaction.id,
        'rd_id': transaction.rdId,
        'paid_date': transaction.paidDate.toIso8601String().split('T').first,
        'amount': transaction.amount,
        'payment_mode': txJson['payment_mode'],
        'split_mode': txJson['split_mode'],
        'installment_amount': transaction.installmentAmount,
        'late_fee_amount': transaction.lateFeeAmount,
      };

      final installmentsJson =
          updatedInstallments.map(_serializeInstallmentForRpc).toList();

      await _supabaseClient.rpc(
        'update_rd_transaction',
        params: {
          'p_transaction': transactionJson,
          'p_installments': installmentsJson,
        },
      );

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> recordPoPayments(
    List<RDInstallment> installments,
  ) async {
    try {
      final installmentsJson =
          installments.map(_serializeInstallmentForRpc).toList();

      await _supabaseClient.rpc(
        'record_rd_po_payments',
        params: {
          'p_installments': installmentsJson,
        },
      );

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> toggleLateFeeWaiver({
    required String installmentId,
    required bool isWaived,
    RDInstallment? installment,
  }) async {
    try {
      await _supabaseClient.rpc(
        'toggle_rd_late_fee_waiver',
        params: {
          'p_installment_id': installmentId,
          'p_is_waived': isWaived,
          if (installment != null)
            'p_installment': _serializeInstallmentForRpc(installment),
        },
      );
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void, String>> _saveRecurringDeposit(
    RecurringDeposit deposit, {
    List<RDInstallment> initialSchedule = const [],
  }) async {
    try {
      final json = deposit.toJson();
      final sparseSchedule = RDLedgerService.extractSparseInstallments(
        initialSchedule,
        initialPaidInstallments: deposit.initialPaidInstallments,
      );
      final installmentsJson =
          sparseSchedule.map(_serializeInstallmentForRpc).toList();

      await _supabaseClient.rpc(
        'save_recurring_deposit',
        params: {
          'p_id': deposit.id,
          'p_customer_id': deposit.customerId,
          'p_status': json['status'],
          'p_scheme_type': json['scheme_type'],
          'p_account_no': deposit.accountNo,
          'p_serial_no': deposit.serialNo,
          'p_installment_amount': deposit.installmentAmount,
          'p_interest_rate': deposit.interestRate,
          'p_term_years': deposit.termYears,
          'p_term_months': deposit.termMonths,
          'p_start_date': deposit.startDate.toIso8601String().split('T').first,
          'p_nominees': deposit.nominees.map((n) => n.toJson()).toList(),
          'p_initial_paid_installments': deposit.initialPaidInstallments,
          'p_installments': installmentsJson,
        },
      );
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
