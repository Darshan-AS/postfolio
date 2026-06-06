import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'otd_search_criteria.freezed.dart';

enum OTDSortField {
  maturityDate,
  startDate,
  name,
  amount;

  String get label => (t.sorting.properties[this.name] ?? name) as String;

  String directionLabel(SortDirection direction) {
    return switch (this) {
      OTDSortField.maturityDate =>
        direction.isAscending
            ? t.sorting.directions.maturity.asc
            : t.sorting.directions.maturity.desc,
      OTDSortField.startDate =>
        direction.isAscending
            ? t.sorting.directions.date.asc
            : t.sorting.directions.date.desc,
      OTDSortField.name =>
        direction.isAscending
            ? t.sorting.directions.name.asc
            : t.sorting.directions.name.desc,
      OTDSortField.amount =>
        direction.isAscending
            ? t.sorting.directions.amount.asc
            : t.sorting.directions.amount.desc,
    };
  }
}

@freezed
sealed class OTDSearchCriteria with _$OTDSearchCriteria {
  const factory OTDSearchCriteria({
    @Default('') String searchQuery,
    @Default(OTDSortField.maturityDate) OTDSortField sortField,
    @Default(SortDirection.asc) SortDirection sortDirection,
    @Default([DepositStatus.active]) List<DepositStatus> statusFilters,
    @Default([]) List<MaturityUrgency> urgencyFilters,
    @Default([]) List<OneTimeSchemeType> schemeFilters,
  }) = _OTDSearchCriteria;
}
