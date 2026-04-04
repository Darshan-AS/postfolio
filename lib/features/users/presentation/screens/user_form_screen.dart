import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/features/users/domain/user_model.dart';
import 'package:postfolio/features/users/presentation/controllers/users_controller.dart';
import 'package:postfolio/core/theme/app_theme.dart';

class UserFormScreen extends ConsumerWidget {
  final String? userId;

  const UserFormScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const _UserForm(existingUser: null);
    }

    final usersState = ref.watch(usersControllerProvider);

    return usersState.when(
      data: (users) {
        final user = users.where((u) => u.id == userId).firstOrNull;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('User not found')),
          );
        }
        return _UserForm(existingUser: user);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  final User? existingUser;

  const _UserForm({this.existingUser});

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingUser?.name);
    _emailController = TextEditingController(text: widget.existingUser?.email);
    _phoneController = TextEditingController(text: widget.existingUser?.phone);
    _addressController = TextEditingController(text: widget.existingUser?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(usersControllerProvider.notifier).saveUser(
          id: widget.existingUser?.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        );

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.existingUser != null;
    final isLoading = ref.watch(usersControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdating ? 'Edit User' : 'New User'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              color: AppTheme.primary,
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: User.validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: User.validatePhone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: User.validateEmail,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _save,
              child: isLoading 
                  ? const Text('Saving...') 
                  : const Text('Save User'),
            ),
          ],
        ),
      ),
    );
  }
}
