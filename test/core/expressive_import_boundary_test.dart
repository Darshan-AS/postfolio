import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `.agents/rules/ui.md` §1: the community Material 3 Expressive package is an implementation
/// detail of the `App*` wrappers. If a screen imports it directly, moving a wrapper onto the
/// official `material_ui` widget later would mean touching that screen too.
void main() {
  const allowedDir = 'lib/core/widgets/expressive/';
  const package = 'package:material_3_expressive/';

  test('only lib/core/widgets/expressive/ imports package:material_3_expressive', () {
    final offenders = <String>[];
    var wrappersUsingIt = 0;

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final importsIt = entity.readAsLinesSync().any(
        (line) =>
            (line.startsWith('import ') || line.startsWith('export ')) &&
            line.contains(package),
      );
      if (!importsIt) continue;
      if (path.startsWith(allowedDir)) {
        wrappersUsingIt++;
      } else {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use the App* wrappers from $allowedDir instead of importing $package directly.',
    );
    // Guards the guard: if the wrappers stop using the package, this test checks nothing
    // and the dependency should be removed from pubspec.yaml.
    expect(wrappersUsingIt, greaterThan(0));
  });
}
