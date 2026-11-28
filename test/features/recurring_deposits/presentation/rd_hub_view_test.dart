import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_batch_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_month_progress.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// The Monthly Hub's controls and the states the screen-wide layout matrix does not reach:
/// a selection with the floating batch bar, a selected header filter, another month, the
/// ungrouped list, overdue accounts and the empty list.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  final source = FakeDataSource();
  final ops = t.recurringDeposits.monthlyOperations;

  /// The customer with two recurring deposits in [FakeDataSource], and one with a single RD.
  const twoAccounts = 'Bruce Wayne';
  const oneAccount = 'Alfred Pennyworth';

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Pumps the Hub in a 360dp-wide window. [FakeDataSource] is anchored at 27 Oct 2026:
  /// that default date shows every Hub state (settled, in hand, partial, unpaid, arrears,
  /// fronted); June 2026 is a settled month; December 2026 puts every account in arrears.
  Future<ProviderContainer> pumpHub(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
    double textScale = 1.0,
    bool disableAnimations = true,
    DateTime? today,
  }) async {
    tester.view.physicalSize = Size(width, height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ledger = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
      absorptions: source.rdFeeAbsorptions,
    );
    final deposits = FakeRecurringDepositRepository(
      deposits: source.recurringDeposits,
    );
    addTearDown(ledger.dispose);
    addTearDown(deposits.dispose);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(
          () => today ?? FakeDataSource.defaultReferenceDate,
        ),
        customerRepositoryProvider.overrideWithValue(
          FakeCustomerRepository(customers: source.customers),
        ),
        recurringDepositRepositoryProvider.overrideWithValue(deposits),
        rdLedgerRepositoryProvider.overrideWithValue(ledger),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(
                  Theme.of(context).colorScheme,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const Scaffold(body: RDMonthlyOperationsView()),
        ),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    return container;
  }

  /// The selection marks on screen. In selection mode a row's avatar turns over into one;
  /// the copies the flip keeps laid out to hold its size are not counted.
  Finder selectionMarks() => find
      .byWidgetPredicate((w) => w is Semantics && w.properties.checked != null)
      .hitTestable();

  group('Monthly Hub controls', () {
    testWidgets(
      'due-window group, group-by and select toggles drive the Hub state',
      (tester) async {
        final container = await pumpHub(tester, height: 3600);
        expect(find.byType(RDMonthlyOperationCard), findsWidgets);
        RDHubFiltersState filters() => container.read(rDHubFiltersProvider);
        final kpis = container.read(monthlyOperationsKpiProvider);
        final firstHalf = ops.toolbar.window15th(count: kpis.firstHalfCount);

        // Each label is in the tree once: `find.text` must not hit a measuring copy.
        expect(find.text(ops.toolbar.windowAll), findsOneWidget);
        expect(find.text(firstHalf), findsOneWidget);
        expect(
          find.text(ops.toolbar.windowEom(count: kpis.secondHalfCount)),
          findsOneWidget,
        );

        expect(filters().dueWindow, RDDueWindowFilter.all);
        await tester.tap(find.text(firstHalf));
        await settle(tester);
        expect(filters().dueWindow, RDDueWindowFilter.firstHalf);

        // Tapping the selected window again must not clear it.
        await tester.tap(find.text(firstHalf));
        await settle(tester);
        expect(filters().dueWindow, RDDueWindowFilter.firstHalf);

        await tester.tap(find.text(ops.toolbar.windowAll));
        await settle(tester);
        expect(filters().dueWindow, RDDueWindowFilter.all);

        expect(filters().groupByCustomer, isTrue);
        expect(find.text(ops.customerGroup.selectGroup), findsOneWidget);
        await tester.tap(find.byTooltip(ops.toolbar.groupByCustomer));
        await settle(tester);
        expect(filters().groupByCustomer, isFalse);
        expect(find.text(ops.customerGroup.selectGroup), findsNothing);
        expect(find.byType(RDMonthlyOperationCard), findsWidgets);

        await tester.tap(find.byTooltip(ops.toolbar.selectMode));
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).isSelectionMode, isTrue);
        expect(selectionMarks(), findsWidgets);

        await tester.tap(find.byTooltip(ops.toolbar.exitSelectMode));
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).isSelectionMode, isFalse);
        expect(selectionMarks(), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'in selection mode a row\'s avatar is its selection mark: a checkbox to a '
      'screen reader, ticked by a tap on the row',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final container = await pumpHub(tester);
        final label = ops.card.selectRow(name: oneAccount);
        expect(selectionMarks(), findsNothing);
        expect(find.bySemanticsLabel(label), findsNothing);

        await tester.tap(find.byTooltip(ops.toolbar.selectMode));
        await settle(tester);

        SemanticsNode mark() =>
            tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          mark(),
          matchesSemantics(
            label: label,
            hasCheckedState: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(find.text(oneAccount));
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).count, 1);
        expect(
          mark(),
          matchesSemantics(
            label: label,
            hasCheckedState: true,
            isChecked: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        // The mark itself can be acted on, as the checkbox it replaces could.
        mark().owner!.performAction(mark().id, SemanticsAction.tap);
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).count, 0);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

    testWidgets('the avatar takes time to turn over', (tester) async {
      await pumpHub(tester, disableAnimations: false);
      await tester.tap(find.byTooltip(ops.toolbar.selectMode));
      await tester.pump();
      // A quarter of the way over, the avatar is still the face that shows.
      await tester.pump(AppMotion.effectsDuration ~/ 4);
      expect(selectionMarks(), findsNothing);
      await tester.pump(AppMotion.effectsDuration);
      expect(selectionMarks(), findsWidgets);
    });

    testWidgets(
      'on a device that removes animations the mark is there in the next frame',
      (tester) async {
        await pumpHub(tester);
        await tester.tap(find.byTooltip(ops.toolbar.selectMode));
        await tester.pump();
        await tester.pump();
        expect(selectionMarks(), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'switching to a settled month shows its statement without the arrival',
      (tester) async {
        // June 2026 is fully settled; July 2026 has Harvey Dent unpaid.
        await pumpHub(
          tester,
          disableAnimations: false,
          today: DateTime(2026, 6, 20),
        );
        final bar = find.byKey(const ValueKey('bar'));
        final statement = find.byKey(const ValueKey('settled'));
        expect(statement, findsOneWidget);

        // July 2026 has an unpaid account: bar shows instead of the settled statement.
        await tester.tap(find.byTooltip(ops.nextMonth));
        await settle(tester);
        expect(bar, findsOneWidget);
        expect(statement, findsNothing);

        // Back to June. Whenever its statement is on screen, the bar it would replace in an
        // arrival is not.
        await tester.tap(find.byTooltip(ops.previousMonth));
        var seen = false;
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          if (statement.evaluate().isNotEmpty) {
            seen = true;
            expect(bar, findsNothing, reason: 'frame $frame');
          }
        }
        expect(seen, isTrue);
      },
    );

    testWidgets(
      'a header tile filters the list and turns into a filled tile while selected',
      (tester) async {
        final container = await pumpHub(tester);
        final label = ops.kpis.receivable;
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(AppGroupTile),
        );
        Color? fill() => tester.widget<AppGroupTile>(tile).color;
        final palette = AppFinancialColors.of(tester.element(tile)).fronted;

        expect(fill(), palette.container);

        await tester.tap(find.text(label));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.fronted,
        );
        // The pair swaps: the fill is the solid colour, the text takes the container's.
        expect(fill(), palette.onContainer);
        expect(
          tester.widget<Text>(find.text(label)).style?.color,
          palette.container,
        );

        await tester.tap(find.text(label));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.all,
        );
        expect(fill(), palette.container);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Select All fills the floating batch bar, which reports and clears the selection',
      (tester) async {
        // Animations on: the bar's entrance must come to rest.
        final container = await pumpHub(
          tester,
          height: 3600,
          disableAnimations: false,
        );
        await tester.pumpAndSettle();
        expect(find.byType(RDHubBatchBar), findsNothing);

        // The customer with two accounts (Bruce Wayne): Select All ticks both.
        final selectAll = find.text(ops.customerGroup.selectGroup);
        await tester.ensureVisible(selectAll);
        await tester.pumpAndSettle();
        await tester.tap(selectAll);
        await tester.pumpAndSettle();

        expect(container.read(rDHubSelectionProvider).isSelectionMode, isTrue);
        expect(container.read(rDHubSelectionProvider).count, 2);

        // Also select Alfred Pennyworth (in hand, ready to deposit) so the batch bar shows a
        // ready-to-deposit count and its Deposit action button.
        final alfred = find.text('Alfred Pennyworth');
        await tester.ensureVisible(alfred);
        await tester.pumpAndSettle();
        await tester.tap(alfred);
        await tester.pumpAndSettle();

        final selection = container.read(rDHubSelectionProvider);
        expect(selection.isSelectionMode, isTrue);
        expect(selection.count, 3);

        final summary = container.read(batchSelectionSummaryProvider);
        expect(summary.readyInstallments, greaterThan(0));
        final bar = find.byType(RDHubBatchBar);
        expect(
          find.descendant(
            of: bar,
            matching: find.text(
              ops.batchPo.selectedSummary(
                count: summary.count,
                ready: summary.readyInstallments,
                amount: summary.totalAmount.toRupeeFormat(),
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: bar,
            matching: find.text(
              ops.batchPo.action(count: summary.readyInstallments),
            ),
          ),
          findsOneWidget,
        );

        // It floats: inside the window on every side, clear of the bottom edge.
        final surface = tester.getRect(
          find.descendant(of: bar, matching: find.byType(Material)).first,
        );
        final window = tester.getRect(find.byType(RDMonthlyOperationsView));
        expect(
          surface.left,
          greaterThanOrEqualTo(window.left + AppDimensions.pageMargin),
        );
        expect(
          surface.right,
          lessThanOrEqualTo(window.right - AppDimensions.pageMargin),
        );
        expect(surface.bottom, window.bottom - AppDimensions.pageMargin);

        await tester.tap(find.byTooltip(ops.batchPo.deselectAll));
        await tester.pumpAndSettle();
        expect(find.byType(RDHubBatchBar), findsNothing);
        expect(container.read(rDHubSelectionProvider).isSelectionMode, isFalse);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the month switcher steps, offers Current month away from it, and opens the picker',
      (tester) async {
        final container = await pumpHub(tester);
        DateTime month() => container.read(rDHubMonthProvider);

        expect(month(), DateTime(2026, 10));
        expect(find.text(ops.currentMonth), findsNothing);

        await tester.tap(find.byTooltip(ops.nextMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 11));
        expect(find.text(ops.currentMonth), findsOneWidget);

        await tester.tap(find.text(ops.currentMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 10));
        expect(find.text(ops.currentMonth), findsNothing);

        await tester.tap(find.byTooltip(ops.previousMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 9));

        await tester.tap(find.byTooltip(ops.toolbar.pickMonth));
        await settle(tester);
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Monthly Hub layout', () {
    testWidgets(
      'only a customer with several accounts gets a header; its rows are titled '
      'by account',
      (tester) async {
        final container = await pumpHub(tester, height: 3600);

        // One account: the row carries the name, and nothing repeats it above.
        expect(find.text(oneAccount), findsOneWidget);
        expect(find.textContaining('$oneAccount •'), findsNothing);

        // Two accounts: the name is in the header only, and each row says which account.
        expect(find.textContaining('$twoAccounts •'), findsOneWidget);
        expect(find.text(twoAccounts), findsNothing);
        final titles = [
          for (final card in tester.widgetList<RDMonthlyOperationCard>(
            find.byType(RDMonthlyOperationCard),
          ))
            if (card.item.deposit.customerName == twoAccounts)
              card.titleByAccount,
        ];
        expect(titles, [isTrue, isTrue]);
        expect(find.textContaining('…0017'), findsOneWidget);
        expect(find.textContaining('…0018'), findsOneWidget);

        // Ungrouped there is no header to carry the name, so every row does.
        container
            .read(rDHubFiltersProvider.notifier)
            .toggleGroupByCustomer(false);
        await settle(tester);
        expect(find.text(twoAccounts), findsNWidgets(2));
        expect(find.textContaining('$twoAccounts •'), findsNothing);
      },
    );

    testWidgets('a row shows the amount to collect once, on its button', (
      tester,
    ) async {
      await pumpHub(tester, height: 2400, today: DateTime(2026, 12, 20));

      final cards = tester
          .widgetList<RDMonthlyOperationCard>(
            find.byType(RDMonthlyOperationCard),
          )
          .where(
            (card) =>
                card.item.isCustomerPending && card.item.totalOutstanding > 0,
          )
          .toList();
      expect(cards, isNotEmpty);

      for (final card in cards) {
        final amount = card.item.totalOutstanding.toRupeeFormat();
        final inRow = find.descendant(
          of: find.byWidget(card),
          matching: find.textContaining(amount),
        );
        expect(
          inRow,
          findsOneWidget,
          reason: '$amount in ${card.item.deposit.accountNo}',
        );
        expect(
          tester.widget<Text>(inRow).data,
          ops.card.collect(amount: amount),
        );
      }
    });

    testWidgets('the status pill and the action share one line', (
      tester,
    ) async {
      await pumpHub(tester, height: 2400, today: DateTime(2026, 12, 20));

      final card = find.byType(RDMonthlyOperationCard).first;
      final pill = tester.getRect(
        find.descendant(of: card, matching: find.byType(RDStatusPill)),
      );
      final action = tester.getRect(
        find.descendant(
          of: card,
          matching: find.byType(RDOperationActionButton),
        ),
      );
      expect(action.left, greaterThan(pill.right));
      expect(action.center.dy, closeTo(pill.center.dy, 1));
      // Touch target of the action, though it hugs its label.
      expect(action.height, greaterThanOrEqualTo(48));
      // Nothing but the caption may follow that line: the action no longer has its own.
      expect(
        tester.getRect(card).bottom - action.bottom,
        lessThan(action.height),
      );
    });

    testWidgets(
      'Collect is the main action in the brand colour even in arrears; Deposit '
      'is tonal',
      (tester) async {
        // December: every account is in arrears.
        await pumpHub(tester, height: 2400, today: DateTime(2026, 12, 20));
        final collect = tester.widgetList<AppButton>(
          find.descendant(
            of: find.byType(RDOperationActionButton),
            matching: find.byType(AppButton),
          ),
        );
        expect(collect, isNotEmpty);
        for (final button in collect) {
          expect(button.variant, AppButtonVariant.filled, reason: button.label);
          expect(button.isDestructive, isFalse, reason: button.label);
          expect(button.backgroundColor, isNull, reason: button.label);
        }
      },
    );

    testWidgets('a Deposit action is tonal, whatever the status of its row', (
      tester,
    ) async {
      // April: some accounts are settled with money waiting for the Post Office.
      await pumpHub(tester, height: 2400);
      final deposits = tester
          .widgetList<AppButton>(
            find.descendant(
              of: find.byType(RDOperationActionButton),
              matching: find.byType(AppButton),
            ),
          )
          .where(
            (button) => button.label.startsWith(
              ops.card.deposit(count: 1).split(' ').first,
            ),
          )
          .toList();
      expect(deposits, isNotEmpty);
      for (final button in deposits) {
        expect(button.variant, AppButtonVariant.tonal, reason: button.label);
        expect(button.backgroundColor, isNull, reason: button.label);
      }
    });

    testWidgets('the four header tiles take under 150dp of a 360dp phone', (
      tester,
    ) async {
      await pumpHub(tester);

      final tiles = [
        for (final label in [
          ops.kpis.toCollect,
          ops.kpis.inHand,
          ops.kpis.receivable,
          ops.kpis.arrears,
        ])
          tester.getRect(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(AppGroupTile),
            ),
          ),
      ];
      final top = tiles.map((r) => r.top).reduce((a, b) => a < b ? a : b);
      final bottom = tiles.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      expect(bottom - top, lessThan(150));
      // Two across: money keeps room to be read.
      expect(tiles[0].top, tiles[1].top);
      expect(tiles[2].top, greaterThan(tiles[0].bottom));
    });
  });

  group('Monthly Hub spacing', () {
    // The test font is about twice as wide as the app's. In a window this wide a name, a
    // hint or the batch bar's text takes one line, as it does on a phone with the real font.
    const roomy = 700.0;

    Rect tilesRect(WidgetTester tester) {
      final tiles = [
        for (final label in [
          ops.kpis.toCollect,
          ops.kpis.inHand,
          ops.kpis.receivable,
          ops.kpis.arrears,
        ])
          tester.getRect(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(AppGroupTile),
            ),
          ),
      ];
      return tiles.reduce((a, b) => a.expandToInclude(b));
    }

    testWidgets(
      'the status pill is at the same height in a row with a button and in a row '
      'without one',
      (tester) async {
        // April: settled rows, which have no button, and rows waiting for the Post Office.
        await pumpHub(tester, width: roomy, height: 2400);

        final withButton = <double>[];
        final withoutButton = <double>[];
        for (final element in find.byType(RDMonthlyOperationCard).evaluate()) {
          final widget = element.widget as RDMonthlyOperationCard;
          // Exclude the >50-char wrapping stress-test name so 2-line title height
          // does not mask the 8dp button touch-padding check on normal rows.
          if (widget.item.deposit.customerName?.startsWith("Koriand'r") ??
              false) {
            continue;
          }
          final card = find.byWidget(element.widget);
          final pill = tester.getRect(
            find.descendant(of: card, matching: find.byType(RDStatusPill)),
          );
          final hasButton = find
              .descendant(
                of: card,
                matching: find.byType(RDOperationActionButton),
              )
              .evaluate()
              .isNotEmpty;
          (hasButton ? withButton : withoutButton).add(
            pill.top - tester.getRect(card).top,
          );
        }
        expect(withButton, isNotEmpty);
        expect(withoutButton, isNotEmpty);

        final all = [...withButton, ...withoutButton]..sort();
        // The button's touch padding had put its row's pill 8dp lower.
        expect(all.last - all.first, lessThanOrEqualTo(2));
      },
    );

    testWidgets('the blocks above the rows are 12dp apart', (tester) async {
      await pumpHub(tester, today: DateTime(2026, 6, 20));

      final switcher = tester.getRect(find.byType(RDMonthSwitcher));
      final tiles = tilesRect(tester);
      final search = tester.getRect(find.byType(SearchBar));
      final dueWindow = tester.getRect(
        find.byType(AppButtonGroup<RDDueWindowFilter>),
      );
      // A 40dp pill sits 4dp inside its 48dp touch target.
      const touchPadding =
          (kMinInteractiveDimension - AppDimensions.buttonHeightSm) / 2;

      // The month's statement (June 2026 is settled here) is a block of its own.
      final progress = tester.getRect(find.byKey(const ValueKey('settled')));
      expect(progress.top - switcher.bottom, AppDimensions.paddingMd);
      expect(tiles.top - progress.bottom, AppDimensions.paddingMd);
      expect(search.top - tiles.bottom, AppDimensions.paddingMd);
      expect(
        dueWindow.top + touchPadding - search.bottom,
        AppDimensions.paddingMd,
      );
    });

    testWidgets(
      'with no progress block the tiles are 12dp under the switcher',
      (tester) async {
        await pumpHub(tester, today: DateTime(2026, 6, 20));
        // May 2026 is past and settled: it has nothing to say.
        await tester.tap(find.byTooltip(ops.previousMonth));
        await settle(tester);
        expect(find.byType(RDHubMonthProgress), findsOneWidget);
        expect(tester.getSize(find.byType(RDHubMonthProgress)).height, 0);

        final switcher = tester.getRect(find.byType(RDMonthSwitcher));
        expect(
          tilesRect(tester).top - switcher.bottom,
          AppDimensions.paddingMd,
        );
      },
    );

    testWidgets(
      'a tile\'s text starts on the edge a row\'s avatar and pill start on',
      (tester) async {
        await pumpHub(tester, height: 1600);

        final card = find.byType(RDMonthlyOperationCard).first;
        final pill = tester.getRect(
          find.descendant(of: card, matching: find.byType(RDStatusPill)),
        );
        expect(pill.left, 2 * AppDimensions.pageMargin);
        for (final label in [ops.kpis.toCollect, ops.kpis.receivable]) {
          expect(tester.getRect(find.text(label)).left, pill.left);
        }
      },
    );

    testWidgets(
      'where the search hint does not fit, the pill shows the short one',
      (tester) async {
        await pumpHub(tester);
        expect(find.text(t.common.search), findsOneWidget);
        expect(find.text(ops.searchHint), findsNothing);
      },
    );

    testWidgets('where the search hint fits, it is shown whole', (
      tester,
    ) async {
      await pumpHub(tester, width: roomy);
      final hint = find.text(ops.searchHint);
      expect(hint, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: hint, matching: find.byType(RichText)).first,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets(
      'two toggles that are on keep a gap between them, inside the search pill',
      (tester) async {
        final container = await pumpHub(tester);
        container.read(rDHubSelectionProvider.notifier).enter();
        await settle(tester);

        Rect fillOf(String tooltip) => tester.getRect(
          // The button's own surface: the nearest one around its icon.
          find
              .ancestor(
                of: find.byTooltip(tooltip),
                matching: find.byType(Material),
              )
              .first,
        );
        final group = fillOf(ops.toolbar.groupByCustomer);
        final select = fillOf(ops.toolbar.exitSelectMode);
        final search = tester.getRect(find.byType(SearchBar));

        expect(group.size, const Size.square(AppDimensions.buttonHeightSm));
        expect(select.size, group.size);
        expect(
          select.left - group.right,
          greaterThanOrEqualTo(AppDimensions.paddingSm),
        );
        expect(
          group.top - search.top,
          greaterThanOrEqualTo(AppDimensions.paddingSm),
        );
        expect(
          search.bottom - group.bottom,
          greaterThanOrEqualTo(AppDimensions.paddingSm),
        );
      },
    );

    testWidgets(
      'the batch bar\'s button is as far from the bar\'s end as from its top',
      (tester) async {
        final container = await pumpHub(tester, width: roomy);
        final items = await container.read(
          monthlyOperationItemsProvider.future,
        );
        container.read(rDHubSelectionProvider.notifier).selectAll([
          for (final i in items) i.installment.id,
        ]);
        await settle(tester);

        final barFinder = find.byType(RDHubBatchBar);
        final bar = tester.getRect(
          find.descendant(of: barFinder, matching: find.byType(Material)).first,
        );
        final button = tester.getRect(
          find.descendant(of: barFinder, matching: find.byType(AppButton)),
        );
        final aboveTheButton = (bar.height - AppDimensions.buttonHeightSm) / 2;
        expect(bar.right - button.right, aboveTheButton);
      },
    );
  });

  // The window is tall on purpose. At 2.0x text the header's four full-width tiles fill an
  // 800dp screen, so a phone-sized window would never lay the rows out and the check would
  // pass without looking at them.
  group(
    'Monthly Hub states at 360dp wide: no overflow, labelled 44dp icon buttons',
    () {
      const tallWindow = 3200.0;

      final states =
          <
            ({
              String name,
              DateTime? today,
              Future<void> Function(
                WidgetTester tester,
                ProviderContainer container,
              )
              arrange,
              Finder expects,
              bool hasRows,
            })
          >[
            (
              name: 'selection with a depositable account',
              today: null,
              arrange: (tester, container) async {
                final items = await container.read(
                  monthlyOperationItemsProvider.future,
                );
                container.read(rDHubSelectionProvider.notifier).selectAll([
                  for (final i in items) i.installment.id,
                ]);
              },
              expects: find.byType(RDHubBatchBar),
              hasRows: true,
            ),
            (
              name: 'selection with nothing to deposit',
              today: null,
              arrange: (tester, container) async {
                final items = await container.read(
                  monthlyOperationItemsProvider.future,
                );
                container.read(rDHubSelectionProvider.notifier).selectAll([
                  for (final i
                      in items.where((i) => i.readyForPoCount == 0).take(1))
                    i.installment.id,
                ]);
              },
              expects: find.text(ops.batchPo.noneReady),
              hasRows: true,
            ),
            (
              name: 'another month, ungrouped, a header filter selected',
              today: null,
              arrange: (tester, container) async {
                container.read(rDHubMonthProvider.notifier).nextMonth();
                final filters = container.read(rDHubFiltersProvider.notifier);
                filters.toggleGroupByCustomer(false);
                filters.setStatus(RDMonthlyFilter.toCollect);
              },
              expects: find.text(ops.currentMonth),
              hasRows: true,
            ),
            (
              name: 'overdue accounts in arrears',
              today: DateTime(2026, 12, 20),
              arrange: (tester, container) async {
                container
                    .read(rDHubFiltersProvider.notifier)
                    .setStatus(RDMonthlyFilter.overdue);
              },
              // Every account in arrears has something to collect.
              expects: find.byType(RDOperationActionButton),
              hasRows: true,
            ),
            (
              name: 'no account matches the search',
              today: null,
              arrange: (tester, container) async {
                container
                    .read(rDHubFiltersProvider.notifier)
                    .setSearchQuery('no such account');
              },
              expects: find.text(ops.noFilterResults),
              hasRows: false,
            ),
          ];

      for (final textScale in const [1.0, 1.3, 2.0]) {
        for (final state in states) {
          testWidgets('${state.name} @ ${textScale}x text', (tester) async {
            final container = await pumpHub(
              tester,
              height: tallWindow,
              textScale: textScale,
              today: state.today,
            );
            await state.arrange(tester, container);
            await settle(tester);

            expect(tester.takeException(), isNull);
            expect(state.expects, findsWidgets);
            expect(
              find.byType(RDMonthlyOperationCard),
              state.hasRows ? findsWidgets : findsNothing,
            );

            for (final element in find.byType(IconButton).evaluate()) {
              final widget = element.widget as IconButton;
              final renderBox = element.renderObject as RenderBox?;
              if (renderBox == null || !renderBox.hasSize) continue;
              expect(
                widget.tooltip?.trim().isNotEmpty ?? false,
                isTrue,
                reason: '${state.name}: an IconButton has no tooltip: $widget',
              );
              expect(
                renderBox.size.shortestSide,
                greaterThanOrEqualTo(AppDimensions.minTapTarget),
                reason:
                    '${state.name}: IconButton (${widget.tooltip}) is ${renderBox.size}',
              );
            }
          });
        }
      }
    },
  );
}
