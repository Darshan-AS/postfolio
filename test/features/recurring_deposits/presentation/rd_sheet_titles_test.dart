import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_account_identity.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_sheet_parts.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// A ledger sheet names the customer in its title and the account on a line under it. The
/// title used to end in a bare serial, which wrapped onto a line of its own.
void main() {
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
  const identity = 'Sl 12 · A/c …6655';

  test('the identity line is the serial and the end of the account number', () {
    expect(rdAccountIdentity(rd), identity);
    expect(rdAccountIdentity(rd.copyWith(serialNo: null)), 'A/c …6655');
    expect(rdAccountIdentity(rd.copyWith(serialNo: '')), 'A/c …6655');
    expect(
      rdAccountIdentity(rd.copyWith(accountNo: '123')),
      'Sl 12 · A/c …123',
    );
  });

  test('the titles name the customer and do not end in a serial', () {
    final ledger = t.recurringDeposits.ledger;
    expect(
      ledger.collectTitle(customer: 'Anita Sharma'),
      'Collect from Anita Sharma',
    );
    expect(
      ledger.depositTitleFor(n: '2', customer: 'Anita Sharma'),
      'Deposit 2 · Anita Sharma',
    );
  });

  testWidgets(
    'the header draws the account under the title, on the same edge',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RDSheetHeader(
              title: 'Collect from Anita Sharma',
              subtitle: identity,
              onClose: () {},
            ),
          ),
        ),
      );
      final title = tester.getRect(find.text('Collect from Anita Sharma'));
      final line = tester.getRect(find.text(identity));
      expect(line.top, greaterThanOrEqualTo(title.bottom));
      expect(line.left, title.left);
      expect(
        line.right,
        lessThanOrEqualTo(tester.getRect(find.byTooltip(t.common.close)).left),
      );
    },
  );

  Future<void> openSheet(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    tester.view.physicalSize = const Size(360, 800) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 3, 10)),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(
            customers: const [Customer(id: 'cust-1', name: 'Anita Sharma')],
          ),
        ),
        recurringDepositRepositoryProvider.overrideWithValue(
          FakeRecurringDepositRepository(deposits: [rd]),
        ),
        rdLedgerRepositoryProvider.overrideWithValue(FakeRDLedgerRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => open(context),
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
  }

  testWidgets(
    'the collect sheet: "Collect from Anita Sharma", then the account',
    (tester) async {
      await openSheet(
        tester,
        (context) => showRDLogPaymentSheet(context, rdId: rd.id),
      );

      final header = find.byType(RDSheetHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.text('Collect from Anita Sharma'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text(identity)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the deposit sheet: "Deposit 1 · Anita Sharma", then the account',
    (tester) async {
      await openSheet(
        tester,
        (context) => showRDDepositSheet(context, rdId: rd.id, initialCount: 1),
      );

      final header = find.byType(RDSheetHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.text('Deposit 1 · Anita Sharma'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text(identity)),
        findsOneWidget,
      );
    },
  );
}
