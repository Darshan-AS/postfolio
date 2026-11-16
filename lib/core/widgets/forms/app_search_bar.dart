import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AppSearchBar extends HookWidget {
  final String? query;
  final String? hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClose;
  final List<Widget>? trailing;

  const AppSearchBar({
    super.key,
    this.query,
    this.hintText,
    required this.onChanged,
    this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() {
      final c = SearchController();
      if (query != null && query!.isNotEmpty) {
        c.text = query!;
      }
      return c;
    });
    final focusNode = useFocusNode();
    final debounceTimer = useRef<Timer?>(null);
    final syncingExternalRef = useRef<bool>(false);

    useEffect(() => controller.dispose, [controller]);

    // Sync external query resets (e.g. "Clear Filters" or state initialization)
    // without re-triggering a debounced write.
    useEffect(() {
      if (query != null && controller.text != query) {
        if (query!.isEmpty || !focusNode.hasFocus) {
          debounceTimer.value?.cancel();
          syncingExternalRef.value = true;
          controller.text = query!;
          syncingExternalRef.value = false;
        }
      }
      return null;
    }, [query]);

    useEffect(() {
      void listener() {
        if (syncingExternalRef.value) return;
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
                    tooltip: t.common.clear,
                    onPressed: () {
                      debounceTimer.value?.cancel();
                      controller.clear();
                      onChanged('');
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                ...?trailing,
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
