import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

part 'rd_search_criteria.freezed.dart';

enum RDSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  highestAmount,
  maturityAsc,
  maturityDesc,
  serialNoAsc,
  serialNoDesc,
}

@freezed
sealed class RDSearchCriteria with _$RDSearchCriteria {
  const factory RDSearchCriteria({
    @Default('') String searchQuery,
    @Default(RDSortOption.maturityAsc) RDSortOption sortBy,
    @Default([DepositStatus.active, DepositStatus.matured])
    List<DepositStatus> statusFilters,
    @Default([]) List<MaturityUrgency> urgencyFilters,
  }) = _RDSearchCriteria;
}
