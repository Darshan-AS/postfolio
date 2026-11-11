import 'dart:async';

import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/utils/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilities for >1,000-row PostgREST `.range()` pagination and debounced,
/// server-filtered Realtime CDC collection streams.
abstract final class SupabasePaginatedQuery {
  static const int defaultPageSize = 500;
  static int _channelCounter = 0;

  /// Fetches all pages from a deterministic `.order(...)` + `.range(from, to)` query
  /// so agent collections safely scale past PostgREST's 1,000-row `max-rows` cap.
  static Future<List<T>> fetchAllPages<T>({
    required Future<List<Map<String, dynamic>>> Function(int from, int to) fetchPage,
    required T Function(Map<String, dynamic>) fromJson,
    int pageSize = defaultPageSize,
  }) async {
    assert(pageSize > 0, 'pageSize must be positive');
    final items = <T>[];
    var offset = 0;
    while (true) {
      final rows = await fetchPage(offset, offset + pageSize - 1);
      for (final row in rows) {
        items.add(fromJson(row));
      }
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
  static Stream<Result<List<T>, String>> watchDebouncedCollection<T>({
    required Future<List<T>> Function() fetchAll,
    Stream<void>? invalidations,
    Future<void> Function()? onDispose,
    Duration debounce = const Duration(milliseconds: 50),
  }) {
    late final StreamController<Result<List<T>, String>> controller;
    StreamSubscription<void>? invalidationSub;
    Timer? debounceTimer;
    var disposed = false;
    var fetching = false;
    var pendingRefetch = false;

    Future<void> load() async {
      if (disposed) return;
      if (fetching) {
        pendingRefetch = true;
        return;
      }
      fetching = true;
      try {
        do {
          pendingRefetch = false;
          final items = await fetchAll();
          if (!disposed && !controller.isClosed) {
            controller.add(Success(items));
          }
        } while (pendingRefetch && !disposed);
      } catch (e) {
        if (!disposed && !controller.isClosed) {
          controller.add(Failure(SupabaseErrorMapper.describe(e)));
        }
      } finally {
        fetching = false;
      }
    }

    void scheduleReload() {
      if (disposed) return;
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
            .subscribe();
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
