import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_animations.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The hint for a search pill [barWidth] wide: [hint] when it fits on one line, and the
/// short "Search..." otherwise. A hint cannot wrap, and a cut one ("Search by accou…") says
/// less than the short one.
///
/// [trailingButtons] is the number of 48dp icon buttons at the end of the pill.
String searchHintThatFits(
  BuildContext context, {
  required String? hint,
  required double barWidth,
  required int trailingButtons,
}) {
  if (hint == null) return t.common.search;

  final theme = SearchBarTheme.of(context);
  final inset =
      theme.padding?.resolve(const {})?.horizontal ?? 2 * AppDimensions.paddingSm;
  // The bar insets its row and then the text field by the same amount; the leading icon
  // and each trailing icon button keep their own width.
  final room =
      barWidth -
      2 * inset -
      AppDimensions.iconMd -
      trailingButtons * kMinInteractiveDimension;
  final painter = TextPainter(
    text: TextSpan(
      text: hint,
      style: theme.hintStyle?.resolve(const {}) ?? Theme.of(context).textTheme.bodyLarge,
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final fits = painter.width <= room;
  painter.dispose();
  return fits ? hint : t.common.search;
}

class AppSearchBar extends HookWidget {
  final String? query;

  /// What can be searched for. Shown when it fits the bar on one line; otherwise the bar
  /// says "Search". A hint cannot wrap, and a cut one ("Search by accou…") says less.
  final String? hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClose;

  /// Icon buttons at the end of the bar.
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
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageMargin),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SearchBar(
                controller: controller,
                focusNode: focusNode,
                hintText: searchHintThatFits(
                  context,
                  hint: hintText,
                  barWidth: constraints.maxWidth,
                  trailingButtons: trailing?.length ?? 0,
                ),
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
          ),
          if (onClose != null) ...[
            AppSpacings.gapSm,
            AppButton.text(label: t.common.cancel, onPressed: onClose),
          ],
        ],
      ),
    );
  }
}
