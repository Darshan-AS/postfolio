import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates raw Supabase / PostgREST / GoTrue exceptions into concise, user-safe
/// domain messages so SQL identifiers, constraint names, and stack traces never leak to UI.
abstract final class SupabaseErrorMapper {
  static String describe(
    Object error, {
    String fallback = 'Something went wrong while talking to the server. Please try again.',
  }) {
    if (error is PostgrestException) {
      return _describePostgrest(error, fallback: fallback);
    }
    if (error is AuthException) {
      return _describeAuth(error);
    }
    if (error is StateError) {
      return error.message;
    }
    return fallback;
  }

  static String _describePostgrest(
    PostgrestException e, {
    required String fallback,
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
        if (msg.contains('Financial terms cannot be modified')) {
          return 'Financial terms cannot be modified after ledger activity has been recorded.';
        }
        if (msg.contains('newer Post Office deposit')) {
          return 'Cannot undo this visit because a newer Post Office deposit was recorded afterward.';
        }
        if (msg.contains('Invalid deposit status')) {
          return 'Invalid deposit status.';
        }
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
