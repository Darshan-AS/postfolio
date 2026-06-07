// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardMetricsData)
final dashboardMetricsDataProvider = DashboardMetricsDataProvider._();

final class DashboardMetricsDataProvider
    extends
        $FunctionalProvider<
          DashboardMetrics,
          DashboardMetrics,
          DashboardMetrics
        >
    with $Provider<DashboardMetrics> {
  DashboardMetricsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardMetricsDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardMetricsDataHash();

  @$internal
  @override
  $ProviderElement<DashboardMetrics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardMetrics create(Ref ref) {
    return dashboardMetricsData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardMetrics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardMetrics>(value),
    );
  }
}

String _$dashboardMetricsDataHash() =>
    r'b814b081acda0b09f0f2be3a068d3c906d15a7ff';

@ProviderFor(DashboardChartSelectedYear)
final dashboardChartSelectedYearProvider =
    DashboardChartSelectedYearProvider._();

final class DashboardChartSelectedYearProvider
    extends $NotifierProvider<DashboardChartSelectedYear, int?> {
  DashboardChartSelectedYearProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardChartSelectedYearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardChartSelectedYearHash();

  @$internal
  @override
  DashboardChartSelectedYear create() => DashboardChartSelectedYear();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$dashboardChartSelectedYearHash() =>
    r'252462e68c01b9578401be8a137b81da3e30761d';

abstract class _$DashboardChartSelectedYear extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(DashboardChartFilter)
final dashboardChartFilterProvider = DashboardChartFilterProvider._();

final class DashboardChartFilterProvider
    extends $NotifierProvider<DashboardChartFilter, OneTimeSchemeType?> {
  DashboardChartFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardChartFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardChartFilterHash();

  @$internal
  @override
  DashboardChartFilter create() => DashboardChartFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OneTimeSchemeType? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OneTimeSchemeType?>(value),
    );
  }
}

String _$dashboardChartFilterHash() =>
    r'a0a56d11505e6b0a1cae30921ef9787f4ffe0bbf';

abstract class _$DashboardChartFilter extends $Notifier<OneTimeSchemeType?> {
  OneTimeSchemeType? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OneTimeSchemeType?, OneTimeSchemeType?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OneTimeSchemeType?, OneTimeSchemeType?>,
              OneTimeSchemeType?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(dashboardChartSeries)
final dashboardChartSeriesProvider = DashboardChartSeriesProvider._();

final class DashboardChartSeriesProvider
    extends
        $FunctionalProvider<
          List<ChartDataPoint>,
          List<ChartDataPoint>,
          List<ChartDataPoint>
        >
    with $Provider<List<ChartDataPoint>> {
  DashboardChartSeriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardChartSeriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardChartSeriesHash();

  @$internal
  @override
  $ProviderElement<List<ChartDataPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChartDataPoint> create(Ref ref) {
    return dashboardChartSeries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChartDataPoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChartDataPoint>>(value),
    );
  }
}

String _$dashboardChartSeriesHash() =>
    r'c4fa9cdf850de4d97b65afe07b140b62b1af2853';
