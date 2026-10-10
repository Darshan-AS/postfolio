import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_form_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_form_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  testWidgets('CustomerFormScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CustomerFormScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('CustomerCard renders customer without savings account', (
    WidgetTester tester,
  ) async {
    const customer = Customer(
      id: 'cust-1',
      name: 'Test Customer',
      phone: '9876543210',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomerCard(customer: customer),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
  });

  testWidgets('AsyncSingleEntityBuilder renders data state correctly', (
    WidgetTester tester,
  ) async {
    const customer = Customer(
      id: 'cust-1',
      name: 'Test Customer',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AsyncSingleEntityBuilder<Customer>(
          state: const AsyncData(customer),
          notFoundMessage: 'Not found',
          onRetry: () {},
          builder: (c) => Text('Hello ${c.name}'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello Test Customer'), findsOneWidget);
  });

  testWidgets('OneTimeDepositFormScreen renders when depositId is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OneTimeDepositFormScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('RecurringDepositFormScreen renders when depositId is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RecurringDepositFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets(
    'OneTimeDepositCard renders customerName directly without stream watcher',
    (WidgetTester tester) async {
      final deposit = OneTimeDeposit(
        id: 'otd-1',
        accountNo: 'TD123456',
        principalAmount: 50000,
        termYears: 5,
        termMonths: 0,
        interestRate: 7.5,
        customerId: 'cust-1',
        customerName: 'Shivanand A B',
        schemeType: OneTimeSchemeType.timeDeposit,
        startDate: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OneTimeDepositCard(deposit: deposit)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shivanand A B'), findsOneWidget);
      expect(find.text('TD123456'), findsOneWidget);
      expect(find.text('TD'), findsOneWidget);
      expect(find.text('5Y'), findsOneWidget);
    },
  );

  testWidgets(
    'RecurringDepositCard renders customerName and avatarLabel directly without stream watcher',
    (WidgetTester tester) async {
      final deposit = RecurringDeposit(
        id: 'rd-1',
        serialNo: '14',
        accountNo: 'RD987654',
        installmentAmount: 2000,
        termYears: 5,
        termMonths: 0,
        interestRate: 6.7,
        customerId: 'cust-1',
        customerName: 'Shivanand A B',
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: RecurringDepositCard(deposit: deposit)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shivanand A B'), findsOneWidget);
      expect(find.text('RD987654'), findsOneWidget);
      expect(find.text('#14'), findsOneWidget);
    },
  );

  testWidgets(
    'OneTimeDepositDetailScreen renders with oneTimeDepositByIdProvider',
    (WidgetTester tester) async {
      final deposit = OneTimeDeposit(
        id: 'otd-1',
        accountNo: 'TD123456',
        principalAmount: 50000,
        termYears: 5,
        termMonths: 0,
        interestRate: 7.5,
        customerId: 'cust-1',
        customerName: 'Shivanand A B',
        schemeType: OneTimeSchemeType.timeDeposit,
        startDate: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            oneTimeDepositByIdProvider('otd-1').overrideWith(
              (ref) => Stream.value(deposit),
            ),
          ],
          child: const MaterialApp(
            home: OneTimeDepositDetailScreen(depositId: 'otd-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TD123456'), findsOneWidget);
      expect(find.text('TD'), findsOneWidget);
      expect(find.text('5Y'), findsOneWidget);
      expect(find.text('Time Deposit'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Shivanand A B'), 200);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Shivanand A B'), findsOneWidget);
    },
  );

  testWidgets(
    'RecurringDepositDetailScreen renders with recurringDepositByIdProvider',
    (WidgetTester tester) async {
      final deposit = RecurringDeposit(
        id: 'rd-1',
        serialNo: '14',
        accountNo: 'RD987654',
        installmentAmount: 2000,
        termYears: 5,
        termMonths: 0,
        interestRate: 6.7,
        customerId: 'cust-1',
        customerName: 'Shivanand A B',
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringDepositByIdProvider('rd-1').overrideWith(
              (ref) => Stream.value(deposit),
            ),
          ],
          child: const MaterialApp(
            home: RecurringDepositDetailScreen(depositId: 'rd-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RD987654'), findsOneWidget);
      expect(find.text('#14'), findsOneWidget);
      expect(find.text('Recurring Deposit'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Shivanand A B'), 200);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Shivanand A B'), findsOneWidget);
    },
  );
}
