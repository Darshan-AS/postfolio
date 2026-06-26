import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseOneTimeDepositRepository implements OneTimeDepositRepository {
  final SupabaseClient _supabaseClient;

  SupabaseOneTimeDepositRepository(this._supabaseClient);

  String get _userId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() {
    return _supabaseClient
        .from('one_time_deposits')
        .stream(primaryKey: ['id'])
        // Assuming we join account_identities to get agent_id for filtering, 
        // but for parity, if flat schema is used initially, it should work.
        // If agent_id is on account_identities, we might need a view or do RLS.
        // Assuming RLS handles user isolation or we will do the join later.
        .map((data) {
          try {
            final deposits = data.map((json) => OneTimeDeposit.fromJson(json)).toList();
            return Success(deposits);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(OneTimeDeposit deposit) async {
    try {
      final data = deposit.toJson();
      
      // For V1 parity, assuming flat tables or proper joins will be added.
      // Remove complex types that can't be inserted directly
      data.remove('nominees');
      data.remove('migration_source');

      // Note: We need to insert into account_identities first
      final accountData = {
        'id': deposit.id, // Enforce same ID
        'customer_id': deposit.customerId,
        'agent_id': _userId,
        'account_type': 'OTD', // Or specific type
      };
      
      await _supabaseClient.from('account_identities').insert(accountData);

      // Now insert into one_time_deposits
      await _supabaseClient.from('one_time_deposits').insert(data);
      
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit) async {
    try {
      final data = deposit.toJson();
      data.remove('nominees');
      data.remove('migration_source');
      
      await _supabaseClient
          .from('one_time_deposits')
          .update(data)
          .eq('id', deposit.id);
          
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
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
}
