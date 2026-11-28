import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Shared network-photo-with-initial content used by both [AgentAvatarButton]
/// and `ProfileScreen` headers.
class AgentAvatarPhoto extends StatelessWidget {
  const AgentAvatarPhoto({
    super.key,
    required this.initial,
    required this.photoUrl,
    this.textStyle,
  });

  final String initial;
  final String? photoUrl;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Text(
      initial,
      style:
          textStyle ??
          AppTypography.emphasizedOf(
            context,
          ).labelLarge?.copyWith(color: scheme.onPrimaryContainer),
    );
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return fallback;

    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: fallback),
      ),
    );
  }
}

/// Trailing avatar button in [ShellAppBar] and [AppNavigationRail] that opens Profile.
class AgentAvatarButton extends HookConsumerWidget {
  const AgentAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = useMemoized(() => UniqueKey().toString());
    final heroTag = EntityHero.tagFrom(origin, AppConstants.selfHeroId);

    AuthUser? authUser;
    try {
      final authState = ref.watch(authControllerProvider);
      authUser = switch (authState) {
        AuthStateAuthenticated(:final user) => user,
        _ => null,
      };
    } catch (_) {
      // Standalone widget tests may mount ShellAppBar without Supabase/AuthRepository.
    }

    AgentProfile? profile;
    try {
      profile = ref.watch(profileControllerProvider).value;
    } catch (_) {
      // Gracefully fall back to AuthUser or default initial.
    }

    bool isDemoMode = false;
    try {
      isDemoMode = ref.watch(demoModeProvider);
    } catch (_) {
      // Isolated tests may omit SharedPreferences overrides.
    }

    final effective = AgentProfile.effectiveFrom(profile, authUser);
    final initial = effective.resolveInitial(fallbackUser: authUser);
    final photoUrl = isDemoMode ? null : authUser?.photoUrl;
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      key: const ValueKey('shell_account_avatar_button'),
      tooltip: t.settings.profileTitle,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: AppDimensions.actionButtonSize,
        height: AppDimensions.actionButtonSize,
      ),
      onPressed: () => ProfileRoute($extra: origin).push(context),
      icon: EntityHero(
        tag: heroTag,
        part: EntityHeroPart.avatar,
        child: AppShapeAvatar(
          size: AppDimensions.iconLg,
          shape: AppAvatarShape.cookie9,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: AgentAvatarPhoto(initial: initial, photoUrl: photoUrl),
        ),
      ),
    );
  }
}
