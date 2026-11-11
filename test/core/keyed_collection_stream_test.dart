import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_paginated_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef _Row = ({String id, int v});

_Row _row(String id, int v) => (id: id, v: v);

void main() {
  group('SupabasePaginatedQuery.watchKeyedCollection', () {
    const tick = Duration(milliseconds: 5);
    const confirmWithin = Duration(milliseconds: 40);

    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    // A scripted `fetchAll`: each call returns the next snapshot (`null` throws); the last
    // one repeats.
    ({
      List<Result<List<_Row>, String>> emitted,
      StreamController<_Row> upserts,
      StreamController<void> invalidations,
      StreamController<List<_Row>> writes,
      int Function() loads,
      int Function() disposals,
      StreamSubscription<Result<List<_Row>, String>> sub,
    }) watch(
      List<List<_Row>?> snapshots, {
      Completer<void>? holdFirstLoad,
      List<Duration> retryDelays = const [],
    }) {
      final upserts = StreamController<_Row>.broadcast();
      final invalidations = StreamController<void>.broadcast();
      final writes = StreamController<List<_Row>>.broadcast();
      addTearDown(upserts.close);
      addTearDown(invalidations.close);
      addTearDown(writes.close);
      var loads = 0;
      var disposals = 0;
      final emitted = <Result<List<_Row>, String>>[];
      final sub = SupabasePaginatedQuery.watchKeyedCollection<_Row>(
        keyOf: (row) => row.id,
        upserts: upserts.stream,
        invalidations: invalidations.stream,
        writes: writes.stream,
        confirmWithin: confirmWithin,
        debounce: tick,
        retryDelays: retryDelays,
        onDispose: () async => disposals++,
        fetchAll: () async {
          final index = loads++;
          if (index == 0 && holdFirstLoad != null) await holdFirstLoad.future;
          final snapshot = index < snapshots.length ? snapshots[index] : snapshots.last;
          if (snapshot == null) throw Exception('network down');
          return snapshot;
        },
      ).listen(emitted.add);
      addTearDown(sub.cancel);
      return (
        emitted: emitted,
        upserts: upserts,
        invalidations: invalidations,
        writes: writes,
        loads: () => loads,
        disposals: () => disposals,
        sub: sub,
      );
    }

    List<_Row>? rowsOf(Result<List<_Row>, String> r) =>
        r is Success<List<_Row>, String> ? r.value : null;

    test('changed and new rows are applied to the list without loading it again', () async {
      final w = watch([
        [_row('a', 1), _row('b', 1)],
      ]);
      await wait(20);
      expect(rowsOf(w.emitted.single), [_row('a', 1), _row('b', 1)]);

      w.upserts
        ..add(_row('a', 2))
        ..add(_row('c', 1))
        ..add(_row('a', 3));
      await wait(30);

      expect(w.loads(), 1, reason: 'three row changes must not cost three (or any) full loads');
      expect(w.emitted, hasLength(2), reason: 'a burst of changes is one emission');
      expect(rowsOf(w.emitted.last), [_row('a', 3), _row('b', 1), _row('c', 1)]);
    });

    test('a row that changes while a load is in flight causes one more load', () async {
      // The in-flight load may have read the table before or after that change, so the
      // change cannot simply be laid over its result.
      final gate = Completer<void>();
      final w = watch(
        [
          [_row('a', 1)],
          [_row('a', 2)],
        ],
        holdFirstLoad: gate,
      );
      await wait(10);
      w.upserts.add(_row('a', 9));
      await wait(15);
      expect(w.loads(), 1, reason: 'loads never overlap');

      gate.complete();
      await wait(30);

      expect(w.loads(), 2);
      expect(rowsOf(w.emitted.last), [_row('a', 2)], reason: 'the list is what the server says');
    });

    test('an invalidation reloads, so rows that are gone from the server disappear', () async {
      final w = watch([
        [_row('a', 1), _row('b', 1)],
        [_row('a', 1)],
      ]);
      await wait(20);
      w.upserts.add(_row('b', 2));
      await wait(20);
      expect(rowsOf(w.emitted.last), [_row('a', 1), _row('b', 2)]);

      w.invalidations.add(null);
      await wait(30);

      expect(w.loads(), 2);
      expect(rowsOf(w.emitted.last), [_row('a', 1)]);
    });

    test('a write the list does not come to show is fetched by a reload', () async {
      // The change feed is down: nothing confirms the write.
      final w = watch([
        [_row('a', 1)],
        [_row('a', 2)],
      ]);
      await wait(20);

      w.writes.add([_row('a', 2)]);
      await wait(15);
      expect(w.loads(), 1, reason: 'the change feed gets a moment to deliver the row first');

      await wait(60);
      expect(w.loads(), 2);
      expect(rowsOf(w.emitted.last), [_row('a', 2)]);
    });

    test('a write the change feed delivers costs no reload', () async {
      final w = watch([
        [_row('a', 1), _row('b', 1)],
      ]);
      await wait(20);

      w.writes.add([_row('a', 2), _row('b', 2)]);
      w.upserts.add(_row('a', 2));
      await wait(10);
      w.upserts.add(_row('b', 2));
      await wait(80);

      expect(w.loads(), 1);
      expect(rowsOf(w.emitted.last), [_row('a', 2), _row('b', 2)]);
    });

    test('a write whose row arrived before it was announced costs no reload', () async {
      // The change feed can be quicker than the response to the write itself.
      final w = watch([
        [_row('a', 1)],
      ]);
      await wait(20);

      w.upserts.add(_row('a', 2));
      await wait(15);
      w.writes.add([_row('a', 2)]);
      await wait(80);

      expect(w.loads(), 1);
    });

    test('a write only partly delivered by the change feed is reloaded', () async {
      final w = watch([
        [_row('a', 1), _row('b', 1)],
        [_row('a', 2), _row('b', 2)],
      ]);
      await wait(20);

      w.writes.add([_row('a', 2), _row('b', 2)]);
      w.upserts.add(_row('a', 2));
      await wait(80);

      expect(w.loads(), 2);
      expect(rowsOf(w.emitted.last), [_row('a', 2), _row('b', 2)]);
    });

    test('after a failed load nothing is merged: the next change loads again', () async {
      final w = watch([
        null,
        [_row('a', 1)],
      ]);
      await wait(20);
      expect(w.emitted.single, isA<Failure<List<_Row>, String>>());

      w.upserts.add(_row('z', 5));
      await wait(30);

      expect(w.loads(), 2);
      expect(rowsOf(w.emitted.last), [_row('a', 1)],
          reason: 'one changed row is not a list; the list comes from the server');
    });

    test('cancelling stops the pending confirmation and releases the source', () async {
      final w = watch([
        [_row('a', 1)],
      ]);
      await wait(20);
      w.writes.add([_row('a', 2)]);

      await w.sub.cancel();
      await wait(80);

      expect(w.loads(), 1, reason: 'no reload after the listener is gone');
      expect(w.disposals(), 1);
    });
  });

  group('SupabasePaginatedQuery.completeRowOf', () {
    const columns = {'id', 'v', 'note'};

    PostgresChangePayload payload(
      PostgresChangeEvent event, {
      Map<String, dynamic> newRecord = const {},
      Map<String, dynamic> oldRecord = const {},
      Object? errors,
    }) =>
        PostgresChangePayload(
          schema: 'public',
          table: 'things',
          commitTimestamp: DateTime(2026, 4, 20),
          eventType: event,
          newRecord: newRecord,
          oldRecord: oldRecord,
          errors: errors,
        );

    _Row? decode(PostgresChangePayload p, {Set<String> known = columns}) =>
        SupabasePaginatedQuery.completeRowOf<_Row>(
          p,
          columns: known,
          fromJson: (json) => _row(json['id'] as String, json['v'] as int),
        );

    test('an insert or update carrying every column is decoded', () {
      const full = {'id': 'a', 'v': 2, 'note': null};
      expect(decode(payload(PostgresChangeEvent.insert, newRecord: full)), _row('a', 2));
      expect(decode(payload(PostgresChangeEvent.update, newRecord: full)), _row('a', 2));
    });

    test('a payload that is not a whole row is refused', () {
      expect(
        decode(payload(PostgresChangeEvent.update, newRecord: const {'id': 'a', 'v': 2})),
        isNull,
        reason: 'Realtime leaves out large values; a row with a hole must not be shown',
      );
      expect(
        decode(payload(PostgresChangeEvent.delete, oldRecord: const {'id': 'a'})),
        isNull,
        reason: 'a delete carries no row',
      );
      expect(
        decode(
          payload(PostgresChangeEvent.update, newRecord: const {'id': 'a', 'v': 2, 'note': null}),
          known: const {},
        ),
        isNull,
        reason: 'until a load has shown which columns a row has, a payload cannot be checked',
      );
      expect(
        decode(
          payload(
            PostgresChangeEvent.update,
            newRecord: const {'id': 'a', 'v': 2, 'note': null},
            errors: const ['Error 401: Unauthorized'],
          ),
        ),
        isNull,
      );
      expect(
        decode(
          payload(PostgresChangeEvent.update, newRecord: const {'id': 'a', 'v': 'two', 'note': null}),
        ),
        isNull,
        reason: 'a row that does not decode is fetched instead of crashing the stream',
      );
    });
  });
}
