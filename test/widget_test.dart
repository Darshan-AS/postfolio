import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';

void main() {
  testWidgets('CustomerFormScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CustomerFormScreen())),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
