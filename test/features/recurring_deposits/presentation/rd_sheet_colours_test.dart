import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';

/// Colour roles on the ledger sheets. Red is for what is overdue. Money the agent puts in
/// from their own pocket is "fronted", and fronted has its own colour on the Hub and the
/// passbook; the sheets used the error red for it.
void main() {
  final today = DateTime(2026, 4, 20);
  // Nothing collected: depositing now is paid from the agent's pocket.
  final rd = RecurringDeposit(
    id: 'rd-101',
    customerId: 'cust-1',
    customerName: 'Anita Sharma',
    serialNo: '12',
    accountNo: '9988776655',
    schemeType: RecurringSchemeType.recurringDeposit,
    status: DepositStatus.active,
    installmentAmount: 1000,
    interestRate: 6.7,
    termYears: 5,
    termMonths: 0,
    startDate: DateTime(2026, 1, 5),
  );

  for (final (name, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets(
      '$name: the from-pocket line on the deposit sheet is the fronted colour',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800) * 2;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(() => today),
            customerRepositoryProvider.overrideWithValue(
              FakeCustomerRepository(
                customers: const [Customer(id: 'cust-1', name: 'Anita Sharma')],
              ),
            ),
            recurringDepositRepositoryProvider.overrideWithValue(
              FakeRecurringDepositRepository(deposits: [rd]),
            ),
            rdLedgerRepositoryProvider.overrideWithValue(
              FakeRDLedgerRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => showRDDepositSheet(
                        context,
                        rdId: rd.id,
                        initialCount: 1,
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final sheet = find.byType(BottomSheet);
        expect(sheet, findsOneWidget);
        final context = tester.element(sheet);
        final scheme = Theme.of(context).colorScheme;
        final fronted = AppFinancialColors.of(context).fronted.onContainer;

        final colours = [
          for (final text in tester.widgetList<Text>(
            find.descendant(of: sheet, matching: find.byType(Text)),
          ))
            text.style?.color,
        ];
        expect(colours, contains(fronted));
        expect(colours, isNot(contains(scheme.error)));
      },
    );
  }
}
