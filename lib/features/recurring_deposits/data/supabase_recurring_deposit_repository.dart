import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
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
      'start_date,created_at,updated_at';

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
            final deposits = data.map((json) => RecurringDeposit.fromJson(json)).toList();
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

  Future<Result<void, String>> _saveRecurringDeposit(RecurringDeposit deposit) async {
    try {
      final json = deposit.toJson();
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
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
