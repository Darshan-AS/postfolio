import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_enums.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _txRow(String id, {String paymentMode = 'cash'}) => {
      'id': id,
      'rd_id': 'rd-1',
      'paid_date': '2026-01-10',
      'amount': 1000,
      'payment_mode': paymentMode,
    };

void main() {
  final reported = <Object>[];

  setUp(() {
    reported.clear();
    SupabaseErrorMapper.onUnexpected = (error, _) => reported.add(error);
  });
  tearDown(() => SupabaseErrorMapper.onUnexpected = null);

  group('decodeRows', () {
    test('decodes every row when all are readable', () {
      final txs = decodeRows([_txRow('t1'), _txRow('t2', paymentMode: 'upi')], RDTransaction.fromJson);
      expect(txs.map((t) => t.id), ['t1', 't2']);
      expect(txs.last.paymentMode, RDPaymentMode.upi);
    });

    test('names the row that could not be read and keeps the original cause', () {
      Object? thrown;
      try {
        decodeRows(
          [_txRow('t1'), _txRow('t2', paymentMode: 'neft'), _txRow('t3')],
          RDTransaction.fromJson,
        );
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<RowDecodeException>());
      final failure = thrown! as RowDecodeException;
      expect(failure.rowId, 't2');
      expect(failure.cause, isA<ArgumentError>(), reason: 'the enum decoder rejected `neft`');
      expect(failure.toString(), contains('neft'));
    });
  });

  test('fetchAllPages reports which row was unreadable instead of a bare decoder error', () async {
    Object? thrown;
    try {
      await SupabasePaginatedQuery.fetchAllPages<RDTransaction>(
        pageSize: 2,
        fetchPage: (from, to) async => [
          _txRow('t1'),
          _txRow('t2'),
          _txRow('t3', paymentMode: 'neft'),
        ].skip(from).take(to - from + 1).toList(),
        fromJson: RDTransaction.fromJson,
      );
    } catch (e) {
      thrown = e;
    }
    expect(thrown, isA<RowDecodeException>());
    expect((thrown! as RowDecodeException).rowId, 't3');
  });

  group('SupabaseErrorMapper', () {
    test('unreadable data gets its own message and the cause is reported, not discarded', () {
      final rowFailure = RowDecodeException(rowId: '0193f2aa-1111', cause: ArgumentError('`neft`'));
      final message = SupabaseErrorMapper.describe(rowFailure);
      expect(message, startsWith(SupabaseErrorMapper.unreadableDataMessage));
      expect(message, contains('0193f2aa'), reason: 'a short record reference helps find the row');
      expect(message, isNot(contains('neft')), reason: 'decoder internals stay out of the UI');

      // The Realtime `.stream()` path decodes outside decodeRows; a bare decoder error is
      // still recognised as unreadable data.
      expect(
        SupabaseErrorMapper.describe(ArgumentError('`neft` is not one of the supported values')),
        SupabaseErrorMapper.unreadableDataMessage,
      );
      expect(
        SupabaseErrorMapper.describe(const FormatException('Invalid date')),
        SupabaseErrorMapper.unreadableDataMessage,
      );

      expect(reported, hasLength(3));
      expect(reported.first, same(rowFailure));
    });

    test('an error with no specific mapping keeps the fallback text but is reported', () {
      final unknown = Exception('socket closed');
      expect(SupabaseErrorMapper.describe(unknown, fallback: 'Try again.'), 'Try again.');

      const unmappedDb = PostgrestException(message: 'internal', code: 'XX000');
      expect(SupabaseErrorMapper.describe(unmappedDb, fallback: 'Try again.'), 'Try again.');

      expect(reported, [same(unknown), same(unmappedDb)]);
    });

    test('errors with a specific user message are not reported as unexpected', () {
      SupabaseErrorMapper.describe(const PostgrestException(message: 'dup', code: '23505'));
      SupabaseErrorMapper.describe(const PostgrestException(message: 'fk', code: '23503'));
      SupabaseErrorMapper.describe(const AuthException('Invalid login credentials'));
      expect(reported, isEmpty);
    });

    test('describing an error never throws, even if the reporter does', () {
      SupabaseErrorMapper.onUnexpected = (_, _) => throw StateError('reporter down');
      expect(SupabaseErrorMapper.describe(Exception('x'), fallback: 'Try again.'), 'Try again.');
    });
  });
}
