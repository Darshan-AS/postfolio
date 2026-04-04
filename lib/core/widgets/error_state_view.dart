import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline, 
              size: AppDimensions.iconXl, 
              color: AppTheme.error,
            ),
            AppSpacings.gapLg,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (onRetry != null) ...[
              AppSpacings.gapLg,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(t.common.retry),
              ),
            ]
          ],
        ),
      ),
    );
  }
}