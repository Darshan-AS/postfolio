import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

part 'local_backend_banner.g.dart';

/// Pure visibility rule for [LocalBackendBanner]: shown only on a local-stack build when
/// Demo Mode is not active (Demo Mode uses in-memory fixtures and shows [DemoBanner]).
bool shouldShowLocalBackendBanner({
  required bool isLocalBackend,
  required bool isDemoMode,
}) => isLocalBackend && !isDemoMode;

/// Whether the compact local-backend strip is shown at the top of the shell: only in a
/// build targeting the local Supabase stack (`config/local.json`) and never while Demo Mode
/// (in-memory fixtures) is active. Tests override it.
@riverpod
bool localBackendBannerVisible(Ref ref) => shouldShowLocalBackendBanner(
  isLocalBackend: Env.isLocalBackend,
  isDemoMode: ref.watch(demoModeProvider),
);

/// Compact, non-intrusive top strip distinguishing a local-stack build (`config/local.json`)
/// from production — particularly helpful on Web and macOS where there is no Android flavor
/// launcher icon.
class LocalBackendBanner extends ConsumerWidget {
  const LocalBackendBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(localBackendBannerVisibleProvider)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Sits under the status bar in place of the app bar, so declare icon brightness explicitly
    // (same invariant as DemoBanner).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: scheme.secondaryContainer,
        child: SafeArea(
          bottom: false,
          child: Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
                vertical: AppDimensions.paddingXs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedDatabase,
                    size: AppDimensions.iconSm,
                    color: scheme.onSecondaryContainer,
                  ),
                  AppSpacings.gapXs,
                  Flexible(
                    child: Text(
                      t.common.localBackendActive,
                      style: AppTypography.emphasizedOf(context).labelMedium
                          ?.copyWith(color: scheme.onSecondaryContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
