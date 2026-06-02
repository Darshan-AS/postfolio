import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_search_criteria.freezed.dart';

enum CustomerSortOption { nameAsc, nameDesc, createdAtAsc, createdAtDesc }

@freezed
sealed class CustomerSearchCriteria with _$CustomerSearchCriteria {
  const factory CustomerSearchCriteria({
    @Default('') String searchQuery,
    @Default(CustomerSortOption.nameAsc) CustomerSortOption sortBy,
  }) = _CustomerSearchCriteria;
}
