import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(demoModeProvider);

    if (!isDemoMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // The banner sits where the app bar would, so it is what the status bar is drawn over.
    // An app bar says which icons suit it; without the same here the status bar keeps
    // whatever was last asked for, such as the light icons of a dialog's scrim.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: MaterialBanner(
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: AppDimensions.iconMd,
            color: scheme.onTertiaryContainer,
          ),
          content: Text(
            t.common.demoModeActive,
            style: AppTypography.emphasizedOf(
              context,
            ).bodyMedium?.copyWith(color: scheme.onTertiaryContainer),
          ),
          actions: [
            AppButton.text(
              key: const ValueKey('exit_demo_mode_button'),
              label: t.common.exitDemoMode,
              onPressed: () {
                ref.read(demoModeProvider.notifier).disable();
              },
            ),
          ],
        ),
      ),
    );
  }
}
