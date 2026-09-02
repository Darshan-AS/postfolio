import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/utils/result.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _supabaseClient;

  SupabaseCustomerRepository(this._supabaseClient);

  String get _agentId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() {
    return _supabaseClient
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('agent_id', _agentId)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('customer_details_view')
                .select()
                .eq('agent_id', _agentId);
            final customers = data.map((json) => Customer.fromJson(json)).toList();
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
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from('customer_details_view')
                .select()
                .eq('id', id)
                .maybeSingle();
            if (data == null) return const Failure<Customer, String>('Customer not found');
            if (data['agent_id'] != _agentId) {
              return const Failure<Customer, String>('Unauthorized');
            }
            return Success(Customer.fromJson(data));
          } catch (e) {
            return Failure(e.toString());
          }
        });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    return _saveCustomer(customer);
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    return _saveCustomer(customer);
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

  Future<Result<void, String>> _saveCustomer(Customer customer) async {
    try {
      await _supabaseClient.rpc('save_customer_with_sb_account', params: {
        'p_id': customer.id,
        'p_name': customer.name,
        'p_phone': customer.phone,
        'p_email': customer.email,
        'p_address': customer.address,
        'p_cif_number': customer.cifNumber,
        'p_date_of_birth': customer.dateOfBirth?.toIso8601String().split('T').first,
        'p_aadhaar_number': customer.aadhaarNumber,
        'p_pan_number': customer.panNumber,
        'p_notes': customer.notes,
        'p_sb_account_number': customer.savingsAccount?.accountNumber,
        'p_nominees': customer.savingsAccount?.nominees.map((n) => n.toJson()).toList() ?? [],
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
