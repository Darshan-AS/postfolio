import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

part 'otd_search_criteria.freezed.dart';

enum OTDSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  highestAmount,
  maturityAsc,
  maturityDesc,
}

@freezed
sealed class OTDSearchCriteria with _$OTDSearchCriteria {
  const factory OTDSearchCriteria({
    @Default('') String searchQuery,
    @Default(OTDSortOption.maturityAsc) OTDSortOption sortBy,
    @Default([]) List<DepositStatus> activeFilters,
  }) = _OTDSearchCriteria;
}
