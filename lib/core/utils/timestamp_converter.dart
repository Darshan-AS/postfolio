import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    // We don't convert back to Timestamp here because FieldValue.serverTimestamp()
    // is usually passed directly in the repository payload, or we let Firestore
    // handle DateTime serialization if using withConverter.
    // Returning the DateTime is fine if using Firestore withConverter which handles DateTime.
    // If we're passing maps manually, returning Timestamp is better.
    return Timestamp.fromDate(date);
  }
}
