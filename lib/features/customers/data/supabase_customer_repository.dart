import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _supabaseClient;
  final _localMutations = StreamController<void>.broadcast();

  SupabaseCustomerRepository(this._supabaseClient);

  String get _agentId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() {
    final agentId = _agentId;
    return SupabasePaginatedQuery.watchPaginatedCollection<Customer>(
      client: _supabaseClient,
      channelPrefix: 'customers-list',
      table: 'customers',
      filterColumn: 'agent_id',
      filterValue: agentId,
      localMutations: _localMutations.stream,
      fetchAll: () => SupabasePaginatedQuery.fetchAllPages<Customer>(
        fetchPage: (from, to) => _supabaseClient
            .from('customers')
            .select()
            .eq('agent_id', agentId)
            .order('name', ascending: true)
            .order('id', ascending: true)
            .range(from, to),
        fromJson: Customer.fromJson,
      ),
    );
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
            return Failure(SupabaseErrorMapper.describe(e));
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
      // One request, one transaction: the customer and its savings account go together.
      // A customer who still owns an OTD/RD is refused by the database (23503) and nothing
      // is removed.
      await _supabaseClient.rpc('delete_customer', params: {'p_id': id});
      _localMutations.add(null);
      return const Success(null);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
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
      _localMutations.add(null);
      return const Success(null);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }
}
