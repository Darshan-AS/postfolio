import 'dart:io';

/// Parses `coverage/lcov.info`, strips generated & one-off migration files, prints a concise
/// per-layer DDD coverage breakdown, and enforces ratcheting layer & total floors in CI.
///
/// Usage:
///   flutter test --exclude-tags integration --coverage
///   dart run tool/check_coverage.dart --min-domain=72 --min-controllers=68 --min-total=44
void main(List<String> args) {
  var lcovPath = 'coverage/lcov.info';
  var minTotal = 0.0;
  var minDomain = 0.0;
  var minControllers = 0.0;
  var minData = 0.0;
  var minUi = 0.0;

  for (final arg in args) {
    if (arg.startsWith('--min=') || arg.startsWith('--min-total=')) {
      minTotal = double.parse(arg.split('=').last);
    } else if (arg.startsWith('--min-domain=')) {
      minDomain = double.parse(arg.split('=').last);
    } else if (arg.startsWith('--min-controllers=')) {
      minControllers = double.parse(arg.split('=').last);
    } else if (arg.startsWith('--min-data=')) {
      minData = double.parse(arg.split('=').last);
    } else if (arg.startsWith('--min-ui=')) {
      minUi = double.parse(arg.split('=').last);
    } else if (arg.startsWith('--file=')) {
      lcovPath = arg.split('=').last;
    }
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: $lcovPath');
    stderr.writeln('Run `flutter test --exclude-tags integration --coverage` first.');
    exit(2);
  }

  const domainKey = 'domain & core';
  const controllersKey = 'controllers & providers';
  const dataKey = 'data & repositories';
  const uiKey = 'presentation UI & routing';

  final buckets = <String, ({int hit, int found})>{
    domainKey: (hit: 0, found: 0),
    controllersKey: (hit: 0, found: 0),
    dataKey: (hit: 0, found: 0),
    uiKey: (hit: 0, found: 0),
  };

  String? currentFile;
  var fileHit = 0;
  var fileFound = 0;

  void flush() {
    final path = currentFile;
    if (path != null && !_isExcluded(path) && fileFound > 0) {
      final bucket = _classify(path);
      final prev = buckets[bucket]!;
      buckets[bucket] = (hit: prev.hit + fileHit, found: prev.found + fileFound);
    }
    currentFile = null;
    fileHit = 0;
    fileFound = 0;
  }

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      flush();
      currentFile = line.substring(3).replaceAll(r'\', '/');
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        fileFound++;
        if ((int.tryParse(parts[1]) ?? 0) > 0) fileHit++;
      }
    } else if (line == 'end_of_record') {
      flush();
    }
  }
  flush();

  double pctOf(({int hit, int found}) b) =>
      b.found == 0 ? 0.0 : (b.hit * 100.0 / b.found);

  var totalHit = 0;
  var totalFound = 0;
  stdout.writeln('--- Postfolio Hand-Written Coverage (excluding *.g.dart / *.freezed.dart) ---');
  for (final entry in buckets.entries) {
    totalHit += entry.value.hit;
    totalFound += entry.value.found;
    final pct = pctOf(entry.value);
    stdout.writeln(
      '  ${entry.key.padRight(27)} ${pct.toStringAsFixed(1).padLeft(5)}%  '
      '(${entry.value.hit}/${entry.value.found} lines)',
    );
  }

  final totalPct = totalFound == 0 ? 0.0 : (totalHit * 100.0 / totalFound);
  stdout.writeln(
    '  ${"TOTAL (hand-written)".padRight(27)} ${totalPct.toStringAsFixed(1).padLeft(5)}%  '
    '($totalHit/$totalFound lines)',
  );

  final failures = <String>[];
  final domainPct = pctOf(buckets[domainKey]!);
  final controllersPct = pctOf(buckets[controllersKey]!);
  final dataPct = pctOf(buckets[dataKey]!);
  final uiPct = pctOf(buckets[uiKey]!);

  if (domainPct < minDomain) {
    failures.add(
      '$domainKey ${domainPct.toStringAsFixed(1)}% < ${minDomain.toStringAsFixed(1)}%',
    );
  }
  if (controllersPct < minControllers) {
    failures.add(
      '$controllersKey ${controllersPct.toStringAsFixed(1)}% < ${minControllers.toStringAsFixed(1)}%',
    );
  }
  if (dataPct < minData) {
    failures.add(
      '$dataKey ${dataPct.toStringAsFixed(1)}% < ${minData.toStringAsFixed(1)}%',
    );
  }
  if (uiPct < minUi) {
    failures.add(
      '$uiKey ${uiPct.toStringAsFixed(1)}% < ${minUi.toStringAsFixed(1)}%',
    );
  }
  if (totalPct < minTotal) {
    failures.add(
      'TOTAL ${totalPct.toStringAsFixed(1)}% < ${minTotal.toStringAsFixed(1)}%',
    );
  }

  if (failures.isNotEmpty) {
    for (final f in failures) {
      stderr.writeln('FAILED COVERAGE RATCHET: $f');
    }
    exit(1);
  }
}

bool _isExcluded(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('firebase_options.dart');

String _classify(String path) {
  if (path.contains('/domain/') ||
      path.contains('/core/env/') ||
      path.contains('/core/models/') ||
      path.contains('/core/services/') ||
      path.contains('/core/enums/') ||
      path.contains('/core/extensions/') ||
      path.contains('/core/utils/')) {
    return 'domain & core';
  }
  if (path.contains('/controllers/') || path.contains('/providers/')) {
    return 'controllers & providers';
  }
  if (path.contains('/data/') || path.contains('/core/mocks/')) {
    return 'data & repositories';
  }
  return 'presentation UI & routing';
}
