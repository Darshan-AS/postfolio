import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/core/models/nominee.dart';
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
        .asyncMap((data) async {
          try {
            if (data.isEmpty) return const Success<List<OneTimeDeposit>, String>([]);

            final accountIds = data.map((json) => json['id'] as String).toList();
            final nomineesData = await _supabaseClient
                .from('nominees')
                .select('account_id, name, relationship, custom_relationship, percentage')
                .inFilter('account_id', accountIds);

            final Map<String, List<Nominee>> nomineesMap = {};
            for (final item in nomineesData) {
              final accId = item['account_id'] as String?;
              if (accId != null) {
                final nominee = Nominee.fromJson(Map<String, dynamic>.from(item as Map));
                nomineesMap.putIfAbsent(accId, () => []).add(nominee);
              }
            }

            final deposits = data.map((json) {
              final depositMap = Map<String, dynamic>.from(json);
              final accId = depositMap['id'] as String;
              if (nomineesMap.containsKey(accId)) {
                depositMap['nominees'] = nomineesMap[accId]!.map((n) => n.toJson()).toList();
              }
              return OneTimeDeposit.fromJson(depositMap);
            }).toList();

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
      
      data.remove('nominees');
      data.remove('migration_source');

      final accountData = {
        'id': deposit.id,
        'customer_id': deposit.customerId,
        'agent_id': _userId,
        'account_type': 'OTD',
      };
      
      await _supabaseClient.from('account_identities').insert(accountData);
      await _supabaseClient.from('one_time_deposits').insert(data);
      
      if (deposit.nominees.isNotEmpty) {
        final nomineesData = deposit.nominees.map((n) => n.toJson()..['account_id'] = deposit.id).toList();
        await _supabaseClient.from('nominees').insert(nomineesData);
      }

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(OneTimeDeposit deposit) async {
    try {
      final data = deposit.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('nominees');
      data.remove('migration_source');
      
      await _supabaseClient
          .from('one_time_deposits')
          .update(data)
          .eq('id', deposit.id);
          
      await _supabaseClient.from('nominees').delete().eq('account_id', deposit.id);
      if (deposit.nominees.isNotEmpty) {
        final nomineesData = deposit.nominees.map((n) => n.toJson()..['account_id'] = deposit.id).toList();
        await _supabaseClient.from('nominees').insert(nomineesData);
      }

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
