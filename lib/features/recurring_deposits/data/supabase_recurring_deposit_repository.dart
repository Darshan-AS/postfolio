import 'dart:async';

import 'package:postfolio/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/recurring_deposits/domain/recurring_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/i18n/strings.g.dart';

class SupabaseRecurringDepositRepository implements RecurringDepositRepository {
  final SupabaseClient _supabaseClient;
  final String? _effectiveAgentId;
  final _localMutations = StreamController<void>.broadcast();

  SupabaseRecurringDepositRepository(
    this._supabaseClient, {
    String? effectiveAgentId,
  }) : _effectiveAgentId = effectiveAgentId;

  String get _agentId {
    final override = _effectiveAgentId;
    if (override != null && override.isNotEmpty) return override;
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw StateError('Agent not authenticated');
    return user.id;
  }

  bool get _isActingAsOther {
    final override = _effectiveAgentId;
    if (override == null || override.isEmpty) return false;
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    return currentUserId == null || override != currentUserId;
  }

  void dispose() {
    if (!_localMutations.isClosed) {
      unawaited(_localMutations.close());
    }
  }

  static const _listColumns =
      'id,agent_id,customer_id,customer_name,status,scheme_type,account_no,'
      'serial_no,installment_amount,interest_rate,term_years,term_months,'
      'start_date,initial_paid_installments,opening_receivable,'
      'created_at,updated_at';

  @override
  Stream<Result<List<RecurringDeposit>, String>> watchRecurringDeposits() {
    final agentId = _agentId;
    return SupabasePaginatedQuery.watchPaginatedCollection<RecurringDeposit>(
      client: _supabaseClient,
      channelPrefix: 'rd-list',
      table: SupabaseTables.accountIdentities,
      filterColumn: 'agent_id',
      filterValue: agentId,
      localMutations: _localMutations.stream,
      shouldRefetch: (payload) {
        final type =
            payload.newRecord['account_type'] ??
            payload.oldRecord['account_type'];
        return type == null || type == 'RD';
      },
      fetchAll: () => SupabasePaginatedQuery.fetchAllPages<RecurringDeposit>(
        fetchPage: (from, to) => _supabaseClient
            .from(SupabaseTables.recurringDepositDetailsView)
            .select(_listColumns)
            .eq('agent_id', agentId)
            .order('id', ascending: true)
            .range(from, to),
        fromJson: RecurringDeposit.fromJson,
      ),
    );
  }

  @override
  Stream<Result<RecurringDeposit, String>> watchRecurringDepositById(
    String id,
  ) {
    return _supabaseClient
        .from(SupabaseTables.accountIdentities)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from(SupabaseTables.recurringDepositDetailsView)
                .select()
                .eq('id', id)
                .maybeSingle();
            if (data == null) {
              return Failure<RecurringDeposit, String>(
                t.errors.recurringDepositNotFound,
              );
            }
            if (data['agent_id'] != _agentId) {
              return Failure<RecurringDeposit, String>(t.errors.unauthorized);
            }
            return Success(RecurringDeposit.fromJson(data));
          } catch (e) {
            return Failure(SupabaseErrorMapper.describe(e));
          }
        });
  }

  @override
  Future<Result<void, String>> saveRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    return _saveRecurringDeposit(deposit);
  }

  @override
  Future<Result<void, String>> updateDepositStatus(
    String id,
    DepositStatus status,
  ) async {
    try {
      await _supabaseClient.rpc<dynamic>(
        SupabaseRpcs.setDepositStatus,
        params: {
          'p_id': id,
          'p_status': status.name,
          if (_isActingAsOther) 'p_agent_id': _agentId,
        },
      );
      if (!_localMutations.isClosed) _localMutations.add(null);
      return const Success(null);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }

  @override
  Future<Result<void, String>> deleteRecurringDeposit(String id) async {
    try {
      await _supabaseClient
          .from(SupabaseTables.accountIdentities)
          .delete()
          .eq('id', id)
          .eq('agent_id', _agentId);
      if (!_localMutations.isClosed) _localMutations.add(null);
      return const Success(null);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }

  Future<Result<void, String>> _saveRecurringDeposit(
    RecurringDeposit deposit,
  ) async {
    try {
      final json = deposit.toJson();
      await _supabaseClient.rpc<dynamic>(
        SupabaseRpcs.saveRecurringDeposit,
        params: {
          'p_id': deposit.id,
          'p_customer_id': deposit.customerId,
          'p_status': json['status'],
          'p_scheme_type': json['scheme_type'],
          'p_account_no': deposit.accountNo,
          'p_serial_no': deposit.serialNo,
          'p_installment_amount': deposit.installmentAmount,
          'p_interest_rate': deposit.interestRate,
          'p_term_years': deposit.termYears,
          'p_term_months': deposit.termMonths,
          'p_start_date': deposit.startDate.toIso8601String().split('T').first,
          'p_nominees': deposit.nominees.map((n) => n.toJson()).toList(),
          'p_initial_paid_installments': deposit.initialPaidInstallments,
          'p_opening_receivable': deposit.openingReceivable,
          if (_isActingAsOther) 'p_agent_id': _agentId,
        },
      );
      if (!_localMutations.isClosed) _localMutations.add(null);
      return const Success(null);
    } catch (e) {
      return Failure(SupabaseErrorMapper.describe(e));
    }
  }
}
