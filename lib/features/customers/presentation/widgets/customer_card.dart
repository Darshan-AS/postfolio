import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/intent_service.dart';

class CustomerCard extends ConsumerWidget {
  final String name;
  final String phone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            AppSpacings.gapXs,
            Text(
              phone,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            AppSpacings.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.error,
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () =>
                      ref.read(intentServiceProvider).launchPhone(phone),
                ),
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () =>
                      ref.read(intentServiceProvider).launchSms(phone),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () =>
                      ref.read(intentServiceProvider).launchMapSearch(name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
