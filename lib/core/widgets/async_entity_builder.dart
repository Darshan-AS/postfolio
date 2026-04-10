import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AsyncEntityBuilder<T> extends StatelessWidget {
  final AsyncValue<List<T>> state;
  final String? entityId;
  final String Function(T) idSelector;
  final Widget Function(T? entity) builder;
  final String notFoundMessage;
  final VoidCallback onRetry;

  const AsyncEntityBuilder({
    super.key,
    required this.state,
    required this.entityId,
    required this.idSelector,
    required this.builder,
    required this.notFoundMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (entityId == null) {
      return builder(null);
    }

    return state.when(
      data: (entities) {
        final entity = entities
            .where((e) => idSelector(e) == entityId)
            .firstOrNull;
        if (entity == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.common.error)),
            body: ErrorStateView(message: notFoundMessage),
          );
        }
        return builder(entity);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.common.loading)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(t.common.error)),
        body: ErrorStateView(message: error.toString(), onRetry: onRetry),
      ),
    );
  }
}
