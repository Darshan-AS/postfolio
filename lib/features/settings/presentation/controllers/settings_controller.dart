import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// Application actions triggered from Settings, keeping presentation widgets pure.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  void build() {}

  Future<void> resetAllListCriteria() async {
    await ref.read(storageServiceProvider).clearListCriteria();
    if (!ref.mounted) return;
    ref.invalidate(customerListCriteriaProvider);
    ref.invalidate(oneTimeListCriteriaProvider);
    ref.invalidate(recurringListCriteriaProvider);
    ref.invalidate(rDHubFiltersProvider);
  }
}
