import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Persistent top banner displayed while an admin is acting as another agent.
/// Mounted in [MaterialApp.router]'s builder so it stays pinned across tabs,
/// pushed detail screens, and form screens.
class ActingAsBanner extends ConsumerWidget {
  const ActingAsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actingAs = ref.watch(actingAsControllerProvider);
    if (actingAs is! ActingAsStateActive) {
      return const SizedBox.shrink();
    }

    final targetAgent = actingAs.targetAgent;
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = scheme.errorContainer;
    final foregroundColor = scheme.onErrorContainer;
    final overlayBrightness = ThemeData.estimateBrightnessForColor(
      backgroundColor,
    );

    Future<void> handleExit() async {
      final router = GoRouter.maybeOf(context);
      final rootRouter = (router == null && Navigator.maybeOf(context) == null)
          ? ref.read(goRouterProvider)
          : null;
      await ref.read(actingAsControllerProvider.notifier).stopActingAs();
      if (router != null) {
        router.go(const DashboardRoute().location);
      } else if (rootRouter != null) {
        rootRouter.go(const DashboardRoute().location);
      }
    }

    // The banner sits at the top of the viewport where an app bar would, so it owns the
    // status bar colour and icon brightness.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayBrightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Material(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: MaterialBanner(
            key: const ValueKey('acting_as_banner'),
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            dividerColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsetsDirectional.only(
              start: AppDimensions.paddingLg,
              top: AppDimensions.paddingSm,
              end: AppDimensions.paddingLg,
              bottom: AppDimensions.paddingNone,
            ),
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedUserSwitch,
              size: AppDimensions.iconMd,
              color: foregroundColor,
            ),
            content: Text(
              t.admin.actingAs(name: targetAgent.displayLabel),
              style: AppTypography.emphasizedOf(
                context,
              ).bodyMedium?.copyWith(color: foregroundColor),
            ),
            actions: [
              AppButton.text(
                key: const ValueKey('acting_as_exit_button'),
                label: t.admin.exitActingAs,
                foregroundColor: foregroundColor,
                onPressed: handleExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
