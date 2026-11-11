import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation: three fact tables + one cache table, all under RLS.
///
/// Every stream is a direct realtime subscription on a single table filtered server-side,
/// so a payment on one RD never triggers a refetch for another.
class SupabaseRDLedgerRepository implements RDLedgerRepository {
  SupabaseRDLedgerRepository(this._client);

  final SupabaseClient _client;
  final _localSummaryMutations = StreamController<void>.broadcast();

  static const _transactions = 'rd_transactions';
  static const _poDeposits = 'rd_po_deposits';
  static const _feeAbsorptions = 'rd_fee_absorptions';
  static const _summaries = 'rd_ledger_summary';

  String get _agentId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  // --- Reads ------------------------------------------------------------------------------

  @override
  Stream<Result<List<RDTransaction>, String>> watchTransactions(String rdId) =>
      _client
          .from(_transactions)
          .stream(primaryKey: ['id'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDTransaction.fromJson));

  @override
  Stream<Result<List<RDPoDeposit>, String>> watchPoDeposits(String rdId) =>
      _client
          .from(_poDeposits)
          .stream(primaryKey: ['id'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDPoDeposit.fromJson));

  @override
  Stream<Result<List<RDFeeAbsorption>, String>> watchFeeAbsorptions(String rdId) =>
      _client
          .from(_feeAbsorptions)
          .stream(primaryKey: ['rd_id', 'installment_no'])
          .eq('rd_id', rdId)
          .map((rows) => _mapRows(rows, RDFeeAbsorption.fromJson));

  /// Largest `rd_id IN (...)` list sent in one request (keeps the URL well under limits).
  static const _rdIdChunkSize = 100;

  /// How many id chunks are fetched at the same time.
  static const _chunkConcurrency = 4;

  /// Rows of [table] for [rdIds], read in bounded `IN (...)` chunks and paginated within
  /// each chunk. The cost follows the accounts asked for, not the agent's whole history,
  /// and the same code path serves 3 accounts or 3,000.
  Future<List<T>> _fetchByRdIds<T>({
    required String table,
    required String agentId,
    required List<String> rdIds,
    required List<String> orderBy,
    required T Function(Map<String, dynamic>) fromJson,
    String columns = '*',
  }) async {
    final chunks = <List<String>>[
      for (var i = 0; i < rdIds.length; i += _rdIdChunkSize)
        rdIds.sublist(
          i,
          i + _rdIdChunkSize > rdIds.length ? rdIds.length : i + _rdIdChunkSize,
        ),
    ];
    final rows = <T>[];
    for (var i = 0; i < chunks.length; i += _chunkConcurrency) {
      final wave = chunks.skip(i).take(_chunkConcurrency);
      final results = await Future.wait([
        for (final chunk in wave)
          SupabasePaginatedQuery.fetchAllPages<T>(
            fetchPage: (from, to) {
              var query = _client
                  .from(table)
                  .select(columns)
                  .eq('agent_id', agentId)
                  .inFilter('rd_id', chunk)
                  .order(orderBy.first, ascending: true);
              for (final column in orderBy.skip(1)) {
                query = query.order(column, ascending: true);
              }
              return query.range(from, to);
            },
            fromJson: fromJson,
          ),
      ]);
      for (final result in results) {
        rows.addAll(result);
      }
    }
    return rows;
  }

  @override
  Future<Result<Map<String, RDRawFactsBundle>, String>> fetchRawFactsForRds(
    List<String> rdIds,
  ) async {
    if (rdIds.isEmpty) {
      return const Success(<String, RDRawFactsBundle>{});
    }
    try {
      final agentId = _agentId;
      final ids = rdIds.toSet().toList(growable: false);

      final (transactions, poDeposits, absorptions) = await (
        _fetchByRdIds<RDTransaction>(
          table: _transactions,
          agentId: agentId,
          rdIds: ids,
          orderBy: const ['paid_date', 'id'],
          fromJson: RDTransaction.fromJson,
        ),
        _fetchByRdIds<RDPoDeposit>(
          table: _poDeposits,
          agentId: agentId,
          rdIds: ids,
          orderBy: const ['deposited_on', 'id'],
          fromJson: RDPoDeposit.fromJson,
        ),
        _fetchByRdIds<RDFeeAbsorption>(
          table: _feeAbsorptions,
          agentId: agentId,
          rdIds: ids,
          orderBy: const ['rd_id', 'installment_no'],
          fromJson: RDFeeAbsorption.fromJson,
        ),
      ).wait;

      final txsByRd = <String, List<RDTransaction>>{};
      for (final tx in transactions) {
        (txsByRd[tx.rdId] ??= <RDTransaction>[]).add(tx);
      }
      final posByRd = <String, List<RDPoDeposit>>{};
      for (final po in poDeposits) {
        (posByRd[po.rdId] ??= <RDPoDeposit>[]).add(po);
      }
      final absByRd = <String, List<RDFeeAbsorption>>{};
      for (final abs in absorptions) {
        (absByRd[abs.rdId] ??= <RDFeeAbsorption>[]).add(abs);
      }

      return Success({
        for (final id in ids)
          id: (
            transactions: txsByRd[id] ?? const <RDTransaction>[],
            poDeposits: posByRd[id] ?? const <RDPoDeposit>[],
            absorptions: absByRd[id] ?? const <RDFeeAbsorption>[],
          ),
      });
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }

  @override
  Stream<Result<List<RDLedgerSummary>, String>> watchSummaries() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value(const Success(<RDLedgerSummary>[]));
    }
    final agentId = user.id;
    return SupabasePaginatedQuery.watchPaginatedCollection<RDLedgerSummary>(
      client: _client,
      channelPrefix: 'rd-summaries',
      table: _summaries,
      filterColumn: 'agent_id',
      filterValue: agentId,
      localMutations: _localSummaryMutations.stream,
      fetchAll: () => SupabasePaginatedQuery.fetchAllPages<RDLedgerSummary>(
        fetchPage: (from, to) => _client
            .from(_summaries)
            .select()
            .eq('agent_id', agentId)
            .order('rd_id', ascending: true)
            .range(from, to),
        fromJson: RDLedgerSummary.fromJson,
      ),
    );
  }

  // --- Writes -----------------------------------------------------------------------------

  @override
  Future<Result<void, String>> upsertSummary(RDLedgerSummary summary) =>
      upsertSummaries([summary]);

  @override
  Future<Result<void, String>> upsertSummaries(List<RDLedgerSummary> summaries) =>
      summaries.isEmpty
          ? Future.value(const Success(null))
          : _guard(() async {
              await _client.from(_summaries).upsert(
                [
                  for (final s in summaries)
                    _withAgent(s.toJson()..remove('updated_at')),
                ],
                onConflict: 'rd_id',
              );
              _localSummaryMutations.add(null);
            });

  @override
  Future<Result<void, String>> addTransaction(RDTransaction transaction) =>
      _guard(() => _client.from(_transactions).insert(_transactionRow(transaction)));

  @override
  Future<Result<void, String>> updateTransaction(RDTransaction transaction) =>
      _guard(() => _client
          .from(_transactions)
          .update(_transactionRow(transaction)..remove('id')..remove('rd_id'))
          .eq('id', transaction.id)
          .eq('rd_id', transaction.rdId));

  @override
  Future<Result<void, String>> deleteTransaction({
    required String rdId,
    required String transactionId,
  }) =>
      _guard(() => _client
          .from(_transactions)
          .delete()
          .eq('id', transactionId)
          .eq('rd_id', rdId));

  @override
  Future<Result<void, String>> addPoDeposit(RDPoDeposit event) =>
      addPoDeposits([event]);

  @override
  Future<Result<void, String>> addPoDeposits(List<RDPoDeposit> events) =>
      events.isEmpty
          ? Future.value(const Success(null))
          : _guard(
              () => _client.from(_poDeposits).insert([
                for (final e in events)
                  _withAgent(e.toJson()..remove('created_at')),
              ]),
            );

  @override
  Future<Result<void, String>> deletePoDeposit({
    required String rdId,
    required String eventId,
  }) =>
      _guard(() => _client.from(_poDeposits).delete().eq('id', eventId).eq('rd_id', rdId));

  @override
  Future<Result<List<String>, String>> deletePoDepositBatch(String batchId) async {
    try {
      final agentId = _agentId;
      final batchRows = await SupabasePaginatedQuery.fetchAllRawPages(
        fetchPage: (from, to) => _client
            .from(_poDeposits)
            .select('rd_id')
            .eq('batch_id', batchId)
            .eq('agent_id', agentId)
            .order('id', ascending: true)
            .range(from, to),
      );
      final affectedSet = {
        for (final row in batchRows)
          if (row['rd_id'] is String) row['rd_id'] as String,
      };
      final affectedRdIds = affectedSet.toList(growable: false);
      if (affectedRdIds.isEmpty) return const Success(<String>[]);

      final allDeposits = await _fetchByRdIds<RDPoDeposit>(
        table: _poDeposits,
        agentId: agentId,
        rdIds: affectedRdIds,
        orderBy: const ['deposited_on', 'id'],
        fromJson: RDPoDeposit.fromJson,
      );
      final error = RDLedgerFacts.validateBatchUndo(
        batchId: batchId,
        deposits: allDeposits,
      );
      if (error != null) return Failure(error);

      await _client
          .from(_poDeposits)
          .delete()
          .eq('batch_id', batchId)
          .eq('agent_id', agentId);
      return Success(affectedRdIds);
    } catch (e) {
      return Failure(
        SupabaseErrorMapper.describe(
          e,
          fallback: 'The ledger could not be updated. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void, String>> upsertFeeAbsorption(RDFeeAbsorption absorption) =>
      _guard(() => _client.from(_feeAbsorptions).upsert(
            _withAgent(absorption.toJson()..remove('created_at')),
            onConflict: 'rd_id,installment_no',
          ));

  @override
  Future<Result<void, String>> removeFeeAbsorption({
    required String rdId,
    required int installmentNo,
  }) =>
      _guard(() => _client
          .from(_feeAbsorptions)
          .delete()
          .eq('rd_id', rdId)
          .eq('installment_no', installmentNo));

  // --- Helpers ----------------------------------------------------------------------------

  Map<String, dynamic> _transactionRow(RDTransaction tx) {
    final json = tx.toJson()
      ..remove('created_at')
      ..remove('updated_at');
    // DATE column: strip any time component the generic converter may have produced.
    json['paid_date'] = tx.paidDate.toIso8601String().split('T').first;
    return _withAgent(json);
  }

  Map<String, dynamic> _withAgent(Map<String, dynamic> json) =>
      json..['agent_id'] = _agentId;

  static Result<List<T>, String> _mapRows<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return Success(rows.map(fromJson).toList(growable: false));
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }

  static Future<Result<void, String>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Success(null);
    } catch (e) {
      return Failure(
        SupabaseErrorMapper.describe(
          e,
          fallback: 'The ledger could not be updated. Please try again.',
        ),
      );
    }
  }
}
