import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(demoModeProvider);

    if (!isDemoMode) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: MaterialBanner(
        leading: HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          size: AppDimensions.iconMd,
          color: scheme.primary,
        ),
        content: Text(
          t.common.demoModeActive,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            key: const ValueKey('exit_demo_mode_button'),
            onPressed: () {
              ref.read(demoModeProvider.notifier).disable();
            },
            child: Text(t.common.exitDemoMode),
          ),
        ],
      ),
    );
  }
}
