import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/widgets/expressive/app_navigation.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

import '../core/routing/signed_in_app.dart';

/// The Recurring destination carries the number of accounts in arrears, on every tab. The
/// number comes from the summary cache (one row per account), not from the ledgers.
void main() {
  final source = FakeDataSource();

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(AppNavigationBar), matching: finder);

  /// The app on the demo accounts, whose ledger is paid up to 27 Oct 2026. The Monthly Hub
  /// is opened once, which fills the summary cache, and the Dashboard is returned to.
  /// Returns the accounts in arrears on [today].
  Future<int> pumpOn(WidgetTester tester, DateTime today) async {
    await pumpSignedInApp(
      tester,
      recurringDeposits: FakeRecurringDepositRepository(
        deposits: source.recurringDeposits,
      ),
      ledger: FakeRDLedgerRepository(
        transactions: source.rdTransactions,
        poDeposits: source.rdPoDeposits,
      ),
      today: today,
    );
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    await tester.tap(inBar(find.text(t.nav.recurringDeposits)));
    await settle();
    await tester.tap(find.text(t.recurringDeposits.views.monthlyHub));
    await settle();
    await tester.tap(inBar(find.text(t.nav.dashboard)));
    await settle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppNavigationBar)),
    );
    return container.read(globalAgentFloatProvider).arrearsAccounts;
  }

  testWidgets('accounts in arrears are counted on the Recurring destination', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final arrears = await pumpOn(tester, DateTime(2027, 2, 10));
    expect(arrears, greaterThan(0));

    expect(inBar(find.text('$arrears')), findsOneWidget);
    // The number alone says nothing to a screen reader: the destination says what it counts.
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(t.nav.recurringDepositsInArrears(n: arrears)),
      ),
      matchesSemantics(
        label: t.nav.recurringDepositsInArrears(n: arrears),
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel(t.nav.recurringDeposits), findsNothing);
    semantics.dispose();
  });

  testWidgets('with no account in arrears the destination has no badge', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final arrears = await pumpOn(tester, DateTime(2026, 4, 20));
    expect(arrears, 0);

    expect(inBar(find.text('0')), findsNothing);
    expect(find.bySemanticsLabel(t.nav.recurringDeposits), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('in arrears')), findsNothing);
    semantics.dispose();
  });
}
