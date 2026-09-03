import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
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
                .select()
                .eq('agent_id', _agentId);
            final deposits = data.map((json) => RecurringDeposit.fromJson(json)).toList();
            return Success(deposits);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit) async {
    return _saveRecurringDeposit(deposit);
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit) async {
    return _saveRecurringDeposit(deposit);
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
  Stream<Result<List<RDInstallment>, String>> watchRDInstallments(String rdId) {
    return _supabaseClient
        .from('rd_installments')
        .stream(primaryKey: ['id'])
        .eq('rd_id', rdId)
        .map((data) {
          try {
            final installments = data.map((json) => RDInstallment.fromJson(json)).toList();
            installments.sort((a, b) => a.installmentDate.compareTo(b.installmentDate));
            return Success(installments);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Stream<Result<List<RDTransaction>, String>> watchRDTransactions(String rdId) {
    return _supabaseClient
        .from('rd_transactions')
        .stream(primaryKey: ['id'])
        .eq('rd_id', rdId)
        .map((data) {
          try {
            final transactions = data.map((json) => RDTransaction.fromJson(json)).toList();
            transactions.sort((a, b) => b.paidDate.compareTo(a.paidDate));
            return Success(transactions);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> recordCustomerPayment(
    RDTransaction transaction,
    List<RDInstallment> updatedInstallments,
  ) async {
    try {
      final transactionJson = {
        'id': transaction.id,
        'rd_id': transaction.rdId,
        'paid_date': transaction.paidDate.toIso8601String().split('T').first,
        'amount': transaction.amount,
        'payment_mode': transaction.toJson()['payment_mode'],
      };

      final installmentsJson = updatedInstallments.map((inst) => {
        'id': inst.id,
        'customer_paid_amount': inst.customerPaidAmount,
        'customer_status': inst.toJson()['customer_status'],
        'late_fee': inst.lateFee,
      }).toList();

      await _supabaseClient.rpc('record_rd_customer_payment_allocated', params: {
        'p_transaction': transactionJson,
        'p_installments': installmentsJson,
      });

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
      final installmentsJson = installments.map((inst) => {
        'id': inst.id,
        'po_status': inst.toJson()['po_status'],
        'po_paid_date': inst.poPaidDate?.toIso8601String().split('T').first,
      }).toList();

      await _supabaseClient.rpc('record_rd_po_payments', params: {
        'p_installments': installmentsJson,
      });

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void, String>> _saveRecurringDeposit(RecurringDeposit deposit) async {
    try {
      final json = deposit.toJson();
      final installments = RDLedgerService.generateInitialSchedule(
        rdId: deposit.id,
        startDate: deposit.startDate,
        installmentAmount: deposit.installmentAmount,
        termYears: deposit.termYears,
        termMonths: deposit.termMonths,
        initialPaidInstallments: deposit.initialPaidInstallments,
      );
      final installmentsJson = installments.map((inst) => {
        'id': inst.id,
        'rd_id': inst.rdId,
        'installment_date': inst.installmentDate.toIso8601String().split('T').first,
        'due_date': inst.dueDate.toIso8601String().split('T').first,
        'installment_amount': inst.installmentAmount,
        'customer_paid_amount': inst.customerPaidAmount,
        'customer_status': inst.customerStatus.name,
        'po_status': inst.poStatus.name,
        'po_paid_date': inst.poPaidDate?.toIso8601String().split('T').first,
        'late_fee': inst.lateFee,
      }).toList();

      await _supabaseClient.rpc('save_recurring_deposit', params: {
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
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
