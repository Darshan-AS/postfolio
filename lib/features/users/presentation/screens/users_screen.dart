import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/core/routing/route_names.dart';
import 'package:postfolio/features/users/presentation/controllers/users_controller.dart';
import 'package:postfolio/features/users/presentation/widgets/user_card.dart';
import 'package:postfolio/core/theme/app_theme.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the Controller state
    final usersState = ref.watch(usersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Users', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.check_box_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh), 
            // Trigger a manual refresh from the controller
            onPressed: () => ref.refresh(usersControllerProvider),
          ),
        ],
      ),
      // 2. Handle the AsyncValue UI states smoothly
      body: usersState.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found. Add one!'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return UserCard(
                name: user.name,
                phone: user.phone ?? 'No Phone',
                onTap: () => context.push(RouteNames.userDetail(user.id)),
                onEdit: () => context.push(RouteNames.userEdit(user.id)),
                onDelete: () {
                  // Call the controller directly to delete
                  ref.read(usersControllerProvider.notifier).deleteUser(user.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.userCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}
