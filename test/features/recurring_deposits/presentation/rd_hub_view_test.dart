import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/layout/entity_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_monthly_operation_item.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_capsule.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_header.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_month_progress.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_switcher.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operations_view.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_payment_bottom_sheets.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// The Monthly Hub's controls and states: uniform KPI filters, sort sheet,
/// fixed Serial # order, `#` avatars with hero tags, top-right money column,
/// M3E capsule + pill, unified AppButton Collect / Deposit actions, and Settled rows.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  final source = FakeDataSource();
  final ops = t.recurringDeposits.monthlyOperations;

  const oneAccount = 'Alfred Pennyworth';

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
  }

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

  group('Monthly Hub controls', () {
    testWidgets('due-window group and sort sheet drive the Hub state', (
      tester,
    ) async {
      final container = await pumpHub(tester, height: 3600);
      expect(find.byType(RDMonthlyOperationCard), findsWidgets);
      RDHubFiltersState filters() => container.read(rDHubFiltersProvider);
      final kpis = container.read(monthlyOperationsKpiProvider);
      final firstHalf = ops.toolbar.window15th(count: kpis.firstHalfCount);

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

      await tester.tap(find.text(ops.toolbar.windowAll));
      await settle(tester);
      expect(filters().dueWindow, RDDueWindowFilter.all);

      // Sort sheet switches from default Serial # to Overdue first and resets cleanly.
      expect(filters().sortField, RDHubSortField.serialNo);
      expect(filters().sortDirection, SortDirection.asc);
      await tester.tap(find.byTooltip(ops.toolbar.sort));
      await settle(tester);
      expect(find.text(ops.toolbar.sortByOverdue), findsOneWidget);
      await tester.tap(find.text(ops.toolbar.sortByOverdue));
      await settle(tester);
      expect(filters().sortField, RDHubSortField.overdueFirst);

      await tester.tap(find.text(t.common.clear));
      await settle(tester);
      expect(filters().sortField, RDHubSortField.serialNo);
      expect(filters().sortDirection, SortDirection.asc);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'switching to a settled month shows its statement without the arrival',
      (tester) async {
        await pumpHub(
          tester,
          disableAnimations: false,
          today: DateTime(2026, 6, 20),
        );
        final bar = find.byKey(const ValueKey('bar'));
        final statement = find.byKey(const ValueKey('settled'));
        expect(statement, findsOneWidget);

        await tester.tap(find.byTooltip(ops.nextMonth));
        await settle(tester);
        expect(bar, findsOneWidget);
        expect(statement, findsNothing);

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
      'all four KPI tiles act uniformly as filters and swap colours when selected',
      (tester) async {
        final container = await pumpHub(tester);

        // To collect keeps a calm primaryContainer tile even when overdue rows exist,
        // and its overdue badge retains red overdue styling even while To collect is selected.
        final toCollectTile = find.ancestor(
          of: find.text(ops.kpis.toCollect),
          matching: find.byType(AppGroupTile),
        );
        final scheme = Theme.of(tester.element(toCollectTile)).colorScheme;
        final overduePalette = AppFinancialColors.of(
          tester.element(toCollectTile),
        ).overdue;
        expect(
          tester.widget<AppGroupTile>(toCollectTile).color,
          scheme.primaryContainer,
        );

        final kpis = container.read(monthlyOperationsKpiProvider);
        final badgeText = ops.kpis.overdueBadge(n: kpis.overdueCount);
        final badgeMaterialFinder = find.ancestor(
          of: find.text(badgeText),
          matching: find.byType(Material),
        );
        expect(
          tester.widget<Material>(badgeMaterialFinder.first).color,
          overduePalette.accent,
        );

        await tester.tap(find.text(ops.kpis.toCollect));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.toCollect,
        );
        expect(
          tester.widget<Material>(badgeMaterialFinder.first).color,
          overduePalette.container,
        );
        expect(
          tester.widget<Text>(find.text(badgeText)).style?.color,
          overduePalette.onContainer,
        );

        // Receivable tile swaps colours and filters to receivable.
        final recLabel = ops.kpis.receivable;
        final recTile = find.ancestor(
          of: find.text(recLabel),
          matching: find.byType(AppGroupTile),
        );
        Color? recFill() => tester.widget<AppGroupTile>(recTile).color;
        final palette = AppFinancialColors.of(
          tester.element(recTile),
        ).receivable;

        expect(recFill(), palette.container);
        await tester.tap(find.text(recLabel));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.receivable,
        );
        expect(recFill(), palette.onContainer);

        await tester.tap(find.text(recLabel));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.all,
        );
        expect(recFill(), palette.container);

        // In hand filters to readyForPo; Paid to PO filters to settled.
        final paidToPoTile = find.descendant(
          of: find.byType(RDHubHeader),
          matching: find.text(ops.kpis.paidToPo),
        );
        await tester.tap(find.text(ops.kpis.inHand));
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.readyForPo,
        );

        await tester.tap(paidToPoTile);
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.settled,
        );

        await tester.tap(paidToPoTile);
        await settle(tester);
        expect(
          container.read(rDHubFiltersProvider).status,
          RDMonthlyFilter.all,
        );
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
      'Deposit from pocket via Collect sheet shortcut and row menu opens Deposit sheet',
      (tester) async {
        await pumpHub(tester, height: 3600);
        final cardFinder = find
            .byWidgetPredicate(
              (w) =>
                  w is RDMonthlyOperationCard &&
                  w.item.canDepositFromPocket &&
                  w.onDepositFromPocket != null,
            )
            .first;
        final targetCard = tester.widget<RDMonthlyOperationCard>(cardFinder);
        final customer = targetCard.item.deposit.customerName!;
        final expectedTitle = t.recurringDeposits.ledger.depositTitleFor(
          n: targetCard.item.fromPocketInstallmentCount.toString(),
          customer: customer,
        );

        // Path 1: Collect button -> inline "Not paid yet? Deposit from pocket" shortcut.
        await tester.tap(
          find.descendant(
            of: cardFinder,
            matching: find.text(ops.card.collectShort),
          ),
        );
        await settle(tester);
        final shortcut = find.text(
          t.recurringDeposits.ledger.depositFromPocketShortcut,
        );
        expect(shortcut, findsOneWidget);

        await tester.tap(shortcut);
        await settle(tester);
        expect(find.text(expectedTitle), findsOneWidget);

        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(find.text(expectedTitle), findsNothing);

        // Path 2: accessible row overflow menu.
        await tester.tap(
          find.descendant(
            of: cardFinder,
            matching: find.byTooltip(t.common.moreOptions),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        await tester.tap(find.text(ops.card.depositFromPocket));
        await settle(tester);
        expect(find.text(expectedTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'rows show #serial in avatar with hero tag, Inst N in subtitle, live money & base /mo in top-right, '
      'and Collect / tonal Deposit / Settled actions',
      (tester) async {
        await pumpHub(tester, height: 3600);

        final cards = tester
            .widgetList<RDMonthlyOperationCard>(
              find.byType(RDMonthlyOperationCard),
            )
            .toList();
        expect(cards, isNotEmpty);

        // Fixed Serial # default order keeps #1 (Alfred Pennyworth) first with Hub hero tag.
        expect(cards.first.item.deposit.customerName, oneAccount);
        expect(
          cards.first.heroTag,
          EntityHero.tagFrom(EntityHero.rdHub, cards.first.item.deposit.id),
        );
        expect(
          find.descendant(
            of: find.byType(EntityAvatar),
            matching: find.text(cards.first.item.deposit.avatarLabel),
          ),
          findsWidgets,
        );

        // Unified AppButton Collect + Deposit + 2-step Paid | PO track + clean Settled edge.
        expect(find.text(ops.card.collectShort), findsWidgets);
        expect(find.text(ops.card.deposit), findsWidgets);
        expect(find.text(ops.card.stepPaid), findsWidgets);
        expect(find.text(ops.card.stepPo), findsWidgets);

        final settledCard = cards.firstWhere((c) => c.item.isSettled);
        expect(
          find.descendant(
            of: find.byWidget(settledCard),
            matching: find.byType(AppButton),
          ),
          findsNothing,
        );

        // Top-right money column shows totalOutstanding and base /mo when they differ.
        final overdueWithDiff = cards.firstWhere(
          (c) =>
              c.item.isCustomerPending &&
              c.item.totalOutstanding > c.item.deposit.installmentAmount,
        );
        final cardFinder = find.byWidget(overdueWithDiff);
        expect(
          find.descendant(
            of: cardFinder,
            matching: find.text(
              overdueWithDiff.item.totalOutstanding.toRupeeFormat(),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardFinder,
            matching: find.text(
              ops.card.basePerMonth(
                amount: overdueWithDiff.item.deposit.installmentAmount
                    .toRupeeFormat(),
              ),
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Deposit action is tonal, Collect action is filled', (
      tester,
    ) async {
      await pumpHub(tester, height: 3600);
      final actionButtons = tester
          .widgetList<AppButton>(
            find.descendant(
              of: find.byType(RDOperationActionButton),
              matching: find.byType(AppButton),
            ),
          )
          .toList();
      final deposits = actionButtons
          .where((button) => button.label == ops.card.deposit)
          .toList();
      expect(deposits, isNotEmpty);
      for (final button in deposits) {
        expect(button.variant, AppButtonVariant.tonal, reason: button.label);
      }

      final collects = actionButtons
          .where((button) => button.label == ops.card.collectShort)
          .toList();
      expect(collects, isNotEmpty);
      for (final collect in collects) {
        expect(collect.variant, AppButtonVariant.filled);
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
          ops.kpis.paidToPo,
          ops.kpis.receivable,
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
      expect(tiles[0].top, tiles[1].top);
      expect(tiles[2].top, greaterThan(tiles[0].bottom));
    });
  });

  group('Monthly Hub spacing', () {
    const roomy = 700.0;

    Rect tilesRect(WidgetTester tester) {
      final tiles = [
        for (final label in [
          ops.kpis.toCollect,
          ops.kpis.inHand,
          ops.kpis.paidToPo,
          ops.kpis.receivable,
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
      'the 2-step track aligns cleanly across rows with Collect, Deposit, and Settled',
      (tester) async {
        await pumpHub(tester, width: roomy, height: 3600);

        final leftPositions = <double>[];
        for (final element in find.byType(RDMonthlyOperationCard).evaluate()) {
          final card = find.byWidget(element.widget);
          final capsule = tester.getRect(
            find.descendant(of: card, matching: find.byType(RDHubStageCapsule)),
          );
          leftPositions.add(capsule.left);
        }
        expect(leftPositions, isNotEmpty);
        final sorted = [...leftPositions]..sort();
        expect(sorted.last - sorted.first, lessThanOrEqualTo(1));
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
      const touchPadding =
          (kMinInteractiveDimension - AppDimensions.buttonHeightSm) / 2;

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

    testWidgets('a tile\'s text starts on the edge a row\'s avatar starts on', (
      tester,
    ) async {
      await pumpHub(tester, height: 1600);
      for (final label in [ops.kpis.toCollect, ops.kpis.paidToPo]) {
        expect(
          tester
              .getRect(
                find.descendant(
                  of: find.byType(RDHubHeader),
                  matching: find.text(label),
                ),
              )
              .left,
          2 * AppDimensions.pageMargin,
        );
      }
    });

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
      'sort button uses shared Sorting01 icon and toggles Badge visibility',
      (tester) async {
        final container = await pumpHub(tester);

        Badge sortBadge() => tester.widget<Badge>(
          find.descendant(
            of: find.byTooltip(ops.toolbar.sort),
            matching: find.byType(Badge),
          ),
        );
        final sortIcon = tester.widget<AppIcon>(
          find.descendant(
            of: find.byTooltip(ops.toolbar.sort),
            matching: find.byType(AppIcon),
          ),
        );
        expect(sortIcon.icon, HugeIcons.strokeRoundedSorting01);
        expect(sortBadge().isLabelVisible, isFalse);

        container
            .read(rDHubFiltersProvider.notifier)
            .setSort(RDHubSortField.overdueFirst, SortDirection.asc);
        await settle(tester);
        expect(sortBadge().isLabelVisible, isTrue);
      },
    );

    testWidgets(
      'RDHubStageCapsule renders all 7 tracks with full-opacity muted foreground and scaled icons at 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800) * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      RDHubStageCapsule(
                        key: ValueKey('track_baseline'),
                        track: RDHubBaselineTrack(),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_overdue_1'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerOverdue(months: 1),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_overdue_3'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerOverdue(months: 3),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_due'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerDueToday(),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_upcoming'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerUpcoming(),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_partial'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerPartial(),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_receivable'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerReceivable(),
                          po: RDPoStep.deposited,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_inhand'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerPaid(),
                          po: RDPoStep.pending,
                        ),
                      ),
                      RDHubStageCapsule(
                        key: ValueKey('track_settled'),
                        track: RDHubTwoStepTrack(
                          customer: RDCustomerPaid(),
                          po: RDPoStep.deposited,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        final statuses = t.recurringDeposits.ledger.statuses;
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('track_baseline')),
            matching: find.byType(RDStatusPill),
          ),
          findsOneWidget,
        );
        expect(find.text(statuses.overdue), findsOneWidget);
        expect(find.text(ops.card.lateMonthsShort(n: 3)), findsOneWidget);
        expect(find.text(statuses.dueToday), findsOneWidget);
        expect(find.text(ops.card.partialShort), findsOneWidget);
        expect(find.text(ops.card.stepUnpaid), findsNWidgets(2));
        expect(find.text(ops.card.stepPaid), findsNWidgets(2));

        // Upcoming chip uses full-opacity onSurfaceVariant (never attenuated by 0.7 alpha)
        // and scales its icon with textScaler (12 * 2.0 = 24.0).
        final upcomingFinder = find.byKey(const ValueKey('track_upcoming'));
        final ctx = tester.element(upcomingFinder);
        final upcomingText = tester.widget<Text>(
          find.descendant(
            of: upcomingFinder,
            matching: find.text(ops.card.stepUnpaid),
          ),
        );
        expect(
          upcomingText.style?.color,
          Theme.of(ctx).colorScheme.onSurfaceVariant,
        );

        final upcomingIcon = tester.widget<AppIcon>(
          find
              .descendant(of: upcomingFinder, matching: find.byType(AppIcon))
              .first,
        );
        expect(upcomingIcon.size, AppDimensions.iconXs * 2.0);
      },
    );

    testWidgets(
      'collect sheet with Deposit from pocket shortcut fits 360x800 @ 2.0x text and confirms before discarding modified input',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800) * 2.0;
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
              () => FakeDataSource.defaultReferenceDate,
            ),
            customerRepositoryProvider.overrideWithValue(
              FakeCustomerRepository(customers: source.customers),
            ),
            recurringDepositRepositoryProvider.overrideWithValue(deposits),
            rdLedgerRepositoryProvider.overrideWithValue(ledger),
          ],
        );
        addTearDown(container.dispose);

        RDLogPaymentOutcome? outcome;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () async {
                        outcome = await showRDLogPaymentSheet(
                          context,
                          rdId: source.recurringDeposits.first.id,
                          initialAmount: 1000,
                          showDepositFromPocketShortcut: true,
                        );
                      },
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
        expect(tester.takeException(), isNull);

        // Modify the amount so hasUnsavedInput becomes true, then tap Deposit from pocket shortcut.
        await tester.enterText(find.byType(TextFormField).first, '2500');
        await tester.pump();
        await tester.tap(
          find.text(t.recurringDeposits.ledger.depositFromPocketShortcut),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(t.recurringDeposits.ledger.discardChangesTitle),
          findsOneWidget,
        );
        await tester.tap(find.text(t.recurringDeposits.ledger.discard));
        await tester.pumpAndSettle();
        expect(outcome, RDLogPaymentOutcome.depositFromPocket);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'collectedPendingPo row announces its readyForPoAmount in TalkBack semantics instead of settled',
      (tester) async {
        await pumpHub(tester, height: 3600);
        final cards = tester
            .widgetList<RDMonthlyOperationCard>(
              find.byType(RDMonthlyOperationCard),
            )
            .toList();
        final inHandCard = cards.firstWhere(
          (c) =>
              c.item.displayStatus(FakeDataSource.defaultReferenceDate) ==
              RDInstallmentDisplayStatus.collectedPendingPo,
        );
        final rowSemantics = tester.getSemantics(find.byWidget(inHandCard));
        expect(
          rowSemantics.label,
          contains(inHandCard.item.readyForPoAmount.toRupeeFormat()),
        );
      },
    );
  });

  group(
    'Monthly Hub states at 360dp wide: no overflow, labelled 44dp icon buttons',
    () {
      const tallWindow = 3600.0;

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
              name: 'default serial order with mixed states',
              today: null,
              arrange: (tester, container) async {},
              expects: find.byType(RDMonthlyOperationCard),
              hasRows: true,
            ),
            (
              name: 'another month, Paid to PO filter selected',
              today: null,
              arrange: (tester, container) async {
                container.read(rDHubMonthProvider.notifier).previousMonth();
                container
                    .read(rDHubFiltersProvider.notifier)
                    .setStatus(RDMonthlyFilter.settled);
              },
              expects: find.text(ops.currentMonth),
              hasRows: true,
            ),
            (
              name: 'overdue accounts sorted by Overdue first',
              today: DateTime(2026, 12, 20),
              arrange: (tester, container) async {
                final filters = container.read(rDHubFiltersProvider.notifier);
                filters.setSort(RDHubSortField.overdueFirst, SortDirection.asc);
                filters.setStatus(RDMonthlyFilter.toCollect);
              },
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
