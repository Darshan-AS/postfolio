import 'package:postfolio/core/utils/row_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates raw Supabase / PostgREST / GoTrue exceptions into concise, user-safe
/// domain messages so SQL identifiers, constraint names, and stack traces never leak to UI.
///
/// Turning an error into a short message must not throw the error away: anything without a
/// specific mapping is handed to [onUnexpected] (crash reporting) with its original cause.
abstract final class SupabaseErrorMapper {
  /// Message for stored data this version of the app cannot decode.
  static const String unreadableDataMessage =
      'Some saved data could not be read by this version of the app. Update the app and try again.';

  /// Sink for errors that had no specific user message (decode failures, unknown database
  /// codes, network and programming errors). Set once at startup; `null` in tests and demo.
  static void Function(Object error, StackTrace? stackTrace)? onUnexpected;

  static String describe(
    Object error, {
    String fallback = 'Something went wrong while talking to the server. Please try again.',
    StackTrace? stackTrace,
  }) {
    if (error is PostgrestException) {
      return _describePostgrest(error, fallback: fallback, stackTrace: stackTrace);
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
      return '$unreadableDataMessage (record $reference)';
    }
    // Decoder errors raised outside `decodeRows` (e.g. the Realtime `.stream()` path).
    if (error is ArgumentError || error is TypeError || error is FormatException) {
      _report(error, stackTrace);
      return unreadableDataMessage;
    }
    _report(error, stackTrace);
    return fallback;
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
          return 'An agent profile with this email already exists.';
        }
        return 'This entry has already been recorded.';
      case '23503':
        return 'This record cannot be deleted while linked accounts or ledger entries exist.';
      case '23514':
        return 'The entry does not satisfy the validation rules.';
      case '42501':
        if (msg.contains('Unauthenticated')) {
          return 'Your session has expired. Please sign in again.';
        }
        return 'You do not have permission to modify this record.';
      case 'P0002':
      case 'PGRST116':
        return 'The requested record could not be found.';
    }
    _report(e, stackTrace);
    return fallback;
  }

  static String _describeAuth(AuthException e) {
    final lower = e.message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network error during authentication. Check your connection and try again.';
    }
    return 'Authentication failed. Please try signing in again.';
  }
}
