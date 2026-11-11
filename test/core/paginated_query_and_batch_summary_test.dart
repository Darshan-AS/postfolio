import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_ledger_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SupabasePaginatedQuery.fetchAllPages (>1,000-row pagination)', () {
    final cases = <({String name, int totalRows, int pageSize, int expectedCalls})>[
      (name: 'empty result set (0 rows)', totalRows: 0, pageSize: 500, expectedCalls: 1),
      (
        name: 'exact single-page boundary (500 rows -> 500 + 0)',
        totalRows: 500,
        pageSize: 500,
        expectedCalls: 2,
      ),
      (
        name: '>1,000 rows stitched across 3 pages (1,250 rows @ 500/page)',
        totalRows: 1250,
        pageSize: 500,
        expectedCalls: 3,
      ),
    ];

    for (final c in cases) {
      test(c.name, () async {
        final serverRows = List.generate(
          c.totalRows,
          (i) => <String, dynamic>{'id': 'row-$i', 'seq': i},
        );
        final recordedRanges = <(int, int)>[];

        final fetched = await SupabasePaginatedQuery.fetchAllPages<int>(
          pageSize: c.pageSize,
          fetchPage: (from, to) async {
            recordedRanges.add((from, to));
            if (from >= serverRows.length) return const [];
            final end = (to + 1).clamp(0, serverRows.length);
            return serverRows.sublist(from, end);
          },
          fromJson: (json) => json['seq'] as int,
        );

        expect(recordedRanges.length, c.expectedCalls);
        expect(fetched.length, c.totalRows);
        expect(fetched, List.generate(c.totalRows, (i) => i));
      });
    }

    test('propagates page fetch errors cleanly to caller', () async {
      await expectLater(
        SupabasePaginatedQuery.fetchAllRawPages(
          pageSize: 100,
          fetchPage: (from, to) async {
            if (from == 0) {
              return List.generate(100, (i) => <String, dynamic>{'id': '$i'});
            }
            throw StateError('Simulated network drop on page 2');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Batch ensureSummaries & rebuildSummaries (O(1) batch reads + upserts)', () {
    test('backfills and rebuilds 25 RD summaries in 1 batch read + 1 bulk upsert', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository(
        initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
      );
      addTearDown(authRepo.dispose);

      final deposits = <RecurringDeposit>[];
      final txByRd = <String, List<RDTransaction>>{};
      final poByRd = <String, List<RDPoDeposit>>{};

      for (var i = 1; i <= 25; i++) {
        final rdId = 'rd-batch-$i';
        final created = RecurringDeposit.create(
          id: rdId,
          serialNo: '$i',
          accountNo: 'RD-00$i',
          installmentAmount: 1000,
          customerId: 'cust-1',
          schemeType: RecurringSchemeType.recurringDeposit,
          startDate: DateTime(2026, 1, 10),
        );
        deposits.add((created as Success<RecurringDeposit, String>).value);
        txByRd[rdId] = [
          RDTransaction(
            id: 'tx-$i',
            rdId: rdId,
            paidDate: DateTime(2026, 1, 10),
            amount: 1000,
            paymentMode: RDPaymentMode.cash,
          ),
        ];
        if (i.isEven) {
          poByRd[rdId] = [
            RDPoDeposit(
              id: 'po-$i',
              rdId: rdId,
              depositedOn: DateTime(2026, 1, 12),
              installmentCount: 1,
              feePaid: 0,
              amount: 1000,
            ),
          ];
        }
      }

      final fakeRdRepo = FakeRecurringDepositRepository(deposits: deposits);
      addTearDown(fakeRdRepo.dispose);
      final fakeLedgerRepo = FakeRDLedgerRepository(
        transactions: txByRd,
        poDeposits: poByRd,
      );
      addTearDown(fakeLedgerRepo.dispose);

      final fakeCustRepo = FakeCustomerRepository(delay: Duration.zero);
      addTearDown(fakeCustRepo.dispose);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 2, 5)),
          authRepositoryProvider.overrideWithValue(authRepo),
          customerRepositoryProvider.overrideWithValue(fakeCustRepo),
          recurringDepositRepositoryProvider.overrideWithValue(fakeRdRepo),
          rdLedgerRepositoryProvider.overrideWithValue(fakeLedgerRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(monthlyOperationItemsProvider, (_, _) {});
      container.listen(rdLedgerSummariesProvider, (_, _) {});
      await container.read(monthlyOperationItemsProvider.future);

      await container.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();

      expect(fakeLedgerRepo.batchFactFetchCount, 1);
      expect(fakeLedgerRepo.upsertSummariesCallCount, 1);
      expect(fakeLedgerRepo.summaryOf('rd-batch-1')?.cashInHandCash, 1000);
      expect(fakeLedgerRepo.summaryOf('rd-batch-2')?.depositedThroughNo, 1);
      expect(fakeLedgerRepo.summaryOf('rd-batch-25')?.paidThroughNo, 1);

      // Calling ensureSummaries() again when all 25 summaries exist should do 0 work.
      await container.read(rDMonthlyOperationsActionsProvider.notifier).ensureSummaries();
      expect(fakeLedgerRepo.batchFactFetchCount, 1);
      expect(fakeLedgerRepo.upsertSummariesCallCount, 1);

      // Pull-to-refresh (rebuildAll: true) performs exactly 1 more batch fetch + 1 bulk upsert.
      await container
          .read(rDMonthlyOperationsActionsProvider.notifier)
          .ensureSummaries(rebuildAll: true);
      expect(fakeLedgerRepo.batchFactFetchCount, 2);
      expect(fakeLedgerRepo.upsertSummariesCallCount, 2);
    });
  });

  group('Client UUIDv7 generation (RFC 9562 time-ordered IDs)', () {
    bool isUuidV7(String id) {
      final parts = id.split('-');
      return parts.length == 5 && parts[2].startsWith('7');
    }

    test('Customers, OTDs, RDs, payments, and PO deposits generate v7 UUIDs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository(
        initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
      );
      addTearDown(authRepo.dispose);

      final custRepo = FakeCustomerRepository(customers: const [], delay: Duration.zero);
      addTearDown(custRepo.dispose);
      final otdRepo = FakeOneTimeDepositRepository(deposits: const [], delay: Duration.zero);
      addTearDown(otdRepo.dispose);
      final rdRepo = FakeRecurringDepositRepository(deposits: const []);
      addTearDown(rdRepo.dispose);
      final ledgerRepo = FakeRDLedgerRepository();
      addTearDown(ledgerRepo.dispose);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
          authRepositoryProvider.overrideWithValue(authRepo),
          customerRepositoryProvider.overrideWithValue(custRepo),
          oneTimeDepositRepositoryProvider.overrideWithValue(otdRepo),
          recurringDepositRepositoryProvider.overrideWithValue(rdRepo),
          rdLedgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(customersControllerProvider, (_, _) {});
      container.listen(oneTimeDepositsControllerProvider, (_, _) {});
      container.listen(recurringDepositsControllerProvider, (_, _) {});

      expect(
        await container.read(customersControllerProvider.notifier).saveCustomer(
              name: 'Vikram Rao',
              phone: '9876543210',
            ),
        isA<Success<void, String>>(),
      );
      final custId =
          ((await custRepo.watchCustomers().first) as Success<List<dynamic>, String>)
              .value
              .single
              .id as String;
      expect(isUuidV7(custId), isTrue, reason: 'Customer ID was not UUIDv7: $custId');

      expect(
        await container.read(oneTimeDepositsControllerProvider.notifier).saveOneTimeDeposit(
              principalAmount: '50000',
              customerId: custId,
              schemeType: OneTimeSchemeType.timeDeposit,
              termYears: 5,
              startDate: DateTime(2026, 4, 1),
            ),
        isA<Success<void, String>>(),
      );
      final otdId =
          ((await otdRepo.watchOneTimeDeposits().first) as Success<List<dynamic>, String>)
              .value
              .single
              .id as String;
      expect(isUuidV7(otdId), isTrue, reason: 'OTD ID was not UUIDv7: $otdId');

      expect(
        await container.read(recurringDepositsControllerProvider.notifier).saveRecurringDeposit(
              installmentAmount: '2000',
              customerId: custId,
              schemeType: RecurringSchemeType.recurringDeposit,
              startDate: DateTime(2026, 4, 1),
            ),
        isA<Success<void, String>>(),
      );
      final rdId = rdRepo.deposits.single.id;
      expect(isUuidV7(rdId), isTrue, reason: 'RD ID was not UUIDv7: $rdId');

      final ledger = container.read(rDLedgerControllerProvider.notifier);
      expect(
        await ledger.recordPayment((
          rdId: rdId,
          transactionId: null,
          amount: 2000,
          paidDate: DateTime(2026, 4, 10),
          paymentMode: RDPaymentMode.cash,
        )),
        isA<Success<void, String>>(),
      );
      final txId = ledgerRepo.transactionsOf(rdId).single.id;
      expect(isUuidV7(txId), isTrue, reason: 'Transaction ID was not UUIDv7: $txId');

      expect(
        await ledger.depositNextToPo(rdId: rdId, count: 1, depositedOn: DateTime(2026, 4, 12)),
        isA<Success<void, String>>(),
      );
      final poId = ledgerRepo.poDepositsOf(rdId).single.id;
      expect(isUuidV7(poId), isTrue, reason: 'PO deposit ID was not UUIDv7: $poId');
    });
  });

  group('SupabasePaginatedQuery.watchDebouncedCollection concurrency & error handling', () {
    test('coalesces burst invalidations, queues mid-flight refetch, maps errors, and disposes',
        () async {
      final triggers = StreamController<void>.broadcast();
      addTearDown(triggers.close);
      var callCount = 0;
      var disposedCount = 0;
      var throwNext = false;
      Completer<List<int>>? slowGate;

      final emitted = <Result<List<int>, String>>[];
      final sub = SupabasePaginatedQuery.watchDebouncedCollection<int>(
        invalidations: triggers.stream,
        debounce: const Duration(milliseconds: 15),
        onDispose: () async {
          disposedCount++;
        },
        fetchAll: () async {
          final seq = ++callCount;
          if (throwNext) {
            throwNext = false;
            throw StateError('Transient gateway timeout');
          }
          if (slowGate case final gate?) {
            return gate.future;
          }
          return [seq];
        },
      ).listen(emitted.add);

      // 1. Initial immediate load on listen.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(callCount, 1);
      expect(emitted.single, isA<Success<List<int>, String>>());

      // 2. Burst of 5 invalidations within 15ms coalesces into 1 reload.
      for (var i = 0; i < 5; i++) {
        triggers.add(null);
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(callCount, 2);
      expect(emitted.length, 2);

      // 3. Invalidation arriving while fetch #3 is mid-flight queues exactly 1 follow-up (#4).
      slowGate = Completer<List<int>>();
      triggers.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(callCount, 3);
      // Fire another invalidation while #3 is still awaiting slowGate!
      triggers.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(callCount, 3, reason: 'Must not overlap in-flight fetch');
      final gate = slowGate;
      slowGate = null;
      gate.complete(const [3]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(callCount, 4);
      expect((emitted.last as Success<List<int>, String>).value, [4]);

      // 4. Error maps cleanly to Failure without closing stream.
      throwNext = true;
      triggers.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(emitted.last, isA<Failure<List<int>, String>>());

      // 5. Cancel invokes onDispose cleanly.
      await sub.cancel();
      expect(disposedCount, 1);
    });
  });

  group('Stage 5 Demo Mode & Repository Delete-Protection Parity', () {
    test('blocks deleting Customers with deposits or RDs with ledger facts until unlinked',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository();
      addTearDown(authRepo.dispose);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(demoModeProvider.notifier).enable();
      container.listen(customerRepositoryProvider, (_, _) {});
      container.listen(oneTimeDepositRepositoryProvider, (_, _) {});
      container.listen(recurringDepositRepositoryProvider, (_, _) {});
      container.listen(rdLedgerRepositoryProvider, (_, _) {});

      final custRepo = container.read(customerRepositoryProvider);
      final otdRepo = container.read(oneTimeDepositRepositoryProvider);
      final rdRepo = container.read(recurringDepositRepositoryProvider);

      final customers =
          ((await custRepo.watchCustomers().first) as Success<List<dynamic>, String>).value;
      final firstCustId = customers.first.id as String;

      // Customer with demo OTD/RD accounts cannot be deleted.
      final blockedCust = await custRepo.deleteCustomer(firstCustId);
      expect(blockedCust, isA<Failure<void, String>>());

      // RD with demo transactions cannot be deleted, while an empty RD can be deleted.
      final rds =
          ((await rdRepo.watchRecurringDeposits().first) as Success<List<dynamic>, String>).value;
      final rdWithFactsId = rds.first.id as String;
      expect(await rdRepo.deleteRecurringDeposit(rdWithFactsId), isA<Failure<void, String>>());

      final freshRd = (RecurringDeposit.create(
        id: '',
        accountNo: 'RD-TEMP-99',
        installmentAmount: 500,
        customerId: firstCustId,
        schemeType: RecurringSchemeType.recurringDeposit,
        startDate: DateTime(2026, 3, 1),
      ) as Success<RecurringDeposit, String>)
          .value;
      expect(await rdRepo.saveRecurringDeposit(freshRd), isA<Success<void, String>>());
      final createdRdId =
          (rdRepo as FakeRecurringDepositRepository).deposits.last.id;
      expect(await rdRepo.deleteRecurringDeposit(createdRdId), isA<Success<void, String>>());
      expect(
        await rdRepo.watchRecurringDepositById(createdRdId).first,
        isA<Failure<RecurringDeposit, String>>(),
      );

      // Deleting an OTD succeeds and updates single-entity watcher to Failure.
      final otdId = (otdRepo as FakeOneTimeDepositRepository).deposits.first.id;
      expect(await otdRepo.deleteOneTimeDeposit(otdId), isA<Success<void, String>>());
      expect(
        await otdRepo.watchOneTimeDepositById(otdId).first,
        isA<Failure<dynamic, String>>(),
      );
    });
  });
}
