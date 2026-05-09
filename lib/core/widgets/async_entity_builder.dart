import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AsyncEntityBuilder<T> extends StatelessWidget {
  final AsyncValue<List<T>> state;
  final String? entityId;
  final String Function(T) idSelector;
  final Widget Function(T? entity) builder;
  final String notFoundMessage;
  final VoidCallback onRetry;
  final T? dummyEntity;
  final bool wrapWithScaffold;

  const AsyncEntityBuilder({
    super.key,
    required this.state,
    required this.entityId,
    required this.idSelector,
    required this.builder,
    required this.notFoundMessage,
    required this.onRetry,
    this.dummyEntity,
    this.wrapWithScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    if (entityId == null) {
      return builder(null);
    }

    return switch (state) {
      AsyncData(:final value) => _buildDataState(context, value),
      AsyncError(:final error) => _buildErrorState(context, error.toString()),
      _ => _buildLoadingState(context),
    };
  }

  Widget _buildDataState(BuildContext context, List<T> entities) {
    final entity = entities.where((e) => idSelector(e) == entityId).firstOrNull;
    if (entity == null) {
      final errorView = ErrorStateView(message: notFoundMessage);
      return wrapWithScaffold
          ? Scaffold(
              appBar: AppBar(title: Text(t.common.error)),
              body: errorView,
            )
          : errorView;
    }
    return builder(entity);
  }

  Widget _buildLoadingState(BuildContext context) {
    if (dummyEntity != null) {
      return Skeletonizer(enabled: true, child: builder(dummyEntity));
    }
    const loadingView = Center(child: CircularProgressIndicator());
    return wrapWithScaffold
        ? Scaffold(
            appBar: AppBar(title: Text(t.common.loading)),
            body: loadingView,
          )
        : loadingView;
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final errorView = ErrorStateView(
      message: error,
      onRetry: onRetry,
    );
    return wrapWithScaffold
        ? Scaffold(
            appBar: AppBar(title: Text(t.common.error)),
            body: errorView,
          )
        : errorView;
  }
}
