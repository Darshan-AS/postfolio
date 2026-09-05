import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_service.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('RD Ledger Update Schedule Tests', () {
    late FakeRecurringDepositRepository repository;
    final rdId = const Uuid().v4();
    final customerId = const Uuid().v4();

    setUp(() {
      repository = FakeRecurringDepositRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Updating start date regenerates and replaces installment schedule when no payments exist', () async {
      final initialStartDate = DateTime(2026, 1, 1);
      final initialSchedule = RDLedgerService.generateInitialSchedule(
        rdId: rdId,
        startDate: initialStartDate,
        installmentAmount: 1000.0,
        termYears: 1,
        termMonths: 0,
        initialPaidInstallments: 0,
      );

      final rd = RecurringDeposit(
        id: rdId,
        customerId: customerId,
        schemeType: RecurringSchemeType.recurringDeposit,
        status: DepositStatus.active,
        installmentAmount: 1000.0,
        interestRate: 6.7,
        termYears: 1,
        termMonths: 0,
        startDate: initialStartDate,
        nominees: const [],
        initialPaidInstallments: 0,
      );

      final createRes = await repository.saveRecurringDeposit(
        rd,
        schedule: initialSchedule,
      );
      expect(createRes, isA<Success<void, String>>());

      // Verify initial installments start in Jan 2026
      final initialInstsRes = await repository.watchRDInstallments(rdId).first;
      final initialInsts = (initialInstsRes as Success<List<RDInstallment>, String>).value;
      expect(initialInsts.length, 12);
      expect(initialInsts.first.installmentDate.month, 1);
      expect(initialInsts.first.installmentDate.year, 2026);

      // Now update the deposit to start in April 2026
      final updatedStartDate = DateTime(2026, 4, 1);
      final updatedSchedule = RDLedgerService.generateInitialSchedule(
        rdId: rdId,
        startDate: updatedStartDate,
        installmentAmount: 2000.0,
        termYears: 1,
        termMonths: 0,
        initialPaidInstallments: 0,
      );

      final updatedRd = rd.copyWith(
        startDate: updatedStartDate,
        installmentAmount: 2000.0,
      );

      final updateRes = await repository.saveRecurringDeposit(
        updatedRd,
        schedule: updatedSchedule,
      );
      expect(updateRes, isA<Success<void, String>>());

      // Verify installments reflect April 2026 and new installment amount
      final updatedInstsRes = await repository.watchRDInstallments(rdId).first;
      final updatedInsts = (updatedInstsRes as Success<List<RDInstallment>, String>).value;
      expect(updatedInsts.length, 12);
      expect(updatedInsts.first.installmentDate.month, 4);
      expect(updatedInsts.first.installmentDate.year, 2026);
      expect(updatedInsts.first.installmentAmount, 2000.0);
      expect(updatedInsts.last.installmentDate.month, 3);
      expect(updatedInsts.last.installmentDate.year, 2027);
    });
  });
}

