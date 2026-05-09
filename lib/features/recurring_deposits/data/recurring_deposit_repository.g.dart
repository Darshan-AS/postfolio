// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_deposit_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurringDepositRepository)
final recurringDepositRepositoryProvider =
    RecurringDepositRepositoryProvider._();

final class RecurringDepositRepositoryProvider
    extends
        $FunctionalProvider<
          RecurringDepositRepository,
          RecurringDepositRepository,
          RecurringDepositRepository
        >
    with $Provider<RecurringDepositRepository> {
  RecurringDepositRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringDepositRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringDepositRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecurringDepositRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurringDepositRepository create(Ref ref) {
    return recurringDepositRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringDepositRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringDepositRepository>(value),
    );
  }
}

String _$recurringDepositRepositoryHash() =>
    r'8d83ce025fe7cb1c78226ee880bd669d9d750381';
