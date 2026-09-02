import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseOneTimeDepositRepository implements OneTimeDepositRepository {
  final SupabaseClient _supabaseClient;

  SupabaseOneTimeDepositRepository(this._supabaseClient);

  String get _agentId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() {
    return _supabaseClient
        .from('account_identities')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _agentId)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('one_time_deposit_details_view')
                .select()
                .eq('agent_id', _agentId);
            final deposits = data.map((json) => OneTimeDeposit.fromJson(json)).toList();
            return Success(deposits);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit) async {
    return _saveOneTimeDeposit(deposit);
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit) async {
    return _saveOneTimeDeposit(deposit);
  }

  @override
  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    try {
      // Deleting from account_identities will cascade to one_time_deposits
      await _supabaseClient.from('account_identities').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void, String>> _saveOneTimeDeposit(OneTimeDeposit deposit) async {
    try {
      final json = deposit.toJson();
      await _supabaseClient.rpc('save_one_time_deposit', params: {
        'p_id': deposit.id,
        'p_customer_id': deposit.customerId,
        'p_status': json['status'],
        'p_scheme_type': json['scheme_type'],
        'p_account_no': deposit.accountNo,
        'p_principal_amount': deposit.principalAmount,
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
