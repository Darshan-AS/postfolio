import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';

void main() {
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
}
