import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/models/base_deposit.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_transactions_section.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// Deposit detail screens: the status action is in the menu with its label, the header
/// says when a one-time deposit matures, and the receipts are grouped by year.
void main() {
  final source = FakeDataSource();
  final rd = source.recurringDeposits.first;
  final otd = source.oneTimeDeposits.first;

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 2400) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository(
      initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
    );
    addTearDown(authRepo.dispose);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
        authRepositoryProvider.overrideWithValue(authRepo),
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
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
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
  }

  group('closing a deposit', () {
    for (final (name, screen, confirmation) in [
      (
        'recurring deposit',
        RecurringDepositDetailScreen(depositId: rd.id, initialTab: 'info'),
        t.recurringDeposits.closeDepositConfirmation,
      ),
      (
        'one-time deposit',
        OneTimeDepositDetailScreen(depositId: otd.id),
        t.oneTimeDeposits.closeDepositConfirmation,
      ),
    ]) {
      testWidgets(
        '$name: it is in the menu with its label, above Delete, and asks first',
        (tester) async {
          await pumpScreen(tester, screen);

          // Not an icon in the app bar any more.
          expect(find.byTooltip(t.common.close), findsNothing);
          expect(find.text(t.common.closeDeposit), findsNothing);

          // The screen passes its reload to the scaffold.
          expect(find.byType(AppRefreshIndicator), findsOneWidget);

          await tester.tap(
            find.byKey(const ValueKey('entity_detail_more_button')),
          );
          await tester.pumpAndSettle();
          final close = find.text(t.common.closeDeposit);
          final delete = find.text(t.common.delete);
          expect(close, findsOneWidget);
          expect(
            tester.getRect(close).bottom,
            lessThanOrEqualTo(tester.getRect(delete).top),
          );

          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.text(confirmation), findsOneWidget);
        },
      );
    }
  });

  group('one-time deposit header', () {
    for (final deposit in source.oneTimeDeposits) {
      testWidgets('${deposit.accountNo} says when it matures, under the scheme', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          OneTimeDepositDetailScreen(depositId: deposit.id),
        );

        // The model decides whether it has matured; the header only words and colours it.
        final urgency = deposit.maturityUrgency;
        final date = deposit.maturityDate.toAppFormat();
        final header = find.byType(EntityDetailHeader);
        final line = find.descendant(
          of: header,
          matching: find.text(
            urgency == MaturityUrgency.matured
                ? t.common.maturedOn(date: date)
                : t.common.maturesOn(date: date),
          ),
        );
        expect(line, findsOneWidget);

        final scheme = AppTheme.lightTheme.colorScheme;
        expect(tester.widget<Text>(line).style?.color, switch (urgency) {
          MaturityUrgency.matured => scheme.error,
          MaturityUrgency.maturingSoon => scheme.tertiary,
          _ => scheme.onSurfaceVariant,
        });

        final name = find.descendant(
          of: header,
          matching: find.text(deposit.schemeType.displayName),
        );
        expect(
          tester.getRect(line).top,
          greaterThanOrEqualTo(tester.getRect(name).bottom),
        );
        expect(tester.getRect(line).left, tester.getRect(name).left);
      });
    }
  });

  group('receipts', () {
    final receipts = source.rdTransactions[rd.id] ?? const [];
    final years = receipts.map((tx) => tx.paidDate.year).toSet();

    testWidgets('are grouped by year, newest first, with no header per month', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        RecurringDepositDetailScreen(
          depositId: rd.id,
          initialTab: 'transactions',
        ),
      );
      expect(
        receipts.length,
        greaterThan(years.length),
        reason: 'fixture: several per year',
      );

      final section = find.byType(RDTransactionsSection);
      expect(
        find.descendant(of: section, matching: find.byType(RDTransactionTile)),
        findsNWidgets(receipts.length),
      );
      final headers = tester
          .widgetList<DetailSectionTitle>(
            find.descendant(
              of: section,
              matching: find.byType(DetailSectionTitle),
            ),
          )
          .map((header) => header.title)
          .toList();
      // The section has other headers too (the Post Office visits); none names a month.
      expect(headers.where((h) => RegExp(r'^\D+ \d{4}$').hasMatch(h)), isEmpty);
      expect(
        headers.where((h) => RegExp(r'^\d{4}$').hasMatch(h)).toList(),
        (years.toList()..sort((a, b) => b.compareTo(a)))
            .map((y) => '$y')
            .toList(),
      );

      // Top to bottom the receipts run from the latest payment to the earliest.
      final tiles = tester
          .widgetList<RDTransactionTile>(
            find.descendant(
              of: section,
              matching: find.byType(RDTransactionTile),
            ),
          )
          .map((tile) => tile.transaction.paidDate)
          .toList();
      for (var i = 1; i < tiles.length; i++) {
        expect(tiles[i].isAfter(tiles[i - 1]), isFalse);
      }
    });

    testWidgets('the months a receipt was applied to are neutral labels', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        RecurringDepositDetailScreen(
          depositId: rd.id,
          initialTab: 'transactions',
        ),
      );
      final scheme = AppTheme.lightTheme.colorScheme;
      final pills = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(RDTransactionTile),
          matching: find.textContaining(RegExp(r'^#\d+ ')),
        ),
      );
      expect(pills, isNotEmpty);
      for (final pill in pills) {
        expect(pill.style?.color, scheme.onSurfaceVariant);
      }
    });
  });
}
