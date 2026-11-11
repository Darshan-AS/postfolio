import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_input_decoration.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/domain/nominees_input_section.dart';
import 'package:postfolio/core/widgets/forms/app_form_fields.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_selection_field.dart';
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
}
