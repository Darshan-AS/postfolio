import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/i18n/strings.g.dart';

part 'customer_search_criteria.freezed.dart';

enum CustomerSortField {
  name,
  createdAt;

  String get label => (t.sorting.properties[this.name] ?? name) as String;

  String directionLabel(SortDirection direction) {
    return switch (this) {
      CustomerSortField.name =>
        direction.isAscending
            ? t.sorting.directions.name.asc
            : t.sorting.directions.name.desc,
      CustomerSortField.createdAt =>
        direction.isAscending
            ? t.sorting.directions.date.asc
            : t.sorting.directions.date.desc,
    };
  }
}

@freezed
sealed class CustomerSearchCriteria with _$CustomerSearchCriteria {
  const factory CustomerSearchCriteria({
    @Default('') String searchQuery,
    @Default(CustomerSortField.name) CustomerSortField sortField,
    @Default(SortDirection.asc) SortDirection sortDirection,
  }) = _CustomerSearchCriteria;
}
