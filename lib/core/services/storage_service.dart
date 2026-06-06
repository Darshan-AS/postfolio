import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/features/customers/domain/customer_search_criteria.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';

part 'storage_service.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('Initialize sharedPreferences in main.dart');
}

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
}

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _demoModeKey = 'demo_mode_enabled';
  static const _themeModeKey = 'theme_mode';

  static const _customerSortFieldKey = 'customer_sort_field';
  static const _customerSortDirectionKey = 'customer_sort_direction';

  static const _otdSortFieldKey = 'otd_sort_field';
  static const _otdSortDirectionKey = 'otd_sort_direction';
  static const _otdStatusFiltersKey = 'otd_status_filters';
  static const _otdUrgencyFiltersKey = 'otd_urgency_filters';
  static const _otdSchemeFiltersKey = 'otd_scheme_filters';

  static const _rdSortFieldKey = 'rd_sort_field';
  static const _rdSortDirectionKey = 'rd_sort_direction';
  static const _rdStatusFiltersKey = 'rd_status_filters';
  static const _rdUrgencyFiltersKey = 'rd_urgency_filters';

  bool get isDemoMode => _prefs.getBool(_demoModeKey) ?? false;

  Future<void> setDemoMode(bool value) => _prefs.setBool(_demoModeKey, value);

  // Theme
  AppThemeMode getThemeMode() {
    final modeString = _prefs.getString(_themeModeKey);
    if (modeString != null) {
      return AppThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => AppThemeMode.system,
      );
    }
    return AppThemeMode.system;
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _prefs.setString(_themeModeKey, mode.name);

  // Customers Criteria
  CustomerSortField getCustomerSortField() {
    final fieldString = _prefs.getString(_customerSortFieldKey);
    if (fieldString != null) {
      return CustomerSortField.values.firstWhere(
        (e) => e.name == fieldString,
        orElse: () => CustomerSortField.name,
      );
    }
    return CustomerSortField.name;
  }

  Future<void> setCustomerSortField(CustomerSortField field) =>
      _prefs.setString(_customerSortFieldKey, field.name);

  SortDirection getCustomerSortDirection() {
    final dirString = _prefs.getString(_customerSortDirectionKey);
    if (dirString != null) {
      return SortDirection.values.firstWhere(
        (e) => e.name == dirString,
        orElse: () => SortDirection.asc,
      );
    }
    return SortDirection.asc;
  }

  Future<void> setCustomerSortDirection(SortDirection direction) =>
      _prefs.setString(_customerSortDirectionKey, direction.name);

  // One-Time Deposits Criteria
  OTDSortField getOTDSortField() {
    final fieldString = _prefs.getString(_otdSortFieldKey);
    if (fieldString != null) {
      return OTDSortField.values.firstWhere(
        (e) => e.name == fieldString,
        orElse: () => OTDSortField.startDate,
      );
    }
    return OTDSortField.startDate;
  }

  Future<void> setOTDSortField(OTDSortField field) =>
      _prefs.setString(_otdSortFieldKey, field.name);

  SortDirection getOTDSortDirection() {
    final dirString = _prefs.getString(_otdSortDirectionKey);
    if (dirString != null) {
      return SortDirection.values.firstWhere(
        (e) => e.name == dirString,
        orElse: () => SortDirection.desc,
      );
    }
    return SortDirection.desc;
  }

  Future<void> setOTDSortDirection(SortDirection direction) =>
      _prefs.setString(_otdSortDirectionKey, direction.name);

  List<DepositStatus> getOTDStatusFilters() {
    final strings = _prefs.getStringList(_otdStatusFiltersKey);
    if (strings != null) {
      return strings
          .map(
            (s) => DepositStatus.values.firstWhere(
              (e) => e.name == s,
              orElse: () => DepositStatus.active,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> setOTDStatusFilters(List<DepositStatus> filters) => _prefs
      .setStringList(_otdStatusFiltersKey, filters.map((e) => e.name).toList());

  List<MaturityUrgency> getOTDUrgencyFilters() {
    final strings = _prefs.getStringList(_otdUrgencyFiltersKey);
    if (strings != null) {
      return strings
          .map(
            (s) => MaturityUrgency.values.firstWhere(
              (e) => e.name == s,
              orElse: () => MaturityUrgency.normal,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> setOTDUrgencyFilters(List<MaturityUrgency> filters) =>
      _prefs.setStringList(
        _otdUrgencyFiltersKey,
        filters.map((e) => e.name).toList(),
      );

  List<OneTimeSchemeType> getOTDSchemeFilters() {
    final strings = _prefs.getStringList(_otdSchemeFiltersKey);
    if (strings != null) {
      return strings
          .map(
            (s) => OneTimeSchemeType.values.firstWhere(
              (e) => e.name == s,
              orElse: () => OneTimeSchemeType.timeDeposit,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> setOTDSchemeFilters(List<OneTimeSchemeType> filters) => _prefs
      .setStringList(_otdSchemeFiltersKey, filters.map((e) => e.name).toList());

  // Recurring Deposits Criteria
  RDSortField getRDSortField() {
    final fieldString = _prefs.getString(_rdSortFieldKey);
    if (fieldString != null) {
      return RDSortField.values.firstWhere(
        (e) => e.name == fieldString,
        orElse: () => RDSortField.startDate,
      );
    }
    return RDSortField.startDate;
  }

  Future<void> setRDSortField(RDSortField field) =>
      _prefs.setString(_rdSortFieldKey, field.name);

  SortDirection getRDSortDirection() {
    final dirString = _prefs.getString(_rdSortDirectionKey);
    if (dirString != null) {
      return SortDirection.values.firstWhere(
        (e) => e.name == dirString,
        orElse: () => SortDirection.desc,
      );
    }
    return SortDirection.desc;
  }

  Future<void> setRDSortDirection(SortDirection direction) =>
      _prefs.setString(_rdSortDirectionKey, direction.name);

  List<DepositStatus> getRDStatusFilters() {
    final strings = _prefs.getStringList(_rdStatusFiltersKey);
    if (strings != null) {
      return strings
          .map(
            (s) => DepositStatus.values.firstWhere(
              (e) => e.name == s,
              orElse: () => DepositStatus.active,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> setRDStatusFilters(List<DepositStatus> filters) => _prefs
      .setStringList(_rdStatusFiltersKey, filters.map((e) => e.name).toList());

  List<MaturityUrgency> getRDUrgencyFilters() {
    final strings = _prefs.getStringList(_rdUrgencyFiltersKey);
    if (strings != null) {
      return strings
          .map(
            (s) => MaturityUrgency.values.firstWhere(
              (e) => e.name == s,
              orElse: () => MaturityUrgency.normal,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> setRDUrgencyFilters(List<MaturityUrgency> filters) => _prefs
      .setStringList(_rdUrgencyFiltersKey, filters.map((e) => e.name).toList());
}
