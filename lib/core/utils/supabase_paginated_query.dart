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
