import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/recurring_deposits/data/supabase_recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('Test SupabaseRecurringDepositRepository create, update amount, and watch', () async {
    final client = SupabaseClient(
      'http://127.0.0.1:54321',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    final authRes = await client.auth.signUp(
      email: 'testagent_rd_${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'password123',
    );

    final user = authRes.user ?? client.auth.currentUser;
    expect(user, isNotNull);

    // Register cleanup hook to delete test agent profile and cascaded records
    addTearDown(() async {
      await client.from('agent_profiles').delete().eq('id', user!.id);
    });

    await client.from('agent_profiles').upsert({
      'id': user!.id,
      'name': 'Test Agent RD',
      'email': user.email,
    });

    final customerRepo = SupabaseCustomerRepository(client);
    final customerId = const Uuid().v4();
    final customerRes = Customer.create(
      id: customerId,
      name: 'RD Customer Test',
      phone: '9876543210',
    );
    final customer = (customerRes as Success<Customer, String>).value;
    await customerRepo.createCustomer(customer);

    final rdRepo = SupabaseRecurringDepositRepository(client);
    final rdId = const Uuid().v4();

    final rdCreateRes = RecurringDeposit.create(
      id: rdId,
      accountNo: 'RD1001',
      installmentAmount: 1000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: customerId,
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 1, 1),
      nominees: const [
        Nominee(
          name: 'RD Nominee',
          relationship: NomineeRelationship.son,
          percentage: 100.0,
        ),
      ],
    );

    expect(rdCreateRes, isA<Success<RecurringDeposit, String>>());
    final rd = (rdCreateRes as Success<RecurringDeposit, String>).value;

    final createResult = await rdRepo.createRecurringDeposit(rd);
    expect(createResult, isA<Success<void, String>>());

    // Verify initial RD in DB
    final initialDbData = await client.from('recurring_deposits').select().eq('id', rdId).single();
    expect((initialDbData['installment_amount'] as num).toDouble(), 1000.0);

    // Update RD with new installment amount 2000.0
    final rdUpdateRes = RecurringDeposit.create(
      id: rdId,
      accountNo: 'RD1001',
      installmentAmount: 2000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: customerId,
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2025, 1, 1),
      nominees: const [
        Nominee(
          name: 'RD Nominee',
          relationship: NomineeRelationship.son,
          percentage: 100.0,
        ),
      ],
    );
    final updatedRd = (rdUpdateRes as Success<RecurringDeposit, String>).value;

    final updateResult = await rdRepo.updateRecurringDeposit(updatedRd);
    expect(updateResult, isA<Success<void, String>>());

    // Verify updated RD in DB directly
    final updatedDbData = await client.from('recurring_deposits').select().eq('id', rdId).single();
    expect((updatedDbData['installment_amount'] as num).toDouble(), 2000.0);

    // Watch RDs
    final watchResult = await rdRepo.watchRecurringDeposits().first;
    expect(watchResult, isA<Success<List<RecurringDeposit>, String>>());
    final watchedList = (watchResult as Success<List<RecurringDeposit>, String>).value;
    final watchedRd = watchedList.firstWhere((r) => r.id == rdId);
    expect(watchedRd.installmentAmount, 2000.0);
  });
}
