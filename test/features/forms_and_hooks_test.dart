import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_po_visit_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_deposit_sheet.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_inspector_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_po_visit_sheet.dart';
import 'package:postfolio/i18n/strings.g.dart';

Finder fieldLabeled(String label) => find.ancestor(
  of: find.textContaining(label),
  matching: find.byType(TextFormField),
);

void main() {
  group('NomineesInputSection & useNomineeFormState', () {
    testWidgets('preserves spacebar while typing, defaults remaining %, keeps sibling controllers on delete, and splits evenly', (tester) async {
      late ValueNotifier<List<Nominee>> captured;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HookBuilder(
                builder: (context) {
                  captured = useState<List<Nominee>>(const []);
                  return NomineesInputSection(
                    nominees: captured.value,
                    onChanged: (next) => captured.value = next,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 1. Add first nominee -> defaults to 100%, spouse/wife/son (not 'other')
      await tester.tap(find.text(t.nominees.addNominee));
      await tester.pumpAndSettle();
      expect(captured.value, hasLength(1));
      expect(captured.value.first.percentage, 100.0);
      expect(captured.value.first.relationship, isNot(NomineeRelationship.other));

      // 2. Simulate typing with spacebar ('Ramesh ' -> 'Ramesh Kumar')
      await tester.enterText(fieldLabeled(t.nominees.name).first, 'Ramesh ');
      await tester.pumpAndSettle();
      final firstNameField = tester.widget<TextFormField>(
        fieldLabeled(t.nominees.name).first,
      );
      expect(firstNameField.controller!.text, 'Ramesh ');

      await tester.enterText(fieldLabeled(t.nominees.name).first, 'Ramesh Kumar');
      await tester.pumpAndSettle();
      expect(captured.value.first.name, 'Ramesh Kumar');

      // 3. Change Nominee 1 percentage to 60 -> Add 2nd nominee -> defaults to remaining 40%
      await tester.enterText(fieldLabeled(t.nominees.percentage).first, '60');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(t.nominees.addNominee));
      await tester.tap(find.text(t.nominees.addNominee));
      await tester.pumpAndSettle();
      expect(captured.value, hasLength(2));
      expect(captured.value[1].percentage, 40.0);
      await tester.enterText(
        fieldLabeled(t.nominees.name).at(1),
        'Sita Devi',
      );
      await tester.pumpAndSettle();

      // 4. Add 3rd nominee, name it 'Arjun', then delete middle ('Sita Devi')
      await tester.ensureVisible(find.text(t.nominees.addNominee));
      await tester.tap(find.text(t.nominees.addNominee));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabeled(t.nominees.name).at(2),
        'Arjun Rao',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('delete_nominee_1')));
      await tester.tap(find.byKey(const ValueKey('delete_nominee_1')));
      await tester.pumpAndSettle();

      expect(captured.value, hasLength(2));
      expect(captured.value[0].name, 'Ramesh Kumar');
      expect(captured.value[1].name, 'Arjun Rao');
      expect(
        tester
            .widget<TextFormField>(fieldLabeled(t.nominees.name).at(1))
            .controller!
            .text,
        'Arjun Rao',
      );

      // 5. Add a 3rd nominee again and tap Split Evenly -> exact 100.00% valid split
      await tester.ensureVisible(find.text(t.nominees.addNominee));
      await tester.tap(find.text(t.nominees.addNominee));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabeled(t.nominees.name).at(2),
        'Meera Rao',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('split_nominees_evenly_chip')),
      );
      await tester.tap(find.byKey(const ValueKey('split_nominees_evenly_chip')));
      await tester.pumpAndSettle();
      expect(Nominee.validateNominees(captured.value), isNull);
    });
  });

  group('CustomerFormScreen validators & sanitization', () {
    testWidgets('validates CIF/Aadhaar/PAN, accepts phone with spaces, and auto-uppercases PAN', (tester) async {
      final repo = FakeCustomerRepository(customers: const []);
      final container = ProviderContainer(
        overrides: [customerRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CustomerFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldLabeled(t.customers.fields.fullName),
        'Kiran Shetty',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.phoneNumber),
        '+91 98765 43210',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.cif),
        '123',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.aadhaarNumber),
        '12345',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.panNumber),
        'badpan',
      );

      // Tap Save -> invalid CIF, Aadhaar, PAN must surface inline errors
      await tester.tap(find.byTooltip(t.common.confirm));
      await tester.pumpAndSettle();

      expect(find.text(t.errors.invalidCif), findsOneWidget);
      expect(find.text(t.errors.invalidAadhaar), findsOneWidget);
      expect(find.text(t.errors.invalidPan), findsOneWidget);
      expect(find.text(t.errors.invalidPhone), findsNothing);

      // Fix CIF, Aadhaar (with spaces), and lowercase PAN -> auto-uppercased and saved
      await tester.enterText(
        fieldLabeled(t.customers.fields.cif),
        '123456789',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.aadhaarNumber),
        '1234 5678 9012',
      );
      await tester.enterText(
        fieldLabeled(t.customers.fields.panNumber),
        'abcde1234f',
      );
      await tester.pump();

      final panField = tester.widget<TextFormField>(
        fieldLabeled(t.customers.fields.panNumber),
      );
      expect(panField.controller!.text, 'ABCDE1234F');
    });
  });

  group('Core Form & Picker Controls', () {
    testWidgets('AppInputDecoration uses Text.rich, AppDropdownField reacts to external value, AppSearchBar syncs external clear, CustomerSelectionField hides raw UUID', (tester) async {
      final customerWithoutCif = const Customer(
        id: 'raw-uuid-9f8e7d6c-1111',
        name: 'Lakshmi Narayan',
        phone: '9876543210',
      );
      final repo = FakeCustomerRepository(customers: [customerWithoutCif]);
      final container = ProviderContainer(
        overrides: [customerRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      late ValueNotifier<String> dropdownVal;
      late ValueNotifier<String> searchQuery;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: HookBuilder(
                builder: (context) {
                  dropdownVal = useState('A');
                  searchQuery = useState('ramesh');
                  final decoration = AppInputDecoration.m3(
                    context,
                    labelText: 'Required Label',
                    isRequired: true,
                  );
                  return Column(
                    children: [
                      InputDecorator(
                        decoration: decoration,
                        child: const Text('Body'),
                      ),
                      AppDropdownField<String>(
                        value: dropdownVal.value,
                        labelText: 'Option',
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('Option A')),
                          DropdownMenuItem(value: 'B', child: Text('Option B')),
                        ],
                        onChanged: (v) => dropdownVal.value = v ?? 'A',
                      ),
                      AppSearchBar(
                        query: searchQuery.value,
                        onChanged: (q) => searchQuery.value = q,
                      ),
                      CustomerSelectionField(
                        initialCustomer: customerWithoutCif,
                        onCustomerSelected: (_) {},
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Required label uses Text (Text.rich), not unscaled RichText
      expect(find.textContaining('Required Label'), findsOneWidget);

      // 2. External dropdown state update reflects in UI
      expect(find.text('Option A'), findsOneWidget);
      dropdownVal.value = 'B';
      await tester.pumpAndSettle();
      expect(find.text('Option B'), findsOneWidget);

      // 3. External search query clear updates SearchBar text
      expect(find.text('ramesh'), findsOneWidget);
      searchQuery.value = '';
      await tester.pumpAndSettle();
      expect(find.text('ramesh'), findsNothing);

      // 4. CustomerSelectionField never prints raw UUID when cifNumber is null
      expect(find.text('Lakshmi Narayan'), findsOneWidget);
      expect(find.textContaining('raw-uuid-9f8e7d6c'), findsNothing);
    });
  });

  group('RD Sheets (Prefill Focus, Counter-Fee Overrides, Inspector UUID) & Detail Actions', () {
    final today = DateTime(2026, 4, 20);
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
      startDate: DateTime(2026, 1, 5), // due Jan 15 -> 3 defaulted months on Apr 20 (fee ₹30)
    );

    ProviderContainer makeContainer(FakeRDLedgerRepository ledgerRepo) {
      return ProviderContainer(
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
          rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
      );
    }

    testWidgets('RDLogPaymentSheet suppresses autofocus when initialAmount is prefilled and autofocuses when blank', (tester) async {
      final ledgerRepo = FakeRDLedgerRepository();
      final container = makeContainer(ledgerRepo);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showRDLogPaymentSheet(
                        context,
                        rdId: rd.id,
                        initialAmount: 1030,
                      ),
                      child: const Text('Open Prefilled'),
                    ),
                    ElevatedButton(
                      onPressed: () => showRDLogPaymentSheet(
                        context,
                        rdId: rd.id,
                      ),
                      child: const Text('Open Blank'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Prefilled: EditableText must NOT have autofocus=true
      await tester.tap(find.text('Open Prefilled'));
      await tester.pumpAndSettle();
      final prefilledEditable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(t.recurringDeposits.ledger.paymentAmount),
          matching: find.byType(EditableText),
        ),
      );
      expect(prefilledEditable.autofocus, isFalse);

      await tester.tap(find.byTooltip(t.common.close));
      await tester.pumpAndSettle();

      // Blank: EditableText MUST have autofocus=true
      await tester.tap(find.text('Open Blank'));
      await tester.pumpAndSettle();
      final blankEditable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(t.recurringDeposits.ledger.paymentAmount),
          matching: find.byType(EditableText),
        ),
      );
      expect(blankEditable.autofocus, isTrue);
    });

    testWidgets('RDDepositSheet & RDPoVisitSheet expose counter-fee override inputs and persist exact feePaid', (tester) async {
      final ledgerRepo = FakeRDLedgerRepository(
        transactions: {
          rd.id: [
            RDTransaction(
              id: 'tx-1',
              rdId: rd.id,
              amount: 1030,
              paidDate: DateTime(2026, 4, 18),
              paymentMode: RDPaymentMode.cash,
            ),
          ],
        },
      );
      final container = makeContainer(ledgerRepo);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showRDDepositSheet(
                        context,
                        rdId: rd.id,
                        initialCount: 1,
                      ),
                      child: const Text('Open Deposit Sheet'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        container.read(rDPoVisitPlannerProvider.notifier).start();
                        showRDPoVisitPlanner(context);
                      },
                      child: const Text('Open Visit Sheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Single-account RDDepositSheet: override statutory ₹30 fee to ₹0 (Sunday/holiday waiver)
      await tester.tap(find.text('Open Deposit Sheet'));
      await tester.pumpAndSettle();

      final feeField = find.byKey(
        const ValueKey('deposit_counter_fee_override_field'),
      );
      expect(feeField, findsOneWidget);
      await tester.enterText(feeField, '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.recurringDeposits.ledger.depositSubmit(n: '1')));
      await tester.pumpAndSettle();

      final singleEventsResult = await ledgerRepo.watchPoDeposits(rd.id).first;
      final singleEvents = (singleEventsResult as Success<List<RDPoDeposit>, String>).value;
      expect(singleEvents, hasLength(1));
      expect(singleEvents.first.feePaid, 0.0);
      expect(singleEvents.first.amount, 1000.0);

      // 2. Multi-account RDPoVisitSheet: collect month #2 via RDLedgerController, warm Hub items, open planner, override fee to ₹15
      await container.read(rDLedgerControllerProvider.notifier).recordPayment((
        rdId: rd.id,
        transactionId: 'tx-2',
        amount: 1020,
        paidDate: DateTime(2026, 4, 19),
        paymentMode: RDPaymentMode.cash,
      ));
      container.listen(monthlyOperationItemsProvider, (_, _) {});
      await container.read(monthlyOperationItemsProvider.future);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Visit Sheet'));
      await tester.pumpAndSettle();

      final visitFeeToggle = find.byKey(ValueKey('visit_fee_override_${rd.id}'));
      expect(visitFeeToggle, findsOneWidget);
      await tester.tap(visitFeeToggle);
      await tester.pumpAndSettle();

      final visitFeeInput = find.byKey(ValueKey('visit_fee_input_${rd.id}'));
      await tester.enterText(visitFeeInput, '15');
      await tester.pumpAndSettle();

      expect(container.read(rDPoVisitPlannerProvider).totalFee, 15.0);
    });

    testWidgets('RDDepositSheet retried after a lost response records one deposit and reports the saved one', (tester) async {
      final ledger = t.recurringDeposits.ledger;
      // Month #1 (due 15 Jan) is collected; depositing it on 20 Apr costs ₹30 at the counter.
      final ledgerRepo = FakeRDLedgerRepository(
        transactions: {
          rd.id: [
            RDTransaction(
              id: 'tx-1',
              rdId: rd.id,
              amount: 1030,
              paidDate: DateTime(2026, 4, 18),
              paymentMode: RDPaymentMode.cash,
            ),
          ],
        },
      );
      final container = makeContainer(ledgerRepo);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showRDDepositSheet(context, rdId: rd.id, initialCount: 1),
                  child: const Text('Open Deposit Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Deposit Sheet'));
      await tester.pumpAndSettle();

      // The write is stored but its response never arrives, so the sheet reports a failure.
      ledgerRepo.failApplyAfterCommitOnce = 'response lost';
      final submit = find.text(ledger.depositSubmit(n: '1'));
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('response lost'), findsOneWidget);
      expect(submit, findsOneWidget, reason: 'the sheet stays open so the agent can retry');
      expect(ledgerRepo.poDepositsOf(rd.id), hasLength(1));

      await tester.tap(submit, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(ledgerRepo.poDepositsOf(rd.id), hasLength(1),
          reason: 'the retry must not deposit month #2 on top of the saved month #1');
      expect(submit, findsNothing, reason: 'the sheet closes once the deposit is known to be saved');
      // Toasts queue: the success message follows the earlier failure message.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.text(
          ledger.depositDoneWithFee(
            installments: ledger.installmentsCount(n: 1),
            customer: 'Anita Sharma',
            amount: 1030.0.toRupeeFormat(),
            fee: 30.0.toRupeeFormat(),
          ),
        ),
        findsOneWidget,
        reason: 'the toast describes the stored deposit (month #1), not the refreshed draft (month #2: ₹1,020)',
      );
    });

    testWidgets('RDMonthInspectorSheet hides raw poBatchId UUID; EntityDetailScaffold puts Delete in overflow menu; DetailItem copies to clipboard', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          copiedText = args['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final ledgerRepo = FakeRDLedgerRepository(
        poDeposits: {
          rd.id: [
            RDPoDeposit(
              id: 'po-1',
              rdId: rd.id,
              depositedOn: DateTime(2026, 2, 10),
              installmentCount: 1,
              feePaid: 10,
              amount: 1010,
              batchId: 'raw-batch-uuid-8888-ffff',
            ),
          ],
        },
      );
      final container = makeContainer(ledgerRepo);
      addTearDown(container.dispose);

      var deleteCalled = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: EntityDetailScaffold(
              appBarTitle: 'Detail Test',
              onEdit: () {},
              deleteDialogTitle: 'Delete?',
              deleteDialogContent: 'Confirm delete',
              onDelete: () async {
                deleteCalled = true;
                return null;
              },
              header: const Text('Header'),
              body: [
                const DetailItem(
                  label: 'Account No',
                  value: '9988776655',
                  copyValue: '9988776655',
                ),
                RDMonthInspectorSheet(
                  rdId: rd.id,
                  installmentNo: 1,
                  onCollect: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Raw batch UUID is never rendered
      expect(find.textContaining('raw-batch-uuid-8888-ffff'), findsNothing);

      // 2. Copy button copies value to Clipboard
      await tester.tap(find.byKey(const ValueKey('copy_Account No')));
      await tester.pumpAndSettle();
      expect(copiedText, '9988776655');

      // 3. Delete lives inside overflow menu, not exposed directly on AppBar
      await tester.tap(find.byKey(const ValueKey('entity_detail_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('entity_detail_delete_item')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });
  });
}
