import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/features/users/presentation/controllers/users_controller.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(usersControllerProvider.notifier).deleteUser(userId);
              ctx.pop(); // Dismiss dialog
              context.pop(); // Pop back to user list
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
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
            return const Center(child: Text('User not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
                child: Icon(Icons.person, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    _buildInfoTile(Icons.phone_outlined, 'Phone Number', user.phone ?? 'Not provided'),
                    const Divider(),
                    _buildInfoTile(Icons.email_outlined, 'Email Address', user.email ?? 'Not provided'),
                    const Divider(),
                    _buildInfoTile(Icons.home_outlined, 'Home Address', user.address ?? 'Not provided'),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
    );
  }
}
