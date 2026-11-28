import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postfolio/core/constants/app_info.dart';

void main() {
  test('AppInfo.fullVersion stays in sync with pubspec.yaml version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(AppInfo.fullVersion, match!.group(1));
  });
}
