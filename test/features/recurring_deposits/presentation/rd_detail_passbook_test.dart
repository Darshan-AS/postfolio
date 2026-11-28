import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_projection.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_hub_capsule.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_tile.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_month_inspector_card.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_next_due_line.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_passbook_po_strip.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_status_pill.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_transactions_section.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  final today = DateTime(2026, 4, 20);
  final rd = RecurringDeposit(
    id: 'rd-detail-1',
    customerId: 'cust-1',
    customerName: 'Bruce Wayne',
    serialNo: '10',
    accountNo: '1002030405',
    schemeType: RecurringSchemeType.recurringDeposit,
    status: DepositStatus.active,
    installmentAmount: 1000,
    interestRate: 6.7,
    termYears: 5,
    termMonths: 0,
    startDate: DateTime(2026, 1, 5),
  );

  RDInstallment openInst() => RDInstallment(
    id: 'inst-4',
    rdId: rd.id,
    installmentNo: 4,
    installmentDate: DateTime(2026, 4, 1),
    dueDate: DateTime(2026, 4, 15),
    installmentAmount: 1000,
    lateFee: 10,
  );

  group('RDPassbookNextDueLine', () {
    testWidgets(
      'shows Amber "All months collected" banner when nextDue is null and hasReadyForPo is true, and Green settled banner when false',
      (tester) async {
        final passbook = t.recurringDeposits.ledger.passbook;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  RDPassbookNextDueLine(
                    key: const ValueKey('inhand_banner'),
                    nextDue: null,
                    now: today,
                    isBusy: false,
                    hasReadyForPo: true,
                    onCollect: () {},
                  ),
                  RDPassbookNextDueLine(
                    key: const ValueKey('settled_banner'),
                    nextDue: null,
                    now: today,
                    isBusy: false,
                    hasReadyForPo: false,
                    onCollect: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text(passbook.allCollected), findsOneWidget);
        expect(find.text(passbook.allCollectedHint), findsOneWidget);
        expect(find.text(passbook.allSettled), findsOneWidget);

        final inHandMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('inhand_banner')),
                matching: find.byType(Material),
              )
              .first,
        );
        final settledMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('settled_banner')),
                matching: find.byType(Material),
              )
              .first,
        );
        final financial = AppFinancialColors.light;
        expect(inHandMaterial.color, financial.inHand.container);
        expect(settledMaterial.color, financial.settled.container);
      },
    );

    testWidgets(
      'displays collectAmount and totalOwedNote when multi-month total differs from single month outstanding',
      (tester) async {
        final passbook = t.recurringDeposits.ledger.passbook;
        final inst = openInst();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: RDPassbookNextDueLine(
                nextDue: inst,
                now: today,
                isBusy: false,
                collectAmount: 3030,
                onCollect: () {},
              ),
            ),
          ),
        );

        expect(find.text(3030.0.toRupeeFormat()), findsOneWidget);
        expect(
          find.text(
            passbook.totalOwedNote(
              month: '4',
              amount: inst.outstandingAmount.toRupeeFormat(),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${passbook.toCollectLabel} · ${passbook.nextDueLine(month: '4', date: '15 Apr')}',
          ),
          findsOneWidget,
        );
        final collectButton = tester.widget<AppButton>(
          find.ancestor(
            of: find.text(passbook.collect),
            matching: find.byType(AppButton),
          ),
        );
        expect(collectButton.variant, AppButtonVariant.filled);
        expect(collectButton.icon, isNull);
        expect(find.byType(RDStatusPill), findsNothing);
      },
    );
  });

  group('RDPassbookPoStrip', () {
    testWidgets(
      'shows In hand 2-line copy and tonal Deposit when ready, and hides Deposit when nothing ready',
      (tester) async {
        final passbook = t.recurringDeposits.ledger.passbook;

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    RDPassbookPoStrip(
                      key: const Key('po-ready'),
                      rdId: rd.id,
                      readiness: const RDPoReadiness(
                        readyCount: 2,
                        readyAmount: 2020,
                        readyFee: 20,
                        nextInstallmentNo: 1,
                      ),
                      latestPoDeposit: null,
                      canDepositFromPocket: true,
                      isBusy: false,
                    ),
                    RDPassbookPoStrip(
                      key: const Key('po-empty'),
                      rdId: rd.id,
                      readiness: const RDPoReadiness(),
                      latestPoDeposit: null,
                      canDepositFromPocket: true,
                      isBusy: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text(passbook.inHandTitle(n: 2)), findsOneWidget);
        expect(
          find.text(
            passbook.inHandSubtitleWithFee(
              amount: 2020.0.toRupeeFormat(),
              fee: 20.0.toRupeeFormat(),
            ),
          ),
          findsOneWidget,
        );

        final readyDepositButton = find.descendant(
          of: find.byKey(const Key('po-ready')),
          matching: find.ancestor(
            of: find.text(passbook.deposit),
            matching: find.byType(AppButton),
          ),
        );
        expect(readyDepositButton, findsOneWidget);
        expect(
          tester.widget<AppButton>(readyDepositButton).variant,
          AppButtonVariant.tonal,
        );

        expect(find.text(passbook.nothingReady), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('po-empty')),
            matching: find.text(passbook.deposit),
          ),
          findsNothing,
        );
      },
    );
  });

  group('RDInstallmentTile', () {
    testWidgets(
      'renders 2-step RDHubStageCapsule without RDStatusPill and shows left accent only for active states',
      (tester) async {
        final passbook = t.recurringDeposits.ledger.passbook;
        final overdueInst = openInst();
        final upcomingInst = RDInstallment(
          id: 'inst-5',
          rdId: rd.id,
          installmentNo: 5,
          installmentDate: DateTime(2026, 5, 1),
          dueDate: DateTime(2026, 5, 15),
          installmentAmount: 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  RDInstallmentTile(
                    key: const Key('tile-overdue'),
                    installment: overdueInst,
                    now: today,
                  ),
                  RDInstallmentTile(
                    key: const Key('tile-upcoming'),
                    installment: upcomingInst,
                    now: today,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(RDHubStageCapsule), findsNWidgets(2));
        expect(find.byType(RDStatusPill), findsNothing);
        expect(find.text(passbook.dueOn(date: '15 Apr')), findsOneWidget);
        expect(find.text(passbook.dueOn(date: '15 May')), findsOneWidget);

        final overdueStripe = tester.widget<PositionedDirectional>(
          find.descendant(
            of: find.byKey(const Key('tile-overdue')),
            matching: find.byType(PositionedDirectional),
          ),
        );
        expect(overdueStripe.width, AppDimensions.borderLg);

        expect(
          find.descendant(
            of: find.byKey(const Key('tile-upcoming')),
            matching: find.byType(PositionedDirectional),
          ),
          findsNothing,
        );
      },
    );
  });

  group('RDMonthInspectorSheet & RDTransactionsSection', () {
    testWidgets(
      'inspector uses 2-step RDHubStageCapsule, omits Not provided placeholders, and uses tonal absorb fee CTA',
      (tester) async {
        final ledgerRepo = FakeRDLedgerRepository(
          transactions: {
            rd.id: [
              RDTransaction(
                id: 'tx-1',
                rdId: rd.id,
                amount: 1000,
                paidDate: DateTime(2026, 2, 20),
                paymentMode: RDPaymentMode.cash,
              ),
            ],
          },
          poDeposits: {
            rd.id: [
              RDPoDeposit(
                id: 'po-1',
                rdId: rd.id,
                depositedOn: DateTime(2026, 4, 20),
                installmentCount: 1,
                feePaid: 30,
                amount: 1030,
              ),
            ],
          },
        );
        addTearDown(ledgerRepo.dispose);

        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(() => today),
            recurringDepositRepositoryProvider.overrideWithValue(
              FakeRecurringDepositRepository(deposits: [rd]),
            ),
            rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RDMonthInspectorSheet(
                    rdId: rd.id,
                    installmentNo: 1,
                    onCollect: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RDHubStageCapsule), findsOneWidget);
        expect(find.byType(RDStatusPill), findsNothing);
        expect(find.text(t.common.notProvided), findsNothing);

        final absorbButton = tester.widget<AppButton>(
          find.ancestor(
            of: find.textContaining('Absorb remaining fee'),
            matching: find.byType(AppButton),
          ),
        );
        expect(absorbButton.variant, AppButtonVariant.tonal);
      },
    );

    testWidgets('embedded Transactions Collect CTA uses filled AppButton', (
      tester,
    ) async {
      final ledgerRepo = FakeRDLedgerRepository(
        transactions: {
          rd.id: [
            RDTransaction(
              id: 'tx-1',
              rdId: rd.id,
              amount: 1000,
              paidDate: DateTime(2026, 1, 10),
              paymentMode: RDPaymentMode.cash,
            ),
          ],
        },
      );
      addTearDown(ledgerRepo.dispose);

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => today),
          recurringDepositRepositoryProvider.overrideWithValue(
            FakeRecurringDepositRepository(deposits: [rd]),
          ),
          rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: RDTransactionsSection(deposit: rd, isEmbeddedTab: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final collectButton = tester.widget<AppButton>(
        find.ancestor(
          of: find.text(t.recurringDeposits.ledger.passbook.collect),
          matching: find.byType(AppButton),
        ),
      );
      expect(collectButton.variant, AppButtonVariant.filled);
      expect(collectButton.icon, isNull);
    });

    testWidgets(
      'segments Payments and PO Deposits, groups visits newest-first with Inst range, shows from-pocket chip and Undo only on latest, without overflow at 2.0x text scale',
      (tester) async {
        final passbook = t.recurringDeposits.ledger.passbook;
        final ledgerRepo = FakeRDLedgerRepository(
          transactions: {
            rd.id: [
              RDTransaction(
                id: 'tx-1',
                rdId: rd.id,
                amount: 1000,
                paidDate: DateTime(2026, 1, 10),
                paymentMode: RDPaymentMode.cash,
              ),
            ],
          },
          poDeposits: {
            rd.id: [
              RDPoDeposit(
                id: 'po-1',
                rdId: rd.id,
                depositedOn: DateTime(2025, 12, 15),
                installmentCount: 1,
                feePaid: 0,
                amount: 1000,
              ),
              RDPoDeposit(
                id: 'po-2',
                rdId: rd.id,
                depositedOn: DateTime(2026, 2, 18),
                installmentCount: 2,
                feePaid: 20,
                amount: 2020,
              ),
            ],
          },
        );
        addTearDown(ledgerRepo.dispose);

        final oldRd = rd.copyWith(startDate: DateTime(2025, 12, 5));
        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(() => today),
            recurringDepositRepositoryProvider.overrideWithValue(
              FakeRecurringDepositRepository(deposits: [oldRd]),
            ),
            rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
          ],
        );
        addTearDown(container.dispose);

        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: RDTransactionsSection(
                      deposit: oldRd,
                      isEmbeddedTab: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppButtonGroup<RDTransactionsTab>), findsOneWidget);
        expect(find.text(passbook.paymentsSegment(count: '1')), findsOneWidget);
        expect(
          find.text(passbook.poDepositsSegment(count: '2')),
          findsOneWidget,
        );
        expect(find.byType(RDTransactionTile), findsOneWidget);

        await tester.tap(find.text(passbook.poDepositsSegment(count: '2')));
        await tester.pumpAndSettle();

        expect(find.byType(RDTransactionTile), findsNothing);
        expect(find.text('2026'), findsOneWidget);
        expect(find.text('2025'), findsOneWidget);
        expect(
          find.text(passbook.poDepositTitle(amount: 2020.0.toRupeeFormat())),
          findsOneWidget,
        );
        expect(find.textContaining('Inst 2–3'), findsOneWidget);
        expect(find.textContaining('Inst 1'), findsOneWidget);
        expect(
          find.text(passbook.poDepositFromPocketCount(count: '2')),
          findsOneWidget,
        );
        expect(
          find.text(t.recurringDeposits.ledger.actions.undo),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
