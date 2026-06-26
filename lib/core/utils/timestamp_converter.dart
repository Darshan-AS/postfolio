import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/env/env.dart';

class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    }
    // Also handle String just in case (e.g. from tests or local JSON)
    if (json is String) {
      return DateTime.tryParse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    
    // Return ISO-8601 string for Supabase, Timestamp for Firebase
    if (Env.useSupabase) {
      return date.toIso8601String();
    }
    
    return Timestamp.fromDate(date);
  }
}
