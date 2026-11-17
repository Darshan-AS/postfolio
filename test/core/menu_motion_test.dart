import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('every MenuAnchor opens and closes with the official animation', () {
    // `MenuAnchor.animated` is off by default and no theme turns it on.
    final still = <String>[];
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'\bMenuAnchor\(').allMatches(source)) {
        if (!_arguments(source, match.end).contains('animated: true')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          still.add('${file.path}:$line');
        }
      }
    }

    expect(still, isEmpty);
  });

  testWidgets('a detail screen\'s menu fades its entries in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EntityDetailScaffold(
          appBarTitle: 'Customer',
          onEdit: () {},
          onDelete: () async => null,
          deleteDialogTitle: 'Delete',
          deleteDialogContent: 'Delete this customer?',
          header: const SizedBox.shrink(),
          body: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('entity_detail_more_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final delete = find.byKey(const ValueKey('entity_detail_delete_item'));
    double opacity() => tester
        .widgetList<FadeTransition>(
          find.ancestor(of: delete, matching: find.byType(FadeTransition)),
        )
        .map((fade) => fade.opacity.value)
        .fold(1, math.min);

    expect(delete, findsOneWidget);
    expect(opacity(), lessThan(1));

    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}

/// The text between the parenthesis that opens a call at [start] and the one that closes it.
String _arguments(String source, int start) {
  var depth = 1;
  var end = start;
  while (end < source.length && depth > 0) {
    final char = source[end];
    if (char == '(') depth++;
    if (char == ')') depth--;
    end++;
  }
  return source.substring(start, end);
}
