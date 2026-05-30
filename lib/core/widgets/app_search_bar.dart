import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'dart:async';

void useDebouncer(VoidCallback callback, [Duration duration = const Duration(milliseconds: 300)]) {
  final timer = useRef<Timer?>(null);
  
  useEffect(() {
    return () => timer.value?.cancel();
  }, const []);

  timer.value?.cancel();
  timer.value = Timer(duration, callback);
}

class AppSearchBar extends HookWidget {
  final String? hintText;
  final ValueChanged<String> onChanged;
  
  const AppSearchBar({
    super.key,
    this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void listener() {
        isFocused.value = focusNode.hasFocus;
      }
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    // Use standard Hook approach for debouncing
    final debounceTimer = useRef<Timer?>(null);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (value) {
          debounceTimer.value?.cancel();
          debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
            onChanged(value);
          });
        },
        decoration: InputDecoration(
          hintText: hintText ?? t.common.search,
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: AppDimensions.iconMd,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: AppDimensions.iconMd,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    focusNode.unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: isFocused.value 
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMd,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
