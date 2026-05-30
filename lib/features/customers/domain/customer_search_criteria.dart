import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_search_criteria.freezed.dart';

enum CustomerSortOption { nameAsc, nameDesc, newest, oldest }

@freezed
sealed class CustomerSearchCriteria with _$CustomerSearchCriteria {
  const factory CustomerSearchCriteria({
    @Default('') String searchQuery,
    @Default(CustomerSortOption.newest) CustomerSortOption sortBy,
  }) = _CustomerSearchCriteria;
}
