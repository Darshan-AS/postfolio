import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/features/users/presentation/controllers/users_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.users.deleteUser),
        content: Text(t.users.deleteUserConfirmation),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(usersControllerProvider.notifier)
                  .deleteUser(userId);

              if (!context.mounted) return;

              switch (result) {
                case Success():
                  ctx.pop(); // Dismiss dialog
                  context.pop(); // Pop back to user list
                case Failure(error: final err):
                  ctx.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.users.failedToDeleteUser(error: err.toString()),
                      ),
                    ),
                  );
              }
            },
            child: Text(
              t.common.delete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RouteNames.userEdit(userId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.error,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: usersState.when(
        data: (users) {
          // Find the specific user from the state
          final user = users.where((u) => u.id == userId).firstOrNull;

          if (user == null) {
            return Center(child: Text(t.users.userNotFound));
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            children: [
              const CircleAvatar(
                radius: AppDimensions.iconXl,
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
                child: Icon(Icons.person, size: AppDimensions.iconXl),
              ),
              AppSpacings.gapLg,
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacings.gapXxl,
              Card(
                child: Column(
                  children: [
                    _buildInfoTile(
                      Icons.phone_outlined,
                      t.users.fields.phoneNumber,
                      user.phone ?? t.common.notProvided,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.email_outlined,
                      t.users.fields.emailAddress,
                      user.email ?? t.common.notProvided,
                    ),
                    const Divider(),
                    _buildInfoTile(
                      Icons.home_outlined,
                      t.users.fields.homeAddress,
                      user.address ?? t.common.notProvided,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(usersControllerProvider),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
