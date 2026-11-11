import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_change.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_summary.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation: three fact tables + one cache table, all under RLS.
///
/// Per-account fact streams are realtime subscriptions filtered server-side, so a payment on
/// one RD never triggers a refetch for another. Every fact write goes through one database
/// function ([applyChange]).
class SupabaseRDLedgerRepository implements RDLedgerRepository {
  SupabaseRDLedgerRepository(this._client);

  final SupabaseClient _client;

  /// Summaries this client has just stored. [watchSummaries] expects Realtime to deliver
  /// them and loads the list itself if it does not.
  final _localSummaryWrites = StreamController<List<RDLedgerSummary>>.broadcast();

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
    // One row per account, kept current from Realtime rows: a payment on one account must
    // not reload every account's summary.
    return SupabasePaginatedQuery.watchKeyedTable<RDLedgerSummary>(
      client: _client,
      channelPrefix: 'rd-summaries',
      table: _summaries,
      filterColumn: 'agent_id',
      filterValue: agentId,
      fetchPage: (from, to) => _client
          .from(_summaries)
          .select()
          .eq('agent_id', agentId)
          .order('rd_id', ascending: true)
          .range(from, to),
      fromJson: RDLedgerSummary.fromJson,
      keyColumn: 'rd_id',
      keyOf: (summary) => summary.rdId,
      writes: _localSummaryWrites.stream,
      // The server stamps `updated_at`; everything else is what was sent.
      shows: (held, written) =>
          held.copyWith(updatedAt: null) == written.copyWith(updatedAt: null),
    );
  }

  @override
  Future<Result<List<RDPoDeposit>, String>> fetchPoDepositsByBatch(String batchId) async {
    try {
      final agentId = _agentId;
      final events = await SupabasePaginatedQuery.fetchAllPages<RDPoDeposit>(
        fetchPage: (from, to) => _client
            .from(_poDeposits)
            .select()
            .eq('batch_id', batchId)
            .eq('agent_id', agentId)
            .order('id', ascending: true)
            .range(from, to),
        fromJson: RDPoDeposit.fromJson,
      );
      return Success(events);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }

  // --- Writes -----------------------------------------------------------------------------

  @override
  Future<Result<void, String>> upsertSummaries(List<RDLedgerSummary> summaries) =>
      summaries.isEmpty
          ? Future.value(const Success(null))
          : _guard(() async {
              await _client.from(_summaries).upsert(
                [
                  for (final s in summaries) _summaryRow(s)..['agent_id'] = _agentId,
                ],
                onConflict: 'rd_id',
              );
              _localSummaryWrites.add(summaries);
            });

  /// One request, one database transaction (`public.apply_rd_ledger_change`): the facts in
  /// [change] and the [summaries] projected from them are stored together or not at all.
  /// The function runs with the caller's privileges, so row-level security applies to every
  /// statement, and it stamps `agent_id` from the session rather than trusting the payload.
  @override
  Future<Result<void, String>> applyChange(
    RDLedgerChange change, {
    List<RDLedgerSummary> summaries = const [],
  }) {
    if (change.isEmpty && summaries.isEmpty) {
      return Future.value(const Success(null));
    }
    return _guard(() async {
      await _client.rpc(
        'apply_rd_ledger_change',
        params: {
          'p_upsert_transactions': [
            for (final t in change.upsertTransactions) _transactionRow(t),
          ],
          'p_delete_transaction_ids': [
            for (final d in change.deleteTransactions) d.transactionId,
          ],
          'p_insert_po_deposits': [
            for (final e in change.insertPoDeposits) e.toJson()..remove('created_at'),
          ],
          'p_delete_po_deposit_ids': [
            for (final d in change.deletePoDeposits) d.eventId,
          ],
          'p_upsert_fee_absorptions': [
            for (final a in change.upsertFeeAbsorptions) a.toJson()..remove('created_at'),
          ],
          'p_delete_fee_absorptions': [
            for (final d in change.deleteFeeAbsorptions)
              {'rd_id': d.rdId, 'installment_no': d.installmentNo},
          ],
          'p_summaries': [for (final s in summaries) _summaryRow(s)],
        },
      );
      if (summaries.isNotEmpty) _localSummaryWrites.add(summaries);
    });
  }

  // --- Helpers ----------------------------------------------------------------------------

  static Map<String, dynamic> _transactionRow(RDTransaction tx) {
    final json = tx.toJson()
      ..remove('created_at')
      ..remove('updated_at');
    // DATE column: strip any time component the generic converter may have produced.
    json['paid_date'] = tx.paidDate.toIso8601String().split('T').first;
    return json;
  }

  static Map<String, dynamic> _summaryRow(RDLedgerSummary summary) =>
      summary.toJson()..remove('updated_at');

  static Result<List<T>, String> _mapRows<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return Success(List<T>.unmodifiable(decodeRows(rows, fromJson)));
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
