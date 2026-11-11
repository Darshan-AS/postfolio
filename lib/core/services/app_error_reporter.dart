import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Rate-limited, deduplicated client crash reporter for Web (where Firebase Crashlytics
/// is unsupported). Writes bounded crash records via `public.log_client_error` only when
/// an authenticated session is active, and silently drops errors when offline or capped.
class AppErrorReporter {
  AppErrorReporter({
    required Future<void> Function({
      required String platform,
      required String error,
      String? stackTrace,
    }) send,
    DateTime Function()? now,
    this.cooldown = const Duration(seconds: 60),
    this.maxReportsPerSession = 20,
  })  : _send = send,
        _now = now ?? DateTime.now;

  factory AppErrorReporter.supabase(SupabaseClient client) {
    return AppErrorReporter(
      send: ({
        required String platform,
        required String error,
        String? stackTrace,
      }) async {
        if (client.auth.currentSession == null) return;
        await client.rpc(
          'log_client_error',
          params: {
            'p_platform': platform,
            'p_error': error,
            'p_stack_trace': stackTrace,
          },
        );
      },
    );
  }

  final Future<void> Function({
    required String platform,
    required String error,
    String? stackTrace,
  }) _send;
  final DateTime Function() _now;
  final Duration cooldown;
  final int maxReportsPerSession;

  final Map<String, DateTime> _lastSentBySignature = {};
  int _sentCount = 0;

  int get sentCount => _sentCount;

  Future<void> report({
    required String platform,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    if (_sentCount >= maxReportsPerSession) return;

    final message = error.toString();
    final signature = '${platform.trim()}|${message.length > 200 ? message.substring(0, 200) : message}';
    final timestamp = _now();
    final previous = _lastSentBySignature[signature];
    if (previous != null && timestamp.difference(previous) < cooldown) {
      return;
    }

    _lastSentBySignature[signature] = timestamp;
    _sentCount++;

    try {
      await _send(
        platform: platform,
        error: message,
        stackTrace: stackTrace?.toString(),
      );
    } catch (_) {
      // Telemetry must never throw or cascade into secondary framework errors.
    }
  }

  void reportUnawaited({
    required String platform,
    required Object error,
    StackTrace? stackTrace,
  }) {
    unawaited(report(platform: platform, error: error, stackTrace: stackTrace));
  }
}
