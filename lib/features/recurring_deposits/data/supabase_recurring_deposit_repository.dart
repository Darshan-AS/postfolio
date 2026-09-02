import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseRecurringDepositRepository implements RecurringDepositRepository {
  final SupabaseClient _supabaseClient;

  SupabaseRecurringDepositRepository(this._supabaseClient);

  String get _userId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    return _supabaseClient
        .from('account_identities')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _userId)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('recurring_deposit_details_view')
                .select()
                .eq('agent_id', _userId);
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
