import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates raw Supabase / PostgREST / GoTrue exceptions into concise, user-safe
/// domain messages so SQL identifiers, constraint names, and stack traces never leak to UI.
///
/// Turning an error into a short message must not throw the error away: anything without a
/// specific mapping is handed to [onUnexpected] (crash reporting) with its original cause.
abstract final class SupabaseErrorMapper {
  /// Message for stored data this version of the app cannot decode.
  static String get unreadableDataMessage => t.errors.unreadableData;

  /// Sink for errors that had no specific user message (decode failures, unknown database
  /// codes, network and programming errors). Set once at startup; `null` in tests and demo.
  static void Function(Object error, StackTrace? stackTrace)? onUnexpected;

  static String describe(
    Object error, {
    String? fallback,
    StackTrace? stackTrace,
  }) {
    final resolvedFallback = fallback ?? t.errors.serverGeneric;
    if (error is PostgrestException) {
      return _describePostgrest(
        error,
        fallback: resolvedFallback,
        stackTrace: stackTrace,
      );
    }
    if (error is AuthException) {
      return _describeAuth(error);
    }
    if (error is StateError) {
      return error.message;
    }
    if (error is RowDecodeException) {
      _report(error, error.stackTrace ?? stackTrace);
      final id = error.rowId;
      if (id == null || id.isEmpty) return unreadableDataMessage;
      final reference = id.length > 8 ? id.substring(0, 8) : id;
      return t.errors.unreadableDataRecord(reference: reference);
    }
    // Decoder errors raised outside `decodeRows` (e.g. the Realtime `.stream()` path).
    if (error is ArgumentError ||
        error is TypeError ||
        error is FormatException) {
      _report(error, stackTrace);
      return unreadableDataMessage;
    }
    _report(error, stackTrace);
    return resolvedFallback;
  }

  static void _report(Object error, StackTrace? stackTrace) {
    try {
      onUnexpected?.call(error, stackTrace);
    } catch (_) {
      // Reporting is best-effort; describing an error must never throw.
    }
  }

  static String _describePostgrest(
    PostgrestException e, {
    required String fallback,
    StackTrace? stackTrace,
  }) {
    final msg = e.message;
    final details = '${e.message} ${e.details ?? ''}'.toLowerCase();

    switch (e.code) {
      case '23505':
        if (details.contains('email')) {
          return t.errors.duplicateEmail;
        }
        return t.errors.duplicateEntry;
      case '23503':
        return t.errors.foreignKeyDeleteBlocked;
      case '23514':
        return t.errors.validationFailed;
      case '42501':
        if (msg.contains('Unauthenticated')) {
          return t.errors.sessionExpired;
        }
        return t.errors.permissionDenied;
      case 'P0002':
      case 'PGRST116':
        return t.errors.recordNotFound;
    }
    _report(e, stackTrace);
    return fallback;
  }

  static String _describeAuth(AuthException e) {
    final lower = e.message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return t.errors.invalidCredentials;
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return t.errors.authNetworkError;
    }
    return t.errors.authFailed;
  }
}
