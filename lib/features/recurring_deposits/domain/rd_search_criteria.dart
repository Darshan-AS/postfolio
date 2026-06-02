import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';

part 'rd_search_criteria.freezed.dart';

enum RDSortOption {
  serialNoAsc,
  serialNoDesc,
  maturityDateAsc,
  maturityDateDesc,
  startDateAsc,
  startDateDesc,
  nameAsc,
  nameDesc,
  amountAsc,
  amountDesc,
}

@freezed
sealed class RDSearchCriteria with _$RDSearchCriteria {
  const factory RDSearchCriteria({
    @Default('') String searchQuery,
    @Default(RDSortOption.serialNoAsc) RDSortOption sortBy,
    @Default([DepositStatus.active]) List<DepositStatus> statusFilters,
    @Default([]) List<MaturityUrgency> urgencyFilters,
  }) = _RDSearchCriteria;
}
