import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/models/savings_account.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _supabaseClient;

  SupabaseCustomerRepository(this._supabaseClient);

  String get _userId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() {
    return _supabaseClient
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _userId)
        .asyncMap((data) async {
          try {
            if (data.isEmpty) return const Success<List<Customer>, String>([]);

            final customerIds = data.map((json) => json['id'] as String).toList();

            final sbAccountsData = await _supabaseClient
                .from('account_identities')
                .select('customer_id, savings_accounts(account_number), nominees(name, relationship, custom_relationship, percentage)')
                .eq('account_type', 'SB')
                .inFilter('customer_id', customerIds);

            final Map<String, SavingsAccount> sbAccountMap = {};
            for (final item in sbAccountsData) {
              final custId = item['customer_id'] as String?;
              final sbAccount = _parseSavingsAccount(item);
              if (custId != null && sbAccount != null) {
                sbAccountMap[custId] = sbAccount;
              }
            }

            final customers = data.map((json) {
              final customer = Customer.fromJson(json);
              final sbAccount = sbAccountMap[customer.id];
              return sbAccount != null ? customer.copyWith(savingsAccount: sbAccount) : customer;
            }).toList();

            return Success(customers);
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Stream<Result<Customer, String>> watchCustomerById(String id) {
    return _supabaseClient
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((data) async {
          try {
            if (data.isEmpty) return const Failure<Customer, String>('Customer not found');
            final customerData = Map<String, dynamic>.from(data.first);
            if (customerData['agent_id'] != _userId) {
              return const Failure<Customer, String>('Unauthorized');
            }

            final customerId = customerData['id'] as String;

            final sbAccountData = await _supabaseClient
                .from('account_identities')
                .select('savings_accounts(account_number), nominees(name, relationship, custom_relationship, percentage)')
                .eq('customer_id', customerId)
                .eq('account_type', 'SB')
                .maybeSingle();

            final sbAccount = _parseSavingsAccount(sbAccountData);
            final customer = Customer.fromJson(customerData);
            return Success(
              sbAccount != null ? customer.copyWith(savingsAccount: sbAccount) : customer,
            );
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    try {
      final data = customer.toJson()
        ..['agent_id'] = _userId
        ..remove('savings_account')
        ..remove('migration_source');

      await _supabaseClient.from('customers').insert(data);

      if (customer.savingsAccount != null &&
          customer.savingsAccount!.accountNumber.trim().isNotEmpty) {
        await _saveSavingsAccountAndNominees(customer.id, customer.savingsAccount!);
      }

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    try {
      final data = customer.toJson()
        ..['agent_id'] = _userId
        ..remove('savings_account')
        ..remove('migration_source');

      await _supabaseClient.from('customers').update(data).eq('id', customer.id);

      final sbAccount = customer.savingsAccount;
      if (sbAccount != null && sbAccount.accountNumber.trim().isNotEmpty) {
        await _saveSavingsAccountAndNominees(customer.id, sbAccount);
      } else {
        await _deleteSavingsAccount(customer.id);
      }

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> deleteCustomer(String id) async {
    try {
      await _supabaseClient.from('customers').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Helper Methods

  SavingsAccount? _parseSavingsAccount(Map<String, dynamic>? data) {
    if (data == null) return null;
    final saRaw = data['savings_accounts'];
    final Map<String, dynamic>? saData;
    if (saRaw is Map) {
      saData = Map<String, dynamic>.from(saRaw);
    } else if (saRaw is List && saRaw.isNotEmpty) {
      saData = Map<String, dynamic>.from(saRaw.first as Map);
    } else {
      saData = null;
    }

    final accNum = saData?['account_number'] as String?;
    if (accNum == null || accNum.trim().isEmpty) return null;

    final rawNominees = (data['nominees'] as List<dynamic>?) ?? [];
    final nominees = rawNominees
        .map((n) => Nominee.fromJson(Map<String, dynamic>.from(n as Map)))
        .toList();

    return SavingsAccount(accountNumber: accNum.trim(), nominees: nominees);
  }

  Future<void> _saveSavingsAccountAndNominees(String customerId, SavingsAccount account) async {
    final accountNumber = account.accountNumber.trim();
    final existing = await _supabaseClient
        .from('account_identities')
        .select('id')
        .eq('customer_id', customerId)
        .eq('account_type', 'SB')
        .maybeSingle();

    final String accountId;
    if (existing != null) {
      accountId = existing['id'] as String;
      await _supabaseClient
          .from('savings_accounts')
          .upsert({'id': accountId, 'account_number': accountNumber});

      await _supabaseClient
          .from('nominees')
          .delete()
          .eq('account_id', accountId);
    } else {
      final accountIdentity = await _supabaseClient
          .from('account_identities')
          .insert({
            'customer_id': customerId,
            'agent_id': _userId,
            'account_type': 'SB',
          })
          .select('id')
          .single();
      accountId = accountIdentity['id'] as String;

      await _supabaseClient.from('savings_accounts').upsert({
        'id': accountId,
        'account_number': accountNumber,
      });
    }

    if (account.nominees.isNotEmpty) {
      final nomineesData = account.nominees
          .map((n) => n.toJson()..['account_id'] = accountId)
          .toList();
      await _supabaseClient.from('nominees').insert(nomineesData);
    }
  }

  Future<void> _deleteSavingsAccount(String customerId) async {
    await _supabaseClient
        .from('account_identities')
        .delete()
        .eq('customer_id', customerId)
        .eq('account_type', 'SB');
  }
}
