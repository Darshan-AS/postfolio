/// Thrown when a stored row cannot be turned into its model — typically a value this version
/// of the app does not know (a new enum token, a missing column).
///
/// Carries the row's id and the original [cause], so the failure can be traced to one record
/// instead of surfacing as an anonymous "something went wrong".
class RowDecodeException implements Exception {
  const RowDecodeException({required this.rowId, required this.cause, this.stackTrace});

  /// Primary key of the row that failed, when the row has one.
  final String? rowId;
  final Object cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'RowDecodeException(row ${rowId ?? 'without id'}): $cause';
}

/// Decodes [rows] with [fromJson], one row at a time.
///
/// A list is all-or-nothing on purpose: silently dropping a payment or an account would
/// show wrong money. The first unreadable row stops the decode with a [RowDecodeException]
/// naming it.
List<T> decodeRows<T>(
  List<Map<String, dynamic>> rows,
  T Function(Map<String, dynamic>) fromJson, {
  String idColumn = 'id',
}) {
  final decoded = <T>[];
  for (final row in rows) {
    try {
      decoded.add(fromJson(row));
    } catch (error, stackTrace) {
      throw RowDecodeException(
        rowId: row[idColumn]?.toString(),
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
  return decoded;
}
