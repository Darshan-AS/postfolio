import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';

part 'otd_search_criteria.freezed.dart';

enum OTDSortOption { newest, oldest, nameAsc, nameDesc, highestAmount, maturityProximity }

@freezed
sealed class OTDSearchCriteria with _$OTDSearchCriteria {
  const factory OTDSearchCriteria({
    @Default('') String searchQuery,
    @Default(OTDSortOption.newest) OTDSortOption sortBy,
    @Default([]) List<DepositStatus> activeFilters,
  }) = _OTDSearchCriteria;
}
