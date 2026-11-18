import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
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
import 'package:skeletonizer/skeletonizer.dart';

import 'signed_in_app.dart';

/// A deposit's avatar, account number and amount travel between a row of the deposit and
/// the deposit's screen, from each place that has such a row, through the real router.
void main() {
  Finder avatar() => find.byType(AppShapeAvatar);

  /// The copy of a line of text that is on its way between the two screens.
  Finder inFlight(String text) => find.descendant(
    of: find.byType(DefaultTextStyleTransition),
    matching: find.text(text),
  );

  /// The size of the font [text] is drawn in.
  double fontSize(WidgetTester tester, Finder text) => tester
      .widget<RichText>(find.descendant(of: text, matching: find.byType(RichText)))
      .text
      .style!
      .fontSize!;

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
    required String amount,
    bool accountOnOneLine = true,
  }) async {
    Finder inRow(Finder part) => find.descendant(of: row, matching: part);
    Finder onScreen(Finder part) => find.descendant(of: find.byType(S), matching: part);

    final rowAvatar = tester.getRect(inRow(avatar()));
    final rowAccountSize = fontSize(tester, inRow(find.text(accountNo)));
    final rowAmountSize = fontSize(tester, inRow(find.text(amount)));
    final listLocation = router.location();

    await tapAndTakeOff(tester, row);
    expect(router.location(), endsWith('/$depositId'));

    // On the way neither end shows its copy: the one drawn is the one in flight.
    expect(inRow(avatar()), findsNothing);
    expect(inRow(find.text(accountNo)), findsNothing);
    expect(inRow(find.text(amount)), findsNothing);
    expect(inHeadOf<S>(avatar()), findsNothing);
    expect(inHeadOf<S>(find.text(accountNo)), findsNothing);
    // The number and the amount are growing from the row's size of font to the screen's.
    if (accountOnOneLine) {
      expect(fontSize(tester, inFlight(accountNo)), greaterThan(rowAccountSize));
    }
    expect(fontSize(tester, inFlight(amount)), greaterThan(rowAmountSize));

    await rest(tester);

    // Landed: a larger avatar and the account number as the title at the head, and the
    // amount in the first figure under it.
    expect(inFlight(accountNo), findsNothing);
    expect(tester.getRect(inHeadOf<S>(avatar())).width, AppDimensions.avatarLg);
    final headAccountSize = fontSize(tester, inHeadOf<S>(find.text(accountNo)));
    expect(headAccountSize, greaterThan(rowAccountSize));
    expect(onScreen(find.text(amount)), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(inHeadOf<S>(avatar()), findsNothing);
    expect(inRow(avatar()), findsNothing);
    if (accountOnOneLine) {
      expect(fontSize(tester, inFlight(accountNo)), lessThan(headAccountSize));
    }

    // Just before they land the number and the amount have the row's size of font: they
    // do not arrive large and shrink in the row.
    await tester.pump(const Duration(milliseconds: 280));
    if (accountOnOneLine) {
      expect(fontSize(tester, inFlight(accountNo)), closeTo(rowAccountSize, 0.5));
    }
    expect(fontSize(tester, inFlight(amount)), closeTo(rowAmountSize, 0.5));

    await rest(tester);
    expect(router.location(), listLocation);
    expect(tester.getRect(inRow(avatar())), rowAvatar);
    expect(fontSize(tester, inRow(find.text(amount))), rowAmountSize);
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
      amount: rameshTimeDeposit.principalAmount.toRupeeFormat(),
    );
  });

  testWidgets('from the one-time list, a deposit that grows to maturity', (tester) async {
    // Its screen leads with the sum invested, where a time deposit's leads with the
    // principal locked in: the amount lands in the first figure of either.
    final router = await pumpSignedInApp(
      tester,
      oneTimeDeposits: FakeOneTimeDepositRepository(
        deposits: [rameshSavingsCertificate],
        delay: Duration.zero,
      ),
    );
    await openTab(tester, 'One-Time');

    await expectRoundTrip<OneTimeDepositDetailScreen>(
      tester,
      router,
      row: find.byType(OneTimeDepositCard),
      depositId: rameshSavingsCertificate.id,
      accountNo: rameshSavingsCertificate.accountNo!,
      amount: rameshSavingsCertificate.principalAmount.toRupeeFormat(),
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
      amount: rameshRecurringDeposit.installmentAmount.toRupeeFormat(),
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
      amount: rameshTimeDeposit.principalAmount.toRupeeFormat(),
      // Beside the amount, the row's title takes two lines in the test font, which is
      // about twice as wide as the app's. A name on two lines travels as the screen's
      // copy, scaled; the lists above cover the change of style.
      accountOnOneLine: false,
    );
  });

  testWidgets('the full record arriving on the way does not end the amount\'s trip', (tester) async {
    final deposits = LateOneTimeDepositRepository();
    await pumpSignedInApp(tester, oneTimeDeposits: deposits);
    await openTab(tester, 'One-Time');
    final amount = rameshTimeDeposit.principalAmount.toRupeeFormat();
    final screen = find.byType(OneTimeDepositDetailScreen);

    await tester.tap(find.byType(OneTimeDepositCard));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The screen is drawn from the list's record, which lacks only the nominees: none of
    // it is a placeholder that would have to be rebuilt when the full record arrives.
    expect(
      find.descendant(
        of: screen,
        matching: find.byWidgetPredicate((widget) => widget is Skeletonizer && widget.enabled),
      ),
      findsNothing,
    );

    deposits.answer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Still one copy, on its way. Its place on the screen fills when that copy lands.
    expect(inFlight(amount), findsOneWidget);
    expect(find.descendant(of: screen, matching: find.text(amount)), findsNothing);

    await rest(tester);
    expect(inFlight(amount), findsNothing);
    expect(find.descendant(of: screen, matching: find.text(amount)), findsOneWidget);
    expect(tester.takeException(), isNull);
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
