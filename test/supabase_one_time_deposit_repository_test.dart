import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/features/one_time_deposits/data/supabase_one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('Test SupabaseOneTimeDepositRepository create, update amount, and watch', () async {
    final client = SupabaseClient(
      'http://127.0.0.1:54321',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    final authRes = await client.auth.signUp(
      email: 'testagent_otd_${DateTime.now().millisecondsSinceEpoch}@example.com',
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
      'name': 'Test Agent OTD',
      'email': user.email,
    });

    final customerRepo = SupabaseCustomerRepository(client);
    final customerId = const Uuid().v4();
    final customerRes = Customer.create(
      id: customerId,
      name: 'OTD Customer Test',
      phone: '9876543210',
    );
    final customer = (customerRes as Success<Customer, String>).value;
    await customerRepo.createCustomer(customer);

    final otdRepo = SupabaseOneTimeDepositRepository(client);
    final otdId = const Uuid().v4();

    final otdCreateRes = OneTimeDeposit.create(
      id: otdId,
      accountNo: 'TD1001',
      principalAmount: 50000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.5,
      customerId: customerId,
      schemeType: OneTimeSchemeType.timeDeposit,
      startDate: DateTime(2025, 1, 1),
      nominees: const [
        Nominee(
          name: 'OTD Nominee',
          relationship: NomineeRelationship.wife,
          percentage: 100.0,
        ),
      ],
    );

    expect(otdCreateRes, isA<Success<OneTimeDeposit, String>>());
    final otd = (otdCreateRes as Success<OneTimeDeposit, String>).value;

    final createResult = await otdRepo.createOneTimeDeposit(otd);
    expect(createResult, isA<Success<void, String>>());

    // Verify initial OTD in DB
    final initialDbData = await client.from('one_time_deposits').select().eq('id', otdId).single();
    expect((initialDbData['principal_amount'] as num).toDouble(), 50000.0);

    // Update OTD with new principal amount 100000.0
    final otdUpdateRes = OneTimeDeposit.create(
      id: otdId,
      accountNo: 'TD1001',
      principalAmount: 100000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 7.5,
      customerId: customerId,
      schemeType: OneTimeSchemeType.timeDeposit,
      startDate: DateTime(2025, 1, 1),
      nominees: const [
        Nominee(
          name: 'OTD Nominee',
          relationship: NomineeRelationship.wife,
          percentage: 100.0,
        ),
      ],
    );
    final updatedOtd = (otdUpdateRes as Success<OneTimeDeposit, String>).value;

    final updateResult = await otdRepo.updateOneTimeDeposit(updatedOtd);
    expect(updateResult, isA<Success<void, String>>());

    // Verify updated OTD in DB directly
    final updatedDbData = await client.from('one_time_deposits').select().eq('id', otdId).single();
    expect((updatedDbData['principal_amount'] as num).toDouble(), 100000.0);

    // Watch OTDs
    final watchResult = await otdRepo.watchOneTimeDeposits().first;
    expect(watchResult, isA<Success<List<OneTimeDeposit>, String>>());
    final watchedList = (watchResult as Success<List<OneTimeDeposit>, String>).value;
    final watchedOtd = watchedList.firstWhere((o) => o.id == otdId);
    expect(watchedOtd.principalAmount, 100000.0);
    expect(watchedOtd.nominees.length, 1);
    expect(watchedOtd.nominees.first.name, 'OTD Nominee');
  });
}
