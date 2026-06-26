import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
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
    // For phase 2, we will fetch customers and their SB accounts using joins
    // Select syntax: *, account_identities(id, account_type, savings_accounts(*), nominees(*))
    // We will do a basic fetch for now to get parity.
    return _supabaseClient
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _userId)
        .map((data) {
          try {
            final customers = data.map((json) {
              // Basic parsing for now
              return Customer.fromJson(json);
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
        .map((data) {
          try {
            if (data.isEmpty) return const Failure('Customer not found');
            final customerData = data.first;
            if (customerData['agent_id'] != _userId) return const Failure('Unauthorized');
            return Success(Customer.fromJson(customerData));
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data['agent_id'] = _userId;
      
      // Remove complex types and non-existent columns before inserting into customers
      data.remove('savings_account');
      data.remove('migration_source');

      await _supabaseClient.from('customers').insert(data);
      
      // Handle Savings Account Normalization
      if (customer.savingsAccount != null) {
        final accountData = {
          'customer_id': customer.id,
          'agent_id': _userId,
          'account_type': 'SB',
        };
        
        final accountIdResult = await _supabaseClient
            .from('account_identities')
            .insert(accountData)
            .select('id')
            .single();
            
        final accountId = accountIdResult['id'];
        
        await _supabaseClient.from('savings_accounts').insert({
          'id': accountId,
          'account_number': customer.savingsAccount!.accountNumber,
        });
        
        if (customer.savingsAccount!.nominees.isNotEmpty) {
          final nomineesData = customer.savingsAccount!.nominees.map((n) => {
            'account_id': accountId,
            'name': n.name,
            'relationship': n.relationship.name, // Convert enum to string
            'share_percentage': n.percentage,
          }).toList();
          
          await _supabaseClient.from('nominees').insert(nomineesData);
        }
      }

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data['agent_id'] = _userId;
      
      data.remove('savings_account');
      data.remove('migration_source');
      
      await _supabaseClient
          .from('customers')
          .update(data)
          .eq('id', customer.id);
          
      // Note: Updating related tables (savings_accounts, nominees) is complex
      // For V1 of migration, we just handle the customer table.
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
}
