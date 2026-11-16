import 'package:flutter/widgets.dart';
import 'package:postfolio/core/utils/date_only_converter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Injectable clock function for deterministic date/time evaluation in
/// controllers, providers, and tests.
@riverpod
DateTime Function() clock(Ref ref) {
  return DateTime.now;
}

/// Reactive calendar date (`yyyy-MM-dd` at local midnight) that refreshes automatically
/// whenever the app resumes on a new calendar day (zero background timers so widget tests
/// never leak pending `FakeAsync` timers).
@riverpod
class CurrentDate extends _$CurrentDate {
  @override
  DateTime build() {
    final readNow = ref.watch(clockProvider);
    final initial = readNow().toDateOnly();

    WidgetsBinding? binding;
    try {
      binding = WidgetsBinding.instance;
    } catch (_) {
      binding = null;
    }

    if (binding != null) {
      final observer = _DayRolloverObserver(onResume: refresh);
      binding.addObserver(observer);
      ref.onDispose(() => binding!.removeObserver(observer));
    }

    return initial;
  }

  /// Re-evaluates the clock and notifies dependents only if the calendar day changed.
  void refresh() {
    final next = ref.read(clockProvider)().toDateOnly();
    if (next != state) {
      state = next;
    }
  }
}

class _DayRolloverObserver with WidgetsBindingObserver {
  _DayRolloverObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
