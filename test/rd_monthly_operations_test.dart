import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';

void main() {
  group('RDMonthlyOperationItem domain getters', () {
    final deposit = RecurringDeposit(
      id: 'rd-1',
      installmentAmount: 1000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: 'cust-1',
      customerName: 'Aarav Sharma',
      accountNo: '1234567890',
      serialNo: '001',
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2026, 1, 1),
    );

    test('correctly identifies customer pending and overdue status', () {
      final now = DateTime(2026, 9, 20);
      final installment = RDInstallment(
        id: 'inst-1',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isCustomerPending, isTrue);
      expect(item.isReadyForPo, isFalse);
      expect(item.isSettled, isFalse);
      expect(item.isOverdue(now), isTrue);
      expect(item.totalPayable(now), 1010.0); // 1% late fee dynamic
    });

    test('correctly identifies ready for PO when customer paid but PO pending', () {
      final now = DateTime(2026, 9, 20);
      final installment = RDInstallment(
        id: 'inst-2',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.unpaid,
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isCustomerPending, isFalse);
      expect(item.isReadyForPo, isTrue);
      expect(item.isSettled, isFalse);
      expect(item.totalPayable(now), 0.0);
    });

    test('correctly identifies settled state when both customer and PO paid', () {
      final now = DateTime(2026, 9, 20);
      final installment = RDInstallment(
        id: 'inst-3',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 9, 18),
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isCustomerPending, isFalse);
      expect(item.isReadyForPo, isFalse);
      expect(item.isSettled, isTrue);
      expect(item.isOverdue(now), isFalse);
    });

    test('correctly identifies fee pending state when principal is paid and PO is paid but late fee is unpaid', () {
      final installment = RDInstallment(
        id: 'inst-4',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 8, 1),
        dueDate: DateTime(2026, 8, 15),
        installmentAmount: 10000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 10000.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 8, 20),
        lateFee: 100.0,
        paidLateFee: 0.0,
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isFeePending, isTrue);
      expect(item.isSettled, isFalse);
      expect(item.isReadyForPo, isFalse);
      expect(item.isCustomerPending, isTrue);
    });

    test('correctly identifies settled state when principal, PO, and late fees are all paid or waived', () {
      final installment = RDInstallment(
        id: 'inst-settled',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 8, 1),
        dueDate: DateTime(2026, 8, 15),
        installmentAmount: 10000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 10000.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 8, 20),
        lateFee: 100.0,
        paidLateFee: 100.0,
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isFeePending, isFalse);
      expect(item.isSettled, isTrue);
      expect(item.isReadyForPo, isFalse);
      expect(item.isCustomerPending, isFalse);
    });

    test('all operational states are mutually exclusive and partition items', () {
      final items = [
        // 1. Pending customer payment
        RDMonthlyOperationItem(
          deposit: deposit,
          installment: RDInstallment(
            id: '1',
            rdId: deposit.id,
            installmentDate: DateTime(2026, 8, 1),
            dueDate: DateTime(2026, 8, 15),
            installmentAmount: 5000.0,
            customerStatus: RDInstallmentStatus.unpaid,
          ),
        ),
        // 2. Ready for PO
        RDMonthlyOperationItem(
          deposit: deposit,
          installment: RDInstallment(
            id: '2',
            rdId: deposit.id,
            installmentDate: DateTime(2026, 8, 1),
            dueDate: DateTime(2026, 8, 15),
            installmentAmount: 5000.0,
            customerStatus: RDInstallmentStatus.fullyPaid,
            customerPaidAmount: 5000.0,
            poStatus: RDPoStatus.unpaid,
          ),
        ),
        // 3. Fee pending (principal paid, PO paid, late fee unpaid)
        RDMonthlyOperationItem(
          deposit: deposit,
          installment: RDInstallment(
            id: '3',
            rdId: deposit.id,
            installmentDate: DateTime(2026, 8, 1),
            dueDate: DateTime(2026, 8, 15),
            installmentAmount: 10000.0,
            customerStatus: RDInstallmentStatus.fullyPaid,
            customerPaidAmount: 10000.0,
            poStatus: RDPoStatus.paid,
            poPaidDate: DateTime(2026, 8, 20),
            lateFee: 100.0,
            paidLateFee: 0.0,
          ),
        ),
        // 4. Settled
        RDMonthlyOperationItem(
          deposit: deposit,
          installment: RDInstallment(
            id: '4',
            rdId: deposit.id,
            installmentDate: DateTime(2026, 8, 1),
            dueDate: DateTime(2026, 8, 15),
            installmentAmount: 10000.0,
            customerStatus: RDInstallmentStatus.fullyPaid,
            customerPaidAmount: 10000.0,
            poStatus: RDPoStatus.paid,
            poPaidDate: DateTime(2026, 8, 20),
            lateFee: 0.0,
            paidLateFee: 0.0,
          ),
        ),
        // 5. PO Advanced (pocket advance)
        RDMonthlyOperationItem(
          deposit: deposit,
          installment: RDInstallment(
            id: '5',
            rdId: deposit.id,
            installmentDate: DateTime(2026, 8, 1),
            dueDate: DateTime(2026, 8, 15),
            installmentAmount: 3000.0,
            customerStatus: RDInstallmentStatus.unpaid,
            poStatus: RDPoStatus.paid,
            poPaidDate: DateTime(2026, 8, 10),
          ),
        ),
      ];

      final toCollect = items.where((i) => i.isCustomerPending).toList();
      final readyForPo = items.where((i) => i.isReadyForPo).toList();
      final settled = items.where((i) => i.isSettled).toList();

      // toCollect includes: 1 (unpaid), 3 (fee pending), 5 (PO advanced)
      expect(toCollect.length, 3);
      // readyForPo includes: 2
      expect(readyForPo.length, 1);
      // settled includes: 4
      expect(settled.length, 1);
      // Symmetrical partition: sum equals total items
      expect(toCollect.length + readyForPo.length + settled.length, items.length);
    });

    test('calculates totalOutstandingPayable and hasOverdueDebt with prior arrears', () {
      final now = DateTime(2026, 9, 5); // Current installment not yet overdue (due Sep 15)
      final installment = RDInstallment(
        id: 'inst-sep',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
      );

      final itemWithArrears = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
        priorOverdueCount: 1,
        priorOverdueAmount: 1010.0,
      );

      expect(itemWithArrears.totalPayable(now), 1000.0);
      expect(itemWithArrears.totalOutstandingPayable(now), 2010.0);
      expect(itemWithArrears.isOverdue(now), isFalse);
      expect(itemWithArrears.hasOverdueDebt(now), isTrue);
    });

    test('calculates totalDefaultFee across prior overdue installments and current dynamic late fee', () {
      final now = DateTime(2026, 9, 20); // 5 days overdue for current
      final currentInstallment = RDInstallment(
        id: 'inst-curr',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
      );

      final itemWithFee = RDMonthlyOperationItem(
        deposit: deposit,
        installment: currentInstallment,
        priorOverdueCount: 2,
        priorOverdueAmount: 2020.0,
        priorOverdueFee: 20.0,
      );

      expect(itemWithFee.totalDefaultFee(now), 30.0); // 20.0 prior + 10.0 current (1%)
      expect(itemWithFee.totalOutstandingPayable(now), 3030.0);
    });

    test('correctly identifies upcoming future months and suppresses overdue debt', () {
      final now = DateTime(2026, 9, 20); // Current month: September 2026

      // October 2026 installment (future month)
      final futureInstallment = RDInstallment(
        id: 'inst-oct',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
      );

      final futureItem = RDMonthlyOperationItem(
        deposit: deposit,
        installment: futureInstallment,
        priorOverdueCount: 0,
        priorOverdueAmount: 0.0,
      );

      expect(futureItem.isUpcoming(now), isTrue);
      expect(futureItem.hasOverdueDebt(now), isFalse);
      expect(futureItem.isCustomerPending, isTrue);

      // September 2026 installment (current month)
      final currentInstallment = RDInstallment(
        id: 'inst-sep',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
      );

      final currentItem = RDMonthlyOperationItem(
        deposit: deposit,
        installment: currentInstallment,
      );

      expect(currentItem.isUpcoming(now), isFalse);
      expect(currentItem.isOverdue(now), isTrue);
      expect(currentItem.hasOverdueDebt(now), isTrue);
    });

    test('correctly identifies PO Advanced state when customer unpaid but PO paid', () {
      final installment = RDInstallment(
        id: 'inst-adv',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 9, 10),
      );

      final item = RDMonthlyOperationItem(
        deposit: deposit,
        installment: installment,
      );

      expect(item.isPoAdvanced, isTrue);
      expect(item.isCustomerPending, isTrue);
      expect(item.isReadyForPo, isFalse);
      expect(item.isSettled, isFalse);
      expect(item.canDepositToPo, isFalse);
      expect(item.canRevertPo, isTrue);
      expect(item.isPoPaid, isTrue);
    });

    test('canDepositToPo and canRevertPo reflect PO payment status across workflows', () {
      // Pending customer payment (can deposit to PO directly / advance)
      final pendingInst = RDInstallment(
        id: 'inst-p',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
      );
      final pendingItem = RDMonthlyOperationItem(deposit: deposit, installment: pendingInst);
      expect(pendingItem.canDepositToPo, isTrue);
      expect(pendingItem.canRevertPo, isFalse);

      // Ready for PO
      final readyInst = RDInstallment(
        id: 'inst-r',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.unpaid,
      );
      final readyItem = RDMonthlyOperationItem(deposit: deposit, installment: readyInst);
      expect(readyItem.canDepositToPo, isTrue);
      expect(readyItem.canRevertPo, isFalse);

      // Settled
      final settledInst = RDInstallment(
        id: 'inst-s',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.paid,
      );
      final settledItem = RDMonthlyOperationItem(deposit: deposit, installment: settledInst);
      expect(settledItem.canDepositToPo, isFalse);
      expect(settledItem.canRevertPo, isTrue);
    });

    test('computes 1-based installmentNumber from deposit start date', () {
      // Start date: 2026-01-01. Installment date: 2026-09-01 -> month 9
      final installment = RDInstallment(
        id: 'inst-sep',
        rdId: deposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
      );
      final item = RDMonthlyOperationItem(deposit: deposit, installment: installment);
      expect(item.installmentNumber, 9);
    });
  });

  group('FakeRecurringDepositRepository watchInstallmentsForMonth', () {
    test('emits installments matching the target month', () async {
      final repo = FakeRecurringDepositRepository();
      addTearDown(repo.dispose);

      final targetMonth = DateTime(2026, 1, 1);
      final stream = repo.watchInstallmentsForMonth(targetMonth);

      final firstSnapshot = await stream.first;
      expect(firstSnapshot, isA<Success<List<RDInstallment>, String>>());

      final installments = (firstSnapshot as Success<List<RDInstallment>, String>).value;
      for (final inst in installments) {
        expect(inst.installmentDate.year, 2026);
        expect(inst.installmentDate.month, 1);
      }
    });

    test('getUnpaidInstallmentsBefore returns only unpaid prior installments', () async {
      final repo = FakeRecurringDepositRepository();
      addTearDown(repo.dispose);

      final cutoff = DateTime(2026, 9, 1);
      final result = await repo.getUnpaidInstallmentsBefore(cutoff);

      expect(result, isA<Success<List<RDInstallment>, String>>());
      final unpaid = (result as Success<List<RDInstallment>, String>).value;

      for (final inst in unpaid) {
        expect(inst.installmentDate.isBefore(cutoff), isTrue);
        expect(inst.isInstallmentPaid, isFalse);
      }
    });

    test('getRDInstallments returns schedule directly without stream lifecycle issues', () async {
      final fakeRepo = FakeRecurringDepositRepository();
      addTearDown(fakeRepo.dispose);

      final depositsResult = await fakeRepo.watchRecurringDeposits().first;
      final deposits = (depositsResult as Success<List<RecurringDeposit>, String>).value;
      expect(deposits, isNotEmpty);

      final deposit = deposits.first;
      final scheduleResult = await fakeRepo.getRDInstallments(deposit.id);
      expect(scheduleResult, isA<Success<List<RDInstallment>, String>>());

      final schedule = (scheduleResult as Success<List<RDInstallment>, String>).value;
      expect(schedule, isNotEmpty);
      expect(schedule.length, 60);
    });
  });

  group('RDLogPaymentSheet with prefilled initialAmount', () {
    testWidgets('renders properly with prefilled initialAmount without exception', (tester) async {
      await initializeDateFormatting('en', null);

      final fakeRepo = FakeRecurringDepositRepository();
      addTearDown(fakeRepo.dispose);

        final depositsResult = await fakeRepo.watchRecurringDeposits().first;
        final deposit = (depositsResult as Success<List<RecurringDeposit>, String>).value.first;
        final scheduleResult = await fakeRepo.getRDInstallments(deposit.id);
        final schedule = (scheduleResult as Success<List<RDInstallment>, String>).value;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recurringDepositRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: RDLogPaymentSheet(
                  deposit: deposit,
                  currentSchedule: schedule,
                  initialAmount: 2010.0,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(RDLogPaymentSheet), findsOneWidget);
        expect(find.text('2010'), findsOneWidget);
    });
  });

  group('RDMonthlyOperationCard Option 1 Layout', () {
    final testDeposit = RecurringDeposit(
      id: 'rd-card-test',
      installmentAmount: 1000.0,
      termYears: 5,
      termMonths: 0,
      interestRate: 6.7,
      customerId: 'cust-1',
      customerName: 'Aarav Sharma',
      accountNo: '1234567890',
      serialNo: '001',
      schemeType: RecurringSchemeType.recurringDeposit,
      startDate: DateTime(2026, 1, 1),
    );

    testWidgets('renders monthly amount /mo, divergent total due, and fee badge when overdue', (tester) async {
      await initializeDateFormatting('en', null);

      final currentInstallment = RDInstallment(
        id: 'inst-curr',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
      );

      final item = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: currentInstallment,
        priorOverdueCount: 1,
        priorOverdueAmount: 1020.0,
        priorOverdueFee: 20.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: item,
              isSelected: false,
              isSelectionMode: false,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Monthly amount and /mo suffix
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('/mo'), findsOneWidget);

      // Divergent Total Due
      expect(find.textContaining('Total Due:'), findsOneWidget);

      // Fee badge
      expect(find.textContaining('Fee:'), findsOneWidget);
    });

    testWidgets('renders monthly amount /mo without divergent total due for normal pending month', (tester) async {
      await initializeDateFormatting('en', null);

      final normalInstallment = RDInstallment(
        id: 'inst-normal',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 25), // Not overdue
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
      );

      final normalItem = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: normalInstallment,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: normalItem,
              isSelected: false,
              isSelectionMode: false,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Monthly amount and /mo suffix
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('/mo'), findsOneWidget);

      // No divergent Total Due row since total pending equals monthly installment
      expect(find.textContaining('Total Due:'), findsNothing);
      expect(find.textContaining('Fee:'), findsNothing);
    });

    testWidgets('renders avatar #N and NO Checkbox in browse mode even for ready for PO items', (tester) async {
      await initializeDateFormatting('en', null);

      final readyInstallment = RDInstallment(
        id: 'inst-ready',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.unpaid,
      );

      final readyItem = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: readyInstallment,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: readyItem,
              isSelected: false,
              isSelectionMode: false,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no Checkbox is present in browse mode
      expect(find.byType(Checkbox), findsNothing);
      // Ensure the avatar showing installment #9 is present
      expect(find.text('#9'), findsOneWidget);
    });

    testWidgets('renders Checkbox when isSelectionMode is true', (tester) async {
      await initializeDateFormatting('en', null);

      final readyInstallment = RDInstallment(
        id: 'inst-ready',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.unpaid,
      );

      final readyItem = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: readyInstallment,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: readyItem,
              isSelected: true,
              isSelectionMode: true,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Checkbox is now visible
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders PO Advanced badge when isPoAdvanced is true', (tester) async {
      await initializeDateFormatting('en', null);

      final advInstallment = RDInstallment(
        id: 'inst-adv',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.unpaid,
        customerPaidAmount: 0.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 9, 10),
      );

      final advItem = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: advInstallment,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: advItem,
              isSelected: false,
              isSelectionMode: false,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Advanced to PO'), findsOneWidget);
    });

    testWidgets('renders Fee badge, Fee Due text, and Collect Fee button when isFeePending is true', (tester) async {
      await initializeDateFormatting('en', null);

      final feePendingInstallment = RDInstallment(
        id: 'inst-fee',
        rdId: testDeposit.id,
        installmentDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        installmentAmount: 1000.0,
        customerStatus: RDInstallmentStatus.fullyPaid,
        customerPaidAmount: 1000.0,
        poStatus: RDPoStatus.paid,
        poPaidDate: DateTime(2026, 9, 18),
        lateFee: 20.0,
        paidLateFee: 0.0,
      );

      final feeItem = RDMonthlyOperationItem(
        deposit: testDeposit,
        installment: feePendingInstallment,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RDMonthlyOperationCard(
              item: feeItem,
              isSelected: false,
              isSelectionMode: false,
              onTap: () {},
              onLogPayment: () {},
              onDepositToPo: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fee: ₹20 badge in subtitle
      expect(find.textContaining('Fee: ₹20'), findsOneWidget);
      // Fee Due: ₹20 in trailing
      expect(find.textContaining('Fee Due: ₹20'), findsOneWidget);
      // Collect Fee button
      expect(find.textContaining('Collect Fee'), findsOneWidget);
      // Not marked as [ ✓ Settled ]
      expect(find.text('Settled'), findsNothing);
    });
  });

  group('RDMonthlyOperationsController selection state', () {
    test('toggleSelectionMode toggles and resets selections when turned off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(rDMonthlyOperationsControllerProvider.notifier);
      expect(container.read(rDMonthlyOperationsControllerProvider).isSelectionMode, isFalse);

      notifier.toggleSelectionMode(true);
      expect(container.read(rDMonthlyOperationsControllerProvider).isSelectionMode, isTrue);

      notifier.toggleSelection('inst-1');
      expect(container.read(rDMonthlyOperationsControllerProvider).selectedInstallmentIds, {'inst-1'});

      // Turning selection mode off clears selected IDs
      notifier.toggleSelectionMode(false);
      expect(container.read(rDMonthlyOperationsControllerProvider).isSelectionMode, isFalse);
      expect(container.read(rDMonthlyOperationsControllerProvider).selectedInstallmentIds, isEmpty);
    });

    test('toggleSelection toggles item and engages selection mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(rDMonthlyOperationsControllerProvider.notifier);

      notifier.toggleSelection('inst-1');
      expect(container.read(rDMonthlyOperationsControllerProvider).isSelectionMode, isTrue);
      expect(container.read(rDMonthlyOperationsControllerProvider).selectedInstallmentIds, {'inst-1'});

      notifier.toggleSelection('inst-1');
      expect(container.read(rDMonthlyOperationsControllerProvider).isSelectionMode, isFalse);
      expect(container.read(rDMonthlyOperationsControllerProvider).selectedInstallmentIds, isEmpty);
    });
  });
}
