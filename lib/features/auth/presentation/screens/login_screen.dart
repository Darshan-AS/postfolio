import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedShield01,
                color: theme.colorScheme.primary,
                size: 80,
              ),
              const SizedBox(height: AppDimensions.paddingXl),
              Text(
                t.auth.welcome,
                style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                t.auth.signInSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingXxl * 2),
              switch (authState) {
                AuthStateLoading() => const Center(child: CircularProgressIndicator()),
                _ => FilledButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signInWithGoogle();
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedGoogle,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  label: Text(t.auth.signInWithGoogle),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMd,
                    ),
                  ),
                ),
              },
              if (authState is AuthStateError) ...[
                const SizedBox(height: AppDimensions.paddingMd),
                Text(
                  authState.message,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
