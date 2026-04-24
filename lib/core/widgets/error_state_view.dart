import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXl,
              color: Theme.of(context).colorScheme.error,
            ),
            AppSpacings.gapLg,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              AppSpacings.gapLg,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(t.common.retry),
              ),
            ],
          ],
        ).animate().fade(duration: AppAnimations.slow).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: AppAnimations.slow,
              curve: AppAnimations.bounceCurve,
            ),
      ),
    );
  }
}
