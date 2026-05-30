import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

part 'list_criteria.freezed.dart';

enum SortOption { newest, oldest, nameAsc, nameDesc, highestAmount, maturityProximity }

@freezed
sealed class ListCriteria with _$ListCriteria {
  const factory ListCriteria({
    @Default('') String searchQuery,
    @Default(SortOption.newest) SortOption sortBy,
    @Default([]) List<DepositStatus> activeFilters,
  }) = _ListCriteria;
}
