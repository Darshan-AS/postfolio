import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_data_source_provider.g.dart';

/// Demo Mode portfolio built relative to today's calendar date from [currentDateProvider].
/// Every Demo Mode repository reads from this single instance so customers, deposits, and
/// ledger facts share one consistent reference date.
@Riverpod(keepAlive: true)
FakeDataSource demoDataSource(Ref ref) {
  final today = ref.watch(currentDateProvider);
  return FakeDataSource.forDate(today);
}
