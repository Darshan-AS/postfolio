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
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_batch_bar.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
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

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Pumps the Hub in a 360dp-wide window. The demo ledger is paid up to 27 Oct 2026, so
  /// the default date shows a settled month and a date after that shows overdue accounts.
  Future<ProviderContainer> pumpHub(
    WidgetTester tester, {
    double height = 800,
    double textScale = 1.0,
    bool disableAnimations = true,
    DateTime? today,
  }) async {
    tester.view.physicalSize = Size(360, height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ledger = FakeRDLedgerRepository(
      transactions: source.rdTransactions,
      poDeposits: source.rdPoDeposits,
    );
    final deposits = FakeRecurringDepositRepository(
      deposits: source.recurringDeposits,
    );
    addTearDown(ledger.dispose);
    addTearDown(deposits.dispose);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => today ?? DateTime(2026, 4, 20)),
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

  group('Monthly Hub controls', () {
    testWidgets(
      'due-window group, group-by and select toggles drive the Hub state',
      (tester) async {
        final container = await pumpHub(tester);
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
        expect(find.text(ops.customerGroup.selectGroup), findsWidgets);
        await tester.tap(find.byTooltip(ops.toolbar.groupByCustomer));
        await settle(tester);
        expect(filters().groupByCustomer, isFalse);
        expect(find.text(ops.customerGroup.selectGroup), findsNothing);
        expect(find.byType(RDMonthlyOperationCard), findsWidgets);

        await tester.tap(find.byTooltip(ops.toolbar.selectMode));
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).isSelectionMode, isTrue);
        expect(find.byType(Checkbox), findsWidgets);

        await tester.tap(find.byTooltip(ops.toolbar.exitSelectMode));
        await settle(tester);
        expect(container.read(rDHubSelectionProvider).isSelectionMode, isFalse);
        expect(find.byType(Checkbox), findsNothing);
        expect(tester.takeException(), isNull);
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
        final container = await pumpHub(tester, disableAnimations: false);
        await tester.pumpAndSettle();
        expect(find.byType(RDHubBatchBar), findsNothing);

        final selectAll = find.text(ops.customerGroup.selectGroup);
        await tester.tap(selectAll.at(0));
        await tester.pumpAndSettle();
        await tester.tap(selectAll.at(1));
        await tester.pumpAndSettle();

        final selection = container.read(rDHubSelectionProvider);
        expect(selection.isSelectionMode, isTrue);
        expect(selection.count, 2);

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

        expect(month(), DateTime(2026, 4));
        expect(find.text(ops.currentMonth), findsNothing);

        await tester.tap(find.byTooltip(ops.nextMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 5));
        expect(find.text(ops.currentMonth), findsOneWidget);

        await tester.tap(find.text(ops.currentMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 4));
        expect(find.text(ops.currentMonth), findsNothing);

        await tester.tap(find.byTooltip(ops.previousMonth));
        await settle(tester);
        expect(month(), DateTime(2026, 3));

        await tester.tap(find.byTooltip(ops.toolbar.pickMonth));
        await settle(tester);
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
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
              expects: find.textContaining(RegExp(r'^owes ₹')),
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
