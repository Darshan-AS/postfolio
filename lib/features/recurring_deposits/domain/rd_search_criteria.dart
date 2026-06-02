import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'rd_search_criteria.freezed.dart';

enum RDSortField {
  serialNo,
  maturityDate,
  startDate,
  name,
  amount;

  String get label => (t.sorting.properties[this.name] ?? name) as String;

  String directionLabel(SortDirection direction) {
    return switch (this) {
      RDSortField.serialNo => direction.isAscending 
          ? t.sorting.directions.serialNo.asc 
          : t.sorting.directions.serialNo.desc,
      RDSortField.maturityDate => direction.isAscending 
          ? t.sorting.directions.maturity.asc 
          : t.sorting.directions.maturity.desc,
      RDSortField.startDate => direction.isAscending 
          ? t.sorting.directions.date.asc 
          : t.sorting.directions.date.desc,
      RDSortField.name => direction.isAscending 
          ? t.sorting.directions.name.asc 
          : t.sorting.directions.name.desc,
      RDSortField.amount => direction.isAscending 
          ? t.sorting.directions.amount.asc 
          : t.sorting.directions.amount.desc,
    };
  }
}

@freezed
sealed class RDSearchCriteria with _$RDSearchCriteria {
  const factory RDSearchCriteria({
    @Default('') String searchQuery,
    @Default(RDSortField.serialNo) RDSortField sortField,
    @Default(SortDirection.asc) SortDirection sortDirection,
    @Default([DepositStatus.active]) List<DepositStatus> statusFilters,
    @Default([]) List<MaturityUrgency> urgencyFilters,
  }) = _RDSearchCriteria;
}
