import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/presentation/widgets/one_time_deposit_card.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/recurring_deposit_card.dart';

import 'signed_in_app.dart';

/// A deposit's avatar and account number travel between a row of the deposit and the head
/// of the deposit's screen, from each place that has such a row, through the real router.
void main() {
  Finder avatar() => find.byType(AppShapeAvatar);

  /// The head of the screen of type [T], and a part inside it.
  Finder headOf<T extends Widget>() =>
      find.descendant(of: find.byType(T), matching: find.byType(EntityDetailHeader));
  Finder inHeadOf<T extends Widget>(Finder part) =>
      find.descendant(of: headOf<T>(), matching: part);

  Future<AppRouter> pumpWithDeposits(
    WidgetTester tester, {
    CustomerRepository? customers,
  }) => pumpSignedInApp(
    tester,
    customers: customers,
    oneTimeDeposits: FakeOneTimeDepositRepository(
      deposits: [rameshTimeDeposit],
      delay: Duration.zero,
    ),
    recurringDeposits: FakeRecurringDepositRepository(deposits: [rameshRecurringDeposit]),
  );

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> tapAndTakeOff(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    // The router builds the screen; the flight starts once it has been laid out.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  /// Long enough for a transition to end and for providers to answer. The recurring
  /// deposit's screen draws its ledger's progress, which need not settle.
  Future<void> rest(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Opens the screen of type [S] from [row], checks the trip there, and the trip back.
  Future<void> expectRoundTrip<S extends Widget>(
    WidgetTester tester,
    AppRouter router, {
    required Finder row,
    required String depositId,
    required String accountNo,
  }) async {
    final rowAvatar = tester.getRect(find.descendant(of: row, matching: avatar()));
    final rowAccount = tester.getRect(find.descendant(of: row, matching: find.text(accountNo)));
    final listLocation = router.location();

    await tapAndTakeOff(tester, row);
    expect(router.location(), endsWith('/$depositId'));

    // On the way neither end shows its copy: the one drawn is the one in flight.
    expect(find.descendant(of: row, matching: avatar()), findsNothing);
    expect(find.descendant(of: row, matching: find.text(accountNo)), findsNothing);
    expect(inHeadOf<S>(avatar()), findsNothing);
    expect(inHeadOf<S>(find.text(accountNo)), findsNothing);

    await rest(tester);

    // Landed at the head: a larger avatar, and the account number as the title.
    expect(tester.getRect(inHeadOf<S>(avatar())).width, AppDimensions.avatarLg);
    expect(
      tester.getRect(inHeadOf<S>(find.text(accountNo))).height,
      greaterThan(rowAccount.height),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(inHeadOf<S>(avatar()), findsNothing);
    expect(find.descendant(of: row, matching: avatar()), findsNothing);

    await rest(tester);
    expect(router.location(), listLocation);
    expect(tester.getRect(find.descendant(of: row, matching: avatar())), rowAvatar);
    expect(tester.takeException(), isNull);
  }

  testWidgets('from the one-time list', (tester) async {
    final router = await pumpWithDeposits(tester);
    await openTab(tester, 'One-Time');
    final row = find.byType(OneTimeDepositCard);

    // The row is titled by the customer and the head of the screen is not: the name is
    // not among the parts that travel. The account number, the row's second line, is.
    final name = find.descendant(of: row, matching: find.text(rameshRao.name));
    expect(name, findsOneWidget);
    expect(find.ancestor(of: name, matching: find.byType(Hero)), findsNothing);

    await expectRoundTrip<OneTimeDepositDetailScreen>(
      tester,
      router,
      row: row,
      depositId: rameshTimeDeposit.id,
      accountNo: rameshTimeDeposit.accountNo!,
    );
  });

  testWidgets('from the recurring list', (tester) async {
    final router = await pumpWithDeposits(tester);
    await openTab(tester, 'Recurring');

    await expectRoundTrip<RecurringDepositDetailScreen>(
      tester,
      router,
      row: find.byType(RecurringDepositCard),
      depositId: rameshRecurringDeposit.id,
      accountNo: rameshRecurringDeposit.accountNo!,
    );
  });

  testWidgets('from the deposit\'s row on its customer\'s screen', (tester) async {
    final router = await pumpWithDeposits(tester);
    await tester.tap(find.text(rameshRao.name));
    await tester.pumpAndSettle();

    final row = find.descendant(
      of: find.byType(CustomerDetailScreen),
      matching: find.byType(OneTimeDepositCard),
    );
    await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await expectRoundTrip<OneTimeDepositDetailScreen>(
      tester,
      router,
      row: row,
      depositId: rameshTimeDeposit.id,
      accountNo: rameshTimeDeposit.accountNo!,
    );
  });

  testWidgets('a row in a tab out of view sends nothing to the customer\'s screen', (tester) async {
    // The customer's full record stays out, as it does for a moment from a server: the
    // screen keeps the shape of its first frame for the whole transition.
    final customers = LateCustomerRepository();
    await pumpWithDeposits(tester, customers: customers);
    // Once opened, a tab stays alive out of view, and with it the deposit's row there.
    await openTab(tester, 'One-Time');
    await openTab(tester, 'Customers');
    expect(find.byType(OneTimeDepositCard), findsNothing);
    expect(find.byType(OneTimeDepositCard, skipOffstage: false), findsOneWidget);

    // Tall enough for the customer's deposits to be built with the screen's first frame.
    tester.view.physicalSize = const Size(412, 2400) * tester.view.devicePixelRatio;
    await tester.pump();

    await tapAndTakeOff(tester, find.text(rameshRao.name));

    // The customer's own parts are on their way. The same deposit's row on the customer's
    // screen keeps its avatar: it is not the destination of the row in the other tab.
    final rowOnScreen = find.descendant(
      of: find.byType(CustomerDetailScreen),
      matching: find.byType(OneTimeDepositCard),
    );
    expect(rowOnScreen, findsOneWidget);
    expect(find.descendant(of: rowOnScreen, matching: avatar()), findsOneWidget);

    customers.answer();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
