import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isSigningIn = authState is AuthStateLoading;

    final heroItems = <Widget>[
      // The brand mark on a large Material shape: the welcome's focal point.
      const AppShapeAvatar(
        shape: AppAvatarShape.softBurst,
        // Opens from a circle as the screen arrives: once, then it is still.
        opensFrom: AppAvatarShape.circle,
        size: AppDimensions.avatarXl,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedShield01,
          size: AppDimensions.iconXl,
        ),
      ),
      AppSpacings.gapXl,
      Text(
        t.auth.welcome,
        style: AppTypography.emphasizedOf(context).displaySmall,
        textAlign: TextAlign.center,
      ),
      AppSpacings.gapSm,
      Text(
        t.auth.signInSubtitle,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageMargin),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxLoginWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: disableAnimations
                        ? heroItems
                        : heroItems
                              .animate(interval: AppAnimations.stagger)
                              .fadeIn(duration: AppAnimations.medium)
                              .slideY(
                                begin: AppAnimations.slideOffset,
                                curve: AppAnimations.defaultCurve,
                                duration: AppAnimations.medium,
                              ),
                  ),
                  AppSpacings.gapXxl,
                  AppSpacings.gapXxl,
                  // While signing in, the main button carries the loading indicator and the
                  // demo entry is unavailable, as both were while a spinner replaced them.
                  AppButton(
                    label: t.auth.signInWithGoogle,
                    icon: HugeIcons.strokeRoundedGoogle,
                    size: AppButtonSize.medium,
                    expand: true,
                    isLoading: isSigningIn,
                    onPressed: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle();
                    },
                  ),
                  AppSpacings.gapSm,
                  Center(
                    child: AppButton.text(
                      label: t.auth.tryDemoMode,
                      icon: HugeIcons.strokeRoundedPlay,
                      onPressed: isSigningIn
                          ? null
                          : () {
                              ref.read(demoModeProvider.notifier).enable();
                            },
                    ),
                  ),
                  if (authState case AuthStateError(:final message)) ...[
                    AppSpacings.gapMd,
                    Text(
                      message,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
