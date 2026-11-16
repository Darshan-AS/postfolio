import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposits_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

class _RecordingIntents extends IntentService {
  final calls = <String>[];

  @override
  Future<void> launchPhone(String phone) async => calls.add('phone $phone');

  @override
  Future<void> launchWhatsApp(String phone) async => calls.add('whatsapp $phone');
}

/// Rows of the three lists, and of the deposits on a customer's screen: what a row
/// carries, and what it leaves to its menu or to the filter.
void main() {
  final source = FakeDataSource();
  final customer = source.customers.first;

  Future<_RecordingIntents> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository(
      initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
    );
    addTearDown(authRepo.dispose);
    final intents = _RecordingIntents();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
        intentServiceProvider.overrideWithValue(intents),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(customers: source.customers),
        ),
        oneTimeDepositRepositoryProvider.overrideWithValue(
          FakeOneTimeDepositRepository(deposits: source.oneTimeDeposits),
        ),
        recurringDepositRepositoryProvider.overrideWithValue(
          FakeRecurringDepositRepository(deposits: source.recurringDeposits),
        ),
        rdLedgerRepositoryProvider.overrideWithValue(
          FakeRDLedgerRepository(
            transactions: source.rdTransactions,
            poDeposits: source.rdPoDeposits,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: SkeletonizerConfig(
              data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
              child: child!,
            ),
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    return intents;
  }

  RenderParagraph paragraphOf(WidgetTester tester, Finder text) => tester
      .renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)).first,
      );

  group('customer rows', () {
    final row = find.widgetWithText(CustomerCard, customer.name);

    testWidgets('Call is on the row; WhatsApp is in the row\'s menu and still works', (
      tester,
    ) async {
      final intents = await pumpScreen(tester, const CustomersScreen());
      final actions = t.customers.actions;

      expect(find.descendant(of: row, matching: find.byTooltip(actions.call)), findsOneWidget);
      expect(find.byTooltip(actions.whatsapp), findsNothing);
      expect(find.text(actions.whatsapp), findsNothing);

      await tester.tap(find.descendant(of: row, matching: find.byTooltip(actions.call)));
      await tester.pump();
      expect(intents.calls, ['phone ${customer.phone}']);

      await tester.tap(find.descendant(of: row, matching: find.byTooltip(t.common.moreOptions)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(actions.whatsapp));
      await tester.pumpAndSettle();
      expect(intents.calls.last, 'whatsapp ${customer.phone}');
    });

    testWidgets('the row keeps two buttons, so the name and the number get the rest', (
      tester,
    ) async {
      await pumpScreen(tester, const CustomersScreen());
      expect(find.descendant(of: row, matching: find.byType(IconButton)), findsNWidgets(2));

      final rowRect = tester.getRect(row);
      final phone = tester.getRect(
        find.descendant(of: row, matching: find.text(customer.phone!.toPhoneFormat())),
      );
      final call = tester.getRect(
        find.descendant(of: row, matching: find.byTooltip(t.customers.actions.call)),
      );
      // The text column runs from the avatar to the Call button: with a second inline
      // button it stopped 48dp earlier and "+91 98765 43201" broke in two.
      expect(call.left - phone.left, greaterThan(rowRect.width * 0.4));
    });
  });

  group('deposit rows', () {
    testWidgets('an active one-time deposit carries no status badge', (tester) async {
      await pumpScreen(tester, const OneTimeDepositsScreen());
      expect(find.byType(OneTimeDepositCard), findsWidgets);
      expect(find.byType(StatusBadge), findsNothing);
    });

    testWidgets('an active recurring deposit carries no status badge', (tester) async {
      await pumpScreen(tester, const RecurringDepositsScreen(initialView: 'accounts'));
      expect(find.byType(RecurringDepositCard), findsWidgets);
      expect(find.byType(StatusBadge), findsNothing);
    });

    testWidgets('a closed deposit still says so', (tester) async {
      final closed = source.oneTimeDeposits.first.copyWith(status: DepositStatus.closed);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: OneTimeDepositCard(deposit: closed)),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(DepositStatus.closed.displayName),
        ),
        findsOneWidget,
      );
    });

    testWidgets('on a customer\'s screen a deposit is titled by its account number, not '
        'by the scheme its avatar already names', (tester) async {
      await pumpScreen(
        tester,
        CustomerDetailScreen(customerId: customer.id),
        size: const Size(360, 2400),
      );
      final otd = source.oneTimeDeposits.firstWhere((d) => d.customerId == customer.id);
      final rd = source.recurringDeposits.firstWhere((d) => d.customerId == customer.id);

      final otdRow = find.byType(OneTimeDepositCard);
      final rdRow = find.byType(RecurringDepositCard);
      expect(find.descendant(of: otdRow, matching: find.text(otd.accountNo!)), findsOneWidget);
      expect(find.descendant(of: rdRow, matching: find.text(rd.accountNo!)), findsOneWidget);
      expect(
        find.descendant(of: otdRow, matching: find.text(otd.schemeType.displayName)),
        findsNothing,
      );
      expect(
        find.descendant(of: rdRow, matching: find.text(rd.schemeType.displayName)),
        findsNothing,
      );
      // The customer is the screen: the rows do not repeat the name either.
      expect(find.descendant(of: otdRow, matching: find.text(customer.name)), findsNothing);
      expect(find.descendant(of: rdRow, matching: find.text(customer.name)), findsNothing);
    });
  });

  group('AppSearchBar hint', () {
    final longHint = t.customers.searchHint;
    final shortHint = t.common.search;

    Future<void> pumpBar(WidgetTester tester, {required double width, double textScale = 1.0}) async {
      tester.view.physicalSize = Size(width, 400) * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: AppSearchBar(
              hintText: longHint,
              onChanged: (_) {},
              trailing: [
                for (final tooltip in ['Sort', 'Filter'])
                  IconButton(
                    tooltip: tooltip,
                    onPressed: () {},
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFilter,
                      size: AppDimensions.iconMd,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }

    // The short hint is the floor. What is checked is that the long one is never shown cut,
    // in steps small enough to land on either side of the width where it starts to fit.
    for (final textScale in const [1.0, 1.3, 2.0]) {
      testWidgets('at ${textScale}x the long hint is shown only where it is not cut', (
        tester,
      ) async {
        var shownSomewhere = false;
        var hiddenSomewhere = false;
        for (var width = 320.0; width <= 2200; width += 6) {
          await pumpBar(tester, width: width, textScale: textScale);
          if (find.text(longHint).evaluate().isEmpty) {
            hiddenSomewhere = true;
            expect(find.text(shortHint), findsOneWidget);
            expect(shownSomewhere, isFalse, reason: 'hidden again at ${width}dp');
          } else {
            shownSomewhere = true;
            expect(
              paragraphOf(tester, find.text(longHint)).didExceedMaxLines,
              isFalse,
              reason: 'cut at ${width}dp',
            );
          }
        }
        expect(hiddenSomewhere, isTrue);
        expect(shownSomewhere, isTrue);
      });
    }

    testWidgets('a phone gets the short hint, a wide window what can be searched for', (
      tester,
    ) async {
      await pumpBar(tester, width: 360);
      expect(find.text(shortHint), findsOneWidget);
      expect(find.text(longHint), findsNothing);

      await pumpBar(tester, width: 2200);
      expect(find.text(longHint), findsOneWidget);
      expect(find.text(shortHint), findsNothing);
    });
  });
}
