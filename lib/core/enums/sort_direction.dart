import 'package:postfolio/i18n/strings.g.dart';

enum SortDirection {
  asc,
  desc;

  bool get isAscending => this == SortDirection.asc;
  bool get isDescending => this == SortDirection.desc;

  String get label => isAscending
      ? t.sorting.directions.general.asc
      : t.sorting.directions.general.desc;
}
