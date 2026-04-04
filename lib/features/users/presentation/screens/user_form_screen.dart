import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postfolio/features/users/domain/user_model.dart';
import 'package:postfolio/features/users/presentation/controllers/users_controller.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/l10n/app_localizations.dart';

class UserFormScreen extends ConsumerWidget {
  final String? userId;

  const UserFormScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const _UserForm(existingUser: null);
    }

    final usersState = ref.watch(usersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return usersState.when(
      data: (users) {
        final user = users.where((u) => u.id == userId).firstOrNull;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.error)),
            body: ErrorStateView(
              message: l10n.userNotFound,
            ),
          );
        }
        return _UserForm(existingUser: user);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(usersControllerProvider),
        ),
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
      final result = await ref.read(usersControllerProvider.notifier).saveUser(
        id: widget.existingUser?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      switch (result) {
        case Success():
          context.pop();
        case Failure(error: final err):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToSaveUser(err))),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.existingUser != null;
    final isLoading = ref.watch(usersControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdating ? l10n.editUser : l10n.newUser),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
              child: Center(
                child: SizedBox(
                  width: AppDimensions.iconMd,
                  height: AppDimensions.iconMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              color: AppTheme.primary,
              onPressed: _save,
              tooltip: l10n.saveUser,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: User.validateName,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: User.validatePhone,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.emailAddress,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: User.validateEmail,
              textInputAction: TextInputAction.next,
            ),
            AppSpacings.gapLg,
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.homeAddress,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home_outlined),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            AppSpacings.gapXxl,
            ElevatedButton(
              onPressed: isLoading ? null : _save,
              child: isLoading 
                  ? Text(l10n.saving) 
                  : Text(l10n.saveUser),
            ),
          ],
        ),
      ),
    );
  }
}
