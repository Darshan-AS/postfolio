import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Injectable clock function for deterministic date/time evaluation in
/// controllers, providers, and tests.
@riverpod
DateTime Function() clock(Ref ref) {
  return DateTime.now;
}
