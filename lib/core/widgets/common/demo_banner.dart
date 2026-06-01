import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    return SafeArea(
      bottom: false,
      child: MaterialBanner(
        leading: const Icon(Icons.info_outline),
        content: Text(
          t.common.demoModeActive,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [SizedBox.shrink()],
      ),
    );
  }
}
