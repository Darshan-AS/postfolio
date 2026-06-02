import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';

part 'otd_search_criteria.freezed.dart';

enum OTDSortOption {
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
sealed class OTDSearchCriteria with _$OTDSearchCriteria {
  const factory OTDSearchCriteria({
    @Default('') String searchQuery,
    @Default(OTDSortOption.maturityDateAsc) OTDSortOption sortBy,
    @Default([DepositStatus.active]) List<DepositStatus> statusFilters,
    @Default([]) List<MaturityUrgency> urgencyFilters,
    @Default([]) List<OneTimeSchemeType> schemeFilters,
  }) = _OTDSearchCriteria;
}
