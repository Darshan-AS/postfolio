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
        .from('recurring_deposits')
        .stream(primaryKey: ['id'])
        .map((data) {
          try {
            final deposits = data.map((json) => RecurringDeposit.fromJson(json)).toList();
            return Success(deposits);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  // Note: watchRecurringDepositById is not in the interface, skipping.

  @override
  Future<Result<void, String>> createRecurringDeposit(RecurringDeposit deposit) async {
    try {
      final data = deposit.toJson();
      
      data.remove('nominees');
      data.remove('migration_source');

      final accountData = {
        'id': deposit.id,
        'customer_id': deposit.customerId,
        'agent_id': _userId,
        'account_type': 'RD',
      };
      
      await _supabaseClient.from('account_identities').insert(accountData);
      await _supabaseClient.from('recurring_deposits').insert(data);
      
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateRecurringDeposit(RecurringDeposit deposit) async {
    try {
      final data = deposit.toJson();
      data.remove('nominees');
      data.remove('migration_source');
      
      await _supabaseClient
          .from('recurring_deposits')
          .update(data)
          .eq('id', deposit.id);
          
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
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
}
