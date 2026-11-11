@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('Test SupabaseCustomerRepository create and update with savings account', () async {
    final client = SupabaseClient(
      'http://127.0.0.1:54321',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // Sign in anonymously or with test user
    final authRes = await client.auth.signUp(
      email: 'testagent_${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'password123',
    );

    final user = authRes.user ?? client.auth.currentUser;
    expect(user, isNotNull);

    // Register cleanup hook to delete test agent profile and cascaded records
    addTearDown(() async {
      await client.from('agent_profiles').delete().eq('id', user!.id);
    });

    // Ensure agent_profile exists
    await client.from('agent_profiles').upsert({
      'id': user!.id,
      'name': 'Test Agent',
      'email': user.email,
    });

    final repository = SupabaseCustomerRepository(client);

    final customerId = const Uuid().v4();
    final createResult = Customer.create(
      id: customerId,
      name: 'Test Customer',
      phone: '9876543210',
      savingsAccountNumber: 'SB123456789',
      savingsNominees: const [
        Nominee(
          name: 'Jane Doe',
          relationship: NomineeRelationship.wife,
          percentage: 100.0,
        ),
      ],
    );

    expect(createResult, isA<Success<Customer, String>>());
    final customer = (createResult as Success<Customer, String>).value;

    final saveResult = await repository.createCustomer(customer);
    expect(saveResult, isA<Success<void, String>>());

    // Verify account_identities
    final ai = await client.from('account_identities').select().eq('customer_id', customerId);
    expect(ai.length, 1);

    // Verify savings_accounts
    final sa = await client.from('savings_accounts').select();
    expect(sa.length, greaterThanOrEqualTo(1));

    final updateCustomerResult = Customer.create(
      id: customerId,
      name: 'Test Customer Updated',
      phone: '9876543210',
      savingsAccountNumber: 'SB999999999',
      savingsNominees: const [
        Nominee(
          name: 'Jane Doe Updated',
          relationship: NomineeRelationship.wife,
          percentage: 100.0,
        ),
      ],
    );

    final updatedCustomer = (updateCustomerResult as Success<Customer, String>).value;
    final updateResult = await repository.updateCustomer(updatedCustomer);
    expect(updateResult, isA<Success<void, String>>());

    // Verify savings_accounts after update
    final saUpdated = await client.from('savings_accounts').select();
    expect(saUpdated.length, greaterThanOrEqualTo(1));

    // Verify nominees after update
    final nomUpdated = await client.from('nominees').select();
    expect(nomUpdated.length, greaterThanOrEqualTo(1));

    // Verify account_identities query return shape
    final rawSbAccountsData = await client
        .from('account_identities')
        .select('customer_id, savings_accounts(account_number), nominees(name, relationship, custom_relationship, percentage)')
        .eq('account_type', 'SB');
    expect(rawSbAccountsData, isNotEmpty);

    // Test watchCustomers (lightweight base table stream for list view)
    final watchedCustomersResult = await repository.watchCustomers().first;
    expect(watchedCustomersResult, isA<Success<List<Customer>, String>>());
    final watchedList = (watchedCustomersResult as Success<List<Customer>, String>).value;
    final watchedCust = watchedList.firstWhere((c) => c.id == customerId);
    expect(watchedCust.name, 'Test Customer Updated');
    expect(watchedCust.phone, '9876543210');

    // Test watchCustomerById
    final watchedByIdResult = await repository.watchCustomerById(customerId).first;
    expect(watchedByIdResult, isA<Success<Customer, String>>());
    final watchedByIdCust = (watchedByIdResult as Success<Customer, String>).value;
    expect(watchedByIdCust.savingsAccount, isNotNull);
    expect(watchedByIdCust.savingsAccount?.accountNumber, 'SB999999999');

    // Deleting a customer who has an embedded SB account (and zero OTD/RD deposits) must succeed.
    final deleteSbOnlyCustomer = await repository.deleteCustomer(customerId);
    expect(deleteSbOnlyCustomer, isA<Success<void, String>>());

    // Deleting a customer who owns an OTD/RD deposit must fail cleanly via ON DELETE NO ACTION (23503).
    final custWithDepositId = const Uuid().v7();
    final custWithDeposit = (Customer.create(
      id: custWithDepositId,
      name: 'Protected Customer',
      phone: '9876500000',
    ) as Success<Customer, String>).value;
    expect(await repository.createCustomer(custWithDeposit), isA<Success<void, String>>());
    await client.rpc('save_one_time_deposit', params: {
      'p_id': const Uuid().v7(),
      'p_customer_id': custWithDepositId,
      'p_status': 'active',
      'p_scheme_type': 'timeDeposit',
      'p_account_no': 'TD-PROTECT-1',
      'p_principal_amount': 10000,
      'p_interest_rate': 7.5,
      'p_term_years': 5,
      'p_term_months': 0,
      'p_start_date': '2026-01-01',
      'p_nominees': const <Map<String, dynamic>>[],
    });

    final blockedDelete = await repository.deleteCustomer(custWithDepositId);
    expect(blockedDelete, isA<Failure<void, String>>());
  });
}

