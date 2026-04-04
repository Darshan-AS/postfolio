import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/features/users/presentation/widgets/user_card.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Users', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.check_box_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        itemCount: 5, // Placeholder count
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          return UserCard(
            name: 'Abdul Khalandar $index',
            phone: '914817320$index',
            onTap: () => context.push('/users/$index'), // Navigate to detail
            onEdit: () => context.push('/users/$index/edit'), // Navigate to edit
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/users/new'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
