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
    r'9a85f15d91df3d161f28de7b3b7ba1b1bfc62e33';

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
    r'c25ba1683ce2bac1d4f1af7dc6018e6b5f7f337b';
