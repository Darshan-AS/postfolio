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

  @override
  Future<Result<Map<String, RDRawFactsBundle>, String>> fetchRawFactsForRds(
    List<String> rdIds,
  ) async {
    if (rdIds.isEmpty) {
      return const Success(<String, RDRawFactsBundle>{});
    }
    try {
      final agentId = _agentId;
      final targetSet = rdIds.toSet();
      final useInFilter = targetSet.length <= 100;
      final idList = useInFilter ? targetSet.toList(growable: false) : const <String>[];

      final results = await Future.wait([
        SupabasePaginatedQuery.fetchAllPages<RDTransaction>(
          fetchPage: (from, to) {
            final q = _client.from(_transactions).select().eq('agent_id', agentId);
            final filtered = useInFilter ? q.inFilter('rd_id', idList) : q;
            return filtered
                .order('paid_date', ascending: true)
                .order('id', ascending: true)
                .range(from, to);
          },
          fromJson: RDTransaction.fromJson,
        ),
        SupabasePaginatedQuery.fetchAllPages<RDPoDeposit>(
          fetchPage: (from, to) {
            final q = _client.from(_poDeposits).select().eq('agent_id', agentId);
            final filtered = useInFilter ? q.inFilter('rd_id', idList) : q;
            return filtered
                .order('deposited_on', ascending: true)
                .order('id', ascending: true)
                .range(from, to);
          },
          fromJson: RDPoDeposit.fromJson,
        ),
        SupabasePaginatedQuery.fetchAllPages<RDFeeAbsorption>(
          fetchPage: (from, to) {
            final q = _client.from(_feeAbsorptions).select().eq('agent_id', agentId);
            final filtered = useInFilter ? q.inFilter('rd_id', idList) : q;
            return filtered
                .order('rd_id', ascending: true)
                .order('installment_no', ascending: true)
                .range(from, to);
          },
          fromJson: RDFeeAbsorption.fromJson,
        ),
      ]);

      final txsByRd = <String, List<RDTransaction>>{};
      for (final tx in results[0] as List<RDTransaction>) {
        if (targetSet.contains(tx.rdId)) {
          (txsByRd[tx.rdId] ??= <RDTransaction>[]).add(tx);
        }
      }
      final posByRd = <String, List<RDPoDeposit>>{};
      for (final po in results[1] as List<RDPoDeposit>) {
        if (targetSet.contains(po.rdId)) {
          (posByRd[po.rdId] ??= <RDPoDeposit>[]).add(po);
        }
      }
      final absByRd = <String, List<RDFeeAbsorption>>{};
      for (final abs in results[2] as List<RDFeeAbsorption>) {
        if (targetSet.contains(abs.rdId)) {
          (absByRd[abs.rdId] ??= <RDFeeAbsorption>[]).add(abs);
        }
      }

      return Success({
        for (final id in targetSet)
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

      final useInFilter = affectedRdIds.length <= 100;
      final fetchedDeposits = await SupabasePaginatedQuery.fetchAllPages<RDPoDeposit>(
        fetchPage: (from, to) {
          final q = _client.from(_poDeposits).select().eq('agent_id', agentId);
          final filtered = useInFilter ? q.inFilter('rd_id', affectedRdIds) : q;
          return filtered
              .order('deposited_on', ascending: true)
              .order('id', ascending: true)
              .range(from, to);
        },
        fromJson: RDPoDeposit.fromJson,
      );
      final allDeposits = useInFilter
          ? fetchedDeposits
          : fetchedDeposits.where((d) => affectedSet.contains(d.rdId)).toList(growable: false);
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
