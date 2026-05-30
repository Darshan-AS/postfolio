import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

part 'rd_search_criteria.freezed.dart';

enum RDSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  highestAmount,
  maturityAsc,
  maturityDesc,
}

@freezed
sealed class RDSearchCriteria with _$RDSearchCriteria {
  const factory RDSearchCriteria({
    @Default('') String searchQuery,
    @Default(RDSortOption.maturityAsc) RDSortOption sortBy,
    @Default([]) List<DepositStatus> activeFilters,
  }) = _RDSearchCriteria;
}
