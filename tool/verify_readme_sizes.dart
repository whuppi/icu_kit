// Verifies that every size number in README.md matches reality.
//
// Direction matters: this tool MEASURES the artifacts, formats each
// measurement the way the README formats sizes, and then asserts the
// README CONTAINS that string. The README is checked against reality —
// there is no stored expectation list that could itself go stale.
//
//   dart run tool/verify_readme_sizes.dart            # measure + verify
//   dart run tool/verify_readme_sizes.dart --strict   # SKIPs become failures
//
// Measured claims:
//   * de.postcard per marker preset (datagen, needs vendor/ + cargo)
//   * fat + lean wasm, raw and gzipped (web_assets/*.wasm; build via
//     `dart run tool/build_wasm.dart [--lean]` when missing)
//   * fat + lean native cdylib (the hook's prebuilt cache; produced by any
//     `dart test` run of the main package (fat) / lean_smoke fixture (lean))
//
// Exit 1 on any mismatch (always) or any SKIP (--strict). Run it after an
// icu4x submodule bump and before a release — see docs/UPDATING.md.
//
// Cross-platform (pure Dart — gzip via dart:io's GZipCodec). Not part of
// `make check` — datagen runs take minutes.

import 'dart:io';

import 'package:icu_kit/src/hook/marker_presets.dart';

const _readmePath = 'README.md';
const _vendor = 'vendor/icu4x';
const _measureLocale = 'de';

/// Presets whose `de.postcard` sizes the README's preset table states,
/// plus the exact-marker-pair row.
const _postcardSpecs = [
  'format-core',
  'format-extended',
  'locale',
  'text',
  'kit',
  'all',
  'DecimalSymbolsV1,PluralsCardinalV1',
];

void main(List<String> args) async {
  final strict = args.contains('--strict');
  final readme = File(_readmePath).readAsStringSync();
  final failures = <String>[];
  final skips = <String>[];
  final passes = <String>[];

  void check(String label, int? bytes) {
    if (bytes == null) {
      skips.add(label);
      return;
    }
    final candidates = _formatCandidates(bytes);
    final hit = candidates.any(readme.contains);
    final shown = candidates.join(' | ');
    if (hit) {
      passes.add('$label → $shown');
    } else {
      failures.add(
        '$label measured $bytes bytes → README contains none of: $shown',
      );
    }
  }

  // ── native cdylibs (hook prebuilt caches) ────────────────────────────
  check('native fat cdylib', _findDylib(lean: false));
  check('native lean cdylib', _findDylib(lean: true));

  // ── wasm, raw + gzipped ──────────────────────────────────────────────
  for (final (label, file) in [
    ('wasm fat raw', 'web_assets/icu4x.wasm'),
    ('wasm lean raw', 'web_assets/icu4x-lean.wasm'),
  ]) {
    final f = File(file);
    if (!f.existsSync()) {
      skips.add('$label ($file missing — dart run tool/build_wasm.dart)');
      skips.add('${label.replaceFirst('raw', 'gzipped')} (same)');
      continue;
    }
    check(label, f.lengthSync());
    check(label.replaceFirst('raw', 'gzipped'), _gzippedSize(file));
  }

  // ── de.postcard per preset (datagen) ─────────────────────────────────
  if (!Directory('$_vendor/provider/icu4x-datagen').existsSync()) {
    skips.add(
      'all postcard sizes (vendor missing — git submodule update --init)',
    );
  } else {
    for (final spec in _postcardSpecs) {
      stderr.writeln('datagen: $_measureLocale / $spec ...');
      check('postcard $spec ($_measureLocale)', _slicePostcard(spec));
    }
  }

  // ── report ───────────────────────────────────────────────────────────
  stdout.writeln('\n── verified against $_readmePath ──');
  for (final p in passes) {
    stdout.writeln('  OK    $p');
  }
  for (final s in skips) {
    stdout.writeln('  SKIP  $s');
  }
  for (final f in failures) {
    stdout.writeln('  STALE $f');
  }
  stdout.writeln(
    '${passes.length} ok, ${skips.length} skipped, ${failures.length} stale',
  );

  if (failures.isNotEmpty || (strict && skips.isNotEmpty)) {
    stdout.writeln(
      failures.isNotEmpty
          ? 'README size numbers are stale — update the README (or the '
                'artifact is wrong).'
          : '--strict: unmeasured claims remain — produce the missing '
                'artifacts and re-run.',
    );
    exit(1);
  }
}

/// Every plausible README rendering of [bytes]. The README writes sizes as
/// "198 B", "68 KB", "5.6 MB", "~16 MB", or "19 MB"; both binary (1024²)
/// and decimal (1000²) MB conventions are accepted so a legitimate rounding
/// choice never raises a false alarm — a genuinely stale number differs in
/// digits, not in convention.
List<String> _formatCandidates(int bytes) {
  if (bytes < 1024) return ['$bytes B'];
  final out = <String>{};
  for (final unit in [1024.0, 1000.0]) {
    final kb = bytes / unit;
    final mb = kb / unit;
    if (mb < 1) {
      out.add('${kb.round()} KB');
      out.add('${mb.toStringAsFixed(1)} MB'); // "0.6 MB" style
    } else {
      out.add('${mb.toStringAsFixed(1)} MB');
      out.add('${mb.round()} MB');
      out.add('~${mb.round()} MB');
    }
  }
  return out.toList();
}

/// The hook caches compiled cdylibs under
/// `.dart_tool/hooks_runner/shared/icu_kit/build/prebuilt/<target>[-lean]/`.
/// The fat cache lives under this package's own .dart_tool (any `dart test`
/// run creates it); the lean cache under the lean_smoke fixture's.
int? _findDylib({required bool lean}) {
  final roots = ['.', 'test_fixtures/lean_smoke', 'example_lean'];
  for (final root in roots) {
    final prebuilt = Directory(
      '$root/.dart_tool/hooks_runner/shared/icu_kit/build/prebuilt',
    );
    if (!prebuilt.existsSync()) continue;
    for (final dir in prebuilt.listSync().whereType<Directory>()) {
      final name = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (name.contains('baked')) continue;
      if (name.contains('lean') != lean) continue;
      for (final f in dir.listSync().whereType<File>()) {
        if (f.path.endsWith('.dylib') ||
            f.path.endsWith('.so') ||
            f.path.endsWith('.dll')) {
          return f.lengthSync();
        }
      }
    }
  }
  return null;
}

int _gzippedSize(String path) =>
    GZipCodec(level: 9).encode(File(path).readAsBytesSync()).length;

/// Runs datagen exactly the way `bin/slice.dart` does and returns the blob
/// size. [spec] is a preset name, 'all', or comma-separated marker names.
int? _slicePostcard(String spec) {
  final markers = resolveMarkerSpec(spec, Directory(_vendor));
  final out = '${Directory.systemTemp.path}/icu_kit_size_check.postcard';
  final r = Process.runSync('cargo', [
    'run',
    '--release',
    '--features=unstable',
    '--manifest-path',
    '$_vendor/provider/icu4x-datagen/Cargo.toml',
    '--',
    '--locales',
    _measureLocale,
    '--markers',
    ...markers,
    '--format',
    'blob',
    '--out',
    out,
    '--overwrite',
  ]);
  if (r.exitCode != 0) {
    stderr.writeln('datagen failed for "$spec": ${r.stderr}');
    return null;
  }
  return File(out).lengthSync();
}
