import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'dart:async';

class AppSearchBar extends HookWidget {
  final String? hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClose;

  const AppSearchBar({
    super.key,
    this.hintText,
    required this.onChanged,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() => SearchController());
    final focusNode = useFocusNode();
    final debounceTimer = useRef<Timer?>(null);

    // Dispose controller
    useEffect(() => controller.dispose, [controller]);

    // Listen to text changes with debouncing
    useEffect(() {
      void listener() {
        debounceTimer.value?.cancel();
        debounceTimer.value = Timer(AppAnimations.debounce, () {
          onChanged(controller.text);
        });
      }

      controller.addListener(listener);
      return () {
        controller.removeListener(listener);
        debounceTimer.value?.cancel();
      };
    }, [controller]);

    // Rebuild when text changes to update trailing icons
    useListenable(controller);

    useEffect(() {
      if (onClose != null) {
        focusNode.requestFocus();
      }
      return null;
    }, []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: controller,
              focusNode: focusNode,
              hintText: hintText ?? t.common.search,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppDimensions.iconMd,
              ),
              trailing: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      controller.clear();
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: AppDimensions.iconMd,
                    ),
                  ),
              ],
            ),
          ),
          if (onClose != null) ...[
            AppSpacings.gapSm,
            TextButton(onPressed: onClose, child: Text(t.common.cancel)),
          ],
        ],
      ),
    );
  }
}
