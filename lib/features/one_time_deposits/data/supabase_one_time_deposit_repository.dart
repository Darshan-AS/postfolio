import 'dart:async';

import 'package:postfolio/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/features/one_time_deposits/domain/one_time_deposit_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/i18n/strings.g.dart';

class SupabaseOneTimeDepositRepository implements OneTimeDepositRepository {
  final SupabaseClient _supabaseClient;
  final String? _effectiveAgentId;
  final _localMutations = StreamController<void>.broadcast();

  SupabaseOneTimeDepositRepository(
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
      'principal_amount,interest_rate,term_years,term_months,start_date,'
      'created_at,updated_at';

  @override
  Stream<Result<List<OneTimeDeposit>, String>> watchOneTimeDeposits() {
    final agentId = _agentId;
    return SupabasePaginatedQuery.watchPaginatedCollection<OneTimeDeposit>(
      client: _supabaseClient,
      channelPrefix: 'otd-list',
      table: SupabaseTables.accountIdentities,
      filterColumn: 'agent_id',
      filterValue: agentId,
      localMutations: _localMutations.stream,
      shouldRefetch: (payload) {
        final type =
            payload.newRecord['account_type'] ??
            payload.oldRecord['account_type'];
        return type == null || type == 'OTD';
      },
      fetchAll: () => SupabasePaginatedQuery.fetchAllPages<OneTimeDeposit>(
        fetchPage: (from, to) => _supabaseClient
            .from(SupabaseTables.oneTimeDepositDetailsView)
            .select(_listColumns)
            .eq('agent_id', agentId)
            .order('id', ascending: true)
            .range(from, to),
        fromJson: OneTimeDeposit.fromJson,
      ),
    );
  }

  @override
  Stream<Result<OneTimeDeposit, String>> watchOneTimeDepositById(String id) {
    return _supabaseClient
        .from(SupabaseTables.accountIdentities)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((_) async {
          try {
            final data = await _supabaseClient
                .from(SupabaseTables.oneTimeDepositDetailsView)
                .select()
                .eq('id', id)
                .maybeSingle();
            if (data == null) {
              return Failure<OneTimeDeposit, String>(
                t.errors.oneTimeDepositNotFound,
              );
            }
            if (data['agent_id'] != _agentId) {
              return Failure<OneTimeDeposit, String>(t.errors.unauthorized);
            }
            return Success(OneTimeDeposit.fromJson(data));
          } catch (e) {
            return Failure(SupabaseErrorMapper.describe(e));
          }
        });
  }

  @override
  Future<Result<void, String>> createOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    return _saveOneTimeDeposit(deposit);
  }

  @override
  Future<Result<void, String>> updateOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    return _saveOneTimeDeposit(deposit);
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
  Future<Result<void, String>> deleteOneTimeDeposit(String id) async {
    try {
      // Deleting from account_identities will cascade to one_time_deposits
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

  Future<Result<void, String>> _saveOneTimeDeposit(
    OneTimeDeposit deposit,
  ) async {
    try {
      final json = deposit.toJson();
      await _supabaseClient.rpc<dynamic>(
        SupabaseRpcs.saveOneTimeDeposit,
        params: {
          'p_id': deposit.id,
          'p_customer_id': deposit.customerId,
          'p_status': json['status'],
          'p_scheme_type': json['scheme_type'],
          'p_account_no': deposit.accountNo,
          'p_principal_amount': deposit.principalAmount,
          'p_interest_rate': deposit.interestRate,
          'p_term_years': deposit.termYears,
          'p_term_months': deposit.termMonths,
          'p_start_date': deposit.startDate.toIso8601String().split('T').first,
          'p_nominees': deposit.nominees.map((n) => n.toJson()).toList(),
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
