import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilities for >1,000-row PostgREST `.range()` pagination and debounced,
/// server-filtered Realtime CDC collection streams.
abstract final class SupabasePaginatedQuery {
  static const int defaultPageSize = 500;

  /// Waits between automatic retries of a failed load. After the last one the stream stops
  /// retrying on its own; the next change event or channel re-subscribe starts over.
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];
  static int _channelCounter = 0;

  /// Builds the status callback for `RealtimeChannel.subscribe`.
  ///
  /// Realtime does not replay changes made while a channel was down (phone asleep, network
  /// switch). Whenever the channel becomes subscribed *again*, [onResubscribed] is called so
  /// the list is fetched afresh. The first subscribe is skipped: the initial snapshot is
  /// already on its way.
  static void Function(RealtimeSubscribeStatus status, [Object? error]) refetchOnResubscribe(
    void Function() onResubscribed,
  ) {
    var wasSubscribed = false;
    return (status, [error]) {
      if (status != RealtimeSubscribeStatus.subscribed) return;
      if (wasSubscribed) onResubscribed();
      wasSubscribed = true;
    };
  }

  /// Fetches all pages from a deterministic `.order(...)` + `.range(from, to)` query
  /// so agent collections safely scale past PostgREST's 1,000-row `max-rows` cap.
  static Future<List<T>> fetchAllPages<T>({
    required Future<List<Map<String, dynamic>>> Function(int from, int to) fetchPage,
    required T Function(Map<String, dynamic>) fromJson,
    int pageSize = defaultPageSize,
    String idColumn = 'id',
  }) async {
    assert(pageSize > 0, 'pageSize must be positive');
    final items = <T>[];
    var offset = 0;
    while (true) {
      final rows = await fetchPage(offset, offset + pageSize - 1);
      items.addAll(decodeRows(rows, fromJson, idColumn: idColumn));
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
    return items;
  }

  /// Fetches all raw JSON map pages using `.range(from, to)`.
  static Future<List<Map<String, dynamic>>> fetchAllRawPages({
    required Future<List<Map<String, dynamic>>> Function(int from, int to) fetchPage,
    int pageSize = defaultPageSize,
  }) =>
      fetchAllPages<Map<String, dynamic>>(
        fetchPage: fetchPage,
        fromJson: (row) => row,
        pageSize: pageSize,
      );

  /// Coordinates an immediate [fetchAll] snapshot plus debounced, coalesced reloads
  /// from [invalidations], guaranteeing that invalidations arriving mid-flight trigger
  /// one follow-up fetch without overlapping requests.
  ///
  /// Failure handling:
  /// * A failed load is retried after each of [retryDelays] in turn.
  /// * While a good snapshot is on screen, a failed refresh is retried quietly; the
  ///   `Failure` is emitted only once the retries are used up. With nothing to show yet,
  ///   the `Failure` is emitted at once (and the retries still run).
  /// * A change that arrived while the failing fetch was in flight is fetched right away.
  /// * After the retries are used up, the next invalidation starts over.
  static Stream<Result<List<T>, String>> watchDebouncedCollection<T>({
    required Future<List<T>> Function() fetchAll,
    Stream<void>? invalidations,
    Future<void> Function()? onDispose,
    Duration debounce = const Duration(milliseconds: 50),
    List<Duration> retryDelays = defaultRetryDelays,
  }) {
    late final StreamController<Result<List<T>, String>> controller;
    StreamSubscription<void>? invalidationSub;
    Timer? debounceTimer;
    Timer? retryTimer;
    var disposed = false;
    var fetching = false;
    var pendingRefetch = false;
    var failedAttempts = 0; // consecutive failures since the last success or invalidation
    var hasData = false; // a snapshot has been delivered
    var failureShown = false; // the latest emission is a Failure

    void emit(Result<List<T>, String> result) {
      if (!disposed && !controller.isClosed) controller.add(result);
    }

    Future<void> load() async {
      if (disposed) return;
      if (fetching) {
        pendingRefetch = true;
        return;
      }
      fetching = true;
      retryTimer?.cancel();
      try {
        do {
          pendingRefetch = false;
          try {
            final items = await fetchAll();
            failedAttempts = 0;
            hasData = true;
            failureShown = false;
            emit(Success(items));
          } catch (error, stackTrace) {
            failedAttempts++;
            final retriesLeft = failedAttempts <= retryDelays.length;
            if ((!hasData || !retriesLeft) && !failureShown) {
              failureShown = true;
              emit(Failure(SupabaseErrorMapper.describe(error, stackTrace: stackTrace)));
            }
            if (retriesLeft && !pendingRefetch && !disposed) {
              retryTimer = Timer(retryDelays[failedAttempts - 1], () {
                unawaited(load());
              });
            }
          }
        } while (pendingRefetch && !disposed);
      } finally {
        fetching = false;
      }
    }

    void scheduleReload() {
      if (disposed) return;
      failedAttempts = 0;
      debounceTimer?.cancel();
      debounceTimer = Timer(debounce, () {
        unawaited(load());
      });
    }

    controller = StreamController<Result<List<T>, String>>(
      onListen: () {
        unawaited(load());
        invalidationSub = invalidations?.listen((_) => scheduleReload());
      },
      onCancel: () async {
        disposed = true;
        debounceTimer?.cancel();
        retryTimer?.cancel();
        await invalidationSub?.cancel();
        if (onDispose != null) {
          await onDispose();
        }
      },
    );

    return controller.stream;
  }

  /// The whole row carried by a Realtime insert or update, or `null` when the payload cannot
  /// stand in for the stored row and the caller has to load instead:
  /// * a delete (it carries no row);
  /// * a payload flagged with errors;
  /// * a payload missing any of [columns] — Realtime leaves large values out, and a row with
  ///   a hole would decode to defaults and be shown as if it were real;
  /// * [columns] still empty: until a load has shown which columns a row has, completeness
  ///   cannot be checked;
  /// * a row [fromJson] cannot decode (the load that follows reports it properly).
  static T? completeRowOf<T>(
    PostgresChangePayload payload, {
    required Set<String> columns,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final isUpsert = payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update;
    if (!isUpsert || payload.errors != null || columns.isEmpty) return null;
    final row = payload.newRecord;
    if (!columns.every(row.containsKey)) return null;
    try {
      return fromJson(row);
    } catch (_) {
      return null;
    }
  }

  /// A list kept up to date row by row instead of being loaded again after every change.
  ///
  /// [fetchAll] loads the list; after that each row from [upserts] replaces (or adds) the
  /// row with the same [keyOf] and the list is re-emitted, with bursts merged into one
  /// emission per [debounce]. Loading again is reserved for the cases where single rows are
  /// not enough:
  /// * an event on [invalidations] (a deletion, a re-subscribed channel, a row that could
  ///   not be read from the change feed);
  /// * a row arriving while a load is in flight or after one failed. That load may have read
  ///   the table before or after the change, so the row is not laid over its result;
  /// * rows from [writes] — what this client has just stored — that the list does not come
  ///   to show within [confirmWithin]. That covers a change feed that is down or dropped an
  ///   event: the write is then fetched instead of waited for. A row counts as shown when
  ///   the list holds one for which [shows] is true (default: equal).
  ///
  /// Rows are applied in arrival order with no version check: the change feed delivers them
  /// in commit order, so the last one applied is the stored one. A row that was already in
  /// the list when its event arrives is simply applied again.
  ///
  /// Loading, retries and failures behave as in [watchDebouncedCollection].
  static Stream<Result<List<T>, String>> watchKeyedCollection<T>({
    required Future<List<T>> Function() fetchAll,
    required String Function(T row) keyOf,
    Stream<T>? upserts,
    Stream<void>? invalidations,
    Stream<List<T>>? writes,
    bool Function(T held, T written)? shows,
    Duration confirmWithin = const Duration(seconds: 2),
    Future<void> Function()? onDispose,
    Duration debounce = const Duration(milliseconds: 50),
    List<Duration> retryDelays = defaultRetryDelays,
  }) {
    final rows = <String, T>{};
    final unconfirmed = <String, T>{}; // written here, not yet seen in the list
    final reloads = StreamController<void>();
    final sources = <StreamSubscription<void>>[];
    late final StreamController<Result<List<T>, String>> controller;
    StreamSubscription<Result<List<T>, String>>? loaded;
    Timer? emitTimer;
    Timer? confirmTimer;
    // True while `rows` is the result of the latest load plus every row that arrived since.
    var current = false;
    final same = shows ?? (T held, T written) => held == written;

    void dropPending() {
      emitTimer?.cancel();
      emitTimer = null;
      confirmTimer?.cancel();
      confirmTimer = null;
      unconfirmed.clear();
    }

    void reload() {
      current = false;
      dropPending();
      if (!reloads.isClosed) reloads.add(null);
    }

    Future<List<T>> load() async {
      // Anything still waiting is answered by this load: it starts after those writes.
      current = false;
      dropPending();
      final fetched = await fetchAll();
      rows
        ..clear()
        ..addEntries([for (final row in fetched) MapEntry(keyOf(row), row)]);
      current = true;
      return fetched;
    }

    void onUpsert(T row) {
      if (!current) {
        reload();
        return;
      }
      final key = keyOf(row);
      rows[key] = row;
      final awaited = unconfirmed[key];
      if (awaited != null && same(row, awaited)) {
        unconfirmed.remove(key);
        if (unconfirmed.isEmpty) {
          confirmTimer?.cancel();
          confirmTimer = null;
        }
      }
      emitTimer ??= Timer(debounce, () {
        emitTimer = null;
        if (current && !controller.isClosed) {
          controller.add(Success(List<T>.unmodifiable(rows.values)));
        }
      });
    }

    void onWritten(List<T> written) {
      if (!current) {
        reload();
        return;
      }
      for (final row in written) {
        final key = keyOf(row);
        final held = rows[key];
        if (held == null || !same(held, row)) unconfirmed[key] = row;
      }
      if (unconfirmed.isEmpty) return;
      confirmTimer?.cancel();
      confirmTimer = Timer(confirmWithin, () {
        confirmTimer = null;
        if (unconfirmed.isNotEmpty) reload();
      });
    }

    controller = StreamController<Result<List<T>, String>>(
      onListen: () {
        if (upserts != null) sources.add(upserts.listen(onUpsert));
        if (invalidations != null) sources.add(invalidations.listen((_) => reload()));
        if (writes != null) sources.add(writes.listen(onWritten));
        loaded = watchDebouncedCollection<T>(
          fetchAll: load,
          invalidations: reloads.stream,
          debounce: debounce,
          retryDelays: retryDelays,
        ).listen(controller.add, onError: controller.addError);
      },
      onCancel: () async {
        current = false;
        dropPending();
        for (final source in sources) {
          await source.cancel();
        }
        await loaded?.cancel();
        await reloads.close();
        if (onDispose != null) {
          await onDispose();
        }
      },
    );

    return controller.stream;
  }

  /// [watchKeyedCollection] over one Supabase table: the list is loaded in pages with
  /// [fetchPage], then kept current from Realtime rows of [table] where [filterColumn]
  /// equals [filterValue]. A Realtime event that is not a whole row ([completeRowOf]) and a
  /// channel that re-subscribes both load the list again.
  static Stream<Result<List<T>, String>> watchKeyedTable<T>({
    required SupabaseClient client,
    required String channelPrefix,
    required String table,
    required String filterColumn,
    required String filterValue,
    required Future<List<Map<String, dynamic>>> Function(int from, int to) fetchPage,
    required T Function(Map<String, dynamic>) fromJson,
    required String keyColumn,
    required String Function(T row) keyOf,
    Stream<List<T>>? writes,
    bool Function(T held, T written)? shows,
    Duration debounce = const Duration(milliseconds: 50),
  }) {
    late final StreamController<T> upserts;
    final invalidations = StreamController<void>();
    RealtimeChannel? channel;
    // The columns a stored row has, learned from the first loaded row.
    var columns = const <String>{};

    void invalidate() {
      if (!invalidations.isClosed) invalidations.add(null);
    }

    upserts = StreamController<T>(
      onListen: () {
        final ch = client.channel(
          '$channelPrefix:$filterValue:${++_channelCounter}',
        );
        channel = ch;
        ch
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filterColumn,
                value: filterValue,
              ),
              callback: (payload) {
                final row = completeRowOf<T>(payload, columns: columns, fromJson: fromJson);
                if (row == null) {
                  invalidate();
                } else if (!upserts.isClosed) {
                  upserts.add(row);
                }
              },
            )
            .subscribe(refetchOnResubscribe(invalidate));
      },
    );

    return watchKeyedCollection<T>(
      fetchAll: () => fetchAllPages<T>(
        fetchPage: (from, to) async {
          final page = await fetchPage(from, to);
          if (page.isNotEmpty) columns = page.first.keys.toSet();
          return page;
        },
        fromJson: fromJson,
        idColumn: keyColumn,
      ),
      keyOf: keyOf,
      upserts: upserts.stream,
      invalidations: invalidations.stream,
      writes: writes,
      shows: shows,
      debounce: debounce,
      onDispose: () async {
        final ch = channel;
        channel = null;
        if (ch != null) {
          await client.removeChannel(ch);
        }
        await upserts.close();
        await invalidations.close();
      },
    );
  }

  /// Emits an immediate paginated snapshot via [fetchAll] and refreshes on matching
  /// Realtime CDC events from [table] or local repository writes ([localMutations]),
  /// coalescing burst updates within [debounce].
  static Stream<Result<List<T>, String>> watchPaginatedCollection<T>({
    required SupabaseClient client,
    required String channelPrefix,
    required String table,
    required String filterColumn,
    required String filterValue,
    required Future<List<T>> Function() fetchAll,
    Stream<void>? localMutations,
    bool Function(PostgresChangePayload payload)? shouldRefetch,
    Duration debounce = const Duration(milliseconds: 50),
  }) {
    late final StreamController<void> triggers;
    RealtimeChannel? channel;
    StreamSubscription<void>? localSub;

    triggers = StreamController<void>(
      onListen: () {
        localSub = localMutations?.listen((_) {
          if (!triggers.isClosed) triggers.add(null);
        });
        final ch = client.channel(
          '$channelPrefix:$filterValue:${++_channelCounter}',
        );
        channel = ch;
        ch
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filterColumn,
                value: filterValue,
              ),
              callback: (payload) {
                if (!triggers.isClosed &&
                    (shouldRefetch == null || shouldRefetch(payload))) {
                  triggers.add(null);
                }
              },
            )
            .subscribe(
              refetchOnResubscribe(() {
                if (!triggers.isClosed) triggers.add(null);
              }),
            );
      },
    );

    return watchDebouncedCollection<T>(
      fetchAll: fetchAll,
      invalidations: triggers.stream,
      debounce: debounce,
      onDispose: () async {
        await localSub?.cancel();
        final ch = channel;
        channel = null;
        if (ch != null) {
          await client.removeChannel(ch);
        }
        await triggers.close();
      },
    );
  }
}
