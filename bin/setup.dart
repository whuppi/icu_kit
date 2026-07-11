// Setup script for icu_kit.
//
//   flutter pub run icu_kit:setup                  # web (default)
//   flutter pub run icu_kit:setup <target>         # web|android|ios|macos|linux|windows
//   flutter pub run icu_kit:setup --force <target> # re-resolve (debugging)
//
// Web: resolves the WASM engine + Diplomat JS bindings into
//   web/icu_kit/. Hash-verified — stale files from a previous version
//   are re-resolved automatically.
// Native: runs `flutter build <target> --debug` which triggers the build
//   hook and caches the binary in Flutter's shared cache.
// --force: web skips the hash check and re-resolves. Native runs
//   `flutter clean` first then rebuilds.
//
// Use `flutter pub run`, NOT `dart run` — native targets
// subprocess `flutter build` which needs flutter on PATH.

import 'dart:io';

import 'package:package_config/package_config.dart';

import '../hook/build.dart' as build;
import 'package:icu_kit/src/hook/resolver.dart';

const _help = '''
Usage: flutter pub run icu_kit:setup [--force] [--lean] [target]

Targets:
  (default)        web
  web              Download/compile WASM + install JS bindings (auto stale detection)
  android          Build + cache native binary for Android
  ios              Build + cache native binary for iOS
  macos            Build + cache native binary for macOS
  linux            Build + cache native binary for Linux
  windows          Build + cache native binary for Windows

Options:
  --lean           Web only: install the lean WASM (no bundled CLDR, ~2 MB
                   instead of ~19 MB). App must load postcards via IcuData.
                   Re-run without --lean to switch back. For native targets
                   the lean switch is the pubspec user_define
                   (hooks: user_defines: icu_kit: bundleCldrData: false).
  --force          Re-resolve target (debugging)
  -h, --help       Show this help
''';

const Map<String, List<String>> _nativeBuildArgs = {
  'android': ['apk', '--debug'],
  'ios': ['ios', '--debug', '--no-codesign'],
  'macos': ['macos', '--debug'],
  'linux': ['linux', '--debug'],
  'windows': ['windows', '--debug'],
};

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    stdout.writeln(_help);
    return;
  }

  final force = args.contains('--force');
  final lean = args.contains('--lean');
  final targets = args.where((a) => !a.startsWith('-')).toList();

  if (targets.isEmpty) {
    targets.add('web');
  }

  if (lean && targets.any((t) => t != 'web')) {
    // Refusing beats silently ignoring: the native lean switch lives in
    // the app's pubspec, and a --lean that "worked" here would hide that.
    stderr.writeln(
      'Error: --lean applies to the web target only. For native targets '
      'set the pubspec user_define instead:\n'
      '  hooks:\n'
      '    user_defines:\n'
      '      icu_kit:\n'
      '        bundleCldrData: false',
    );
    exit(1);
  }

  for (final target in targets) {
    if (target == 'web') {
      await _setupWeb(force, lean: lean);
    } else if (_nativeBuildArgs.containsKey(target)) {
      await _setupNative(target, force);
    } else {
      stderr.writeln('Error: unknown target "$target".');
      stderr.writeln('Valid: web, ${_nativeBuildArgs.keys.join(', ')}');
      exit(1);
    }
  }
}

// ── Web ───────────────────────────────────────────────────────────

Future<void> _setupWeb(bool force, {required bool lean}) async {
  final config = await findPackageConfig(Directory.current);
  if (config == null) {
    stderr.writeln('Error: not inside a Dart/Flutter project.');
    exit(1);
  }

  final pkg = config.packages.where((p) => p.name == 'icu_kit').firstOrNull;
  if (pkg == null) {
    stderr.writeln('Error: icu_kit not in pubspec.yaml.');
    exit(1);
  }

  final packageRoot = pkg.root;
  final version = readVersion(packageRoot);

  stdout.writeln('=== Web assets (v$version${lean ? ', lean' : ''}) ===');
  final destDir = Directory('web/icu_kit');
  final count = await build.resolveWeb(
    packageRoot: packageRoot,
    version: version,
    destDir: destDir,
    force: force,
    lean: lean,
  );
  stdout.writeln(
    count > 0
        ? '$count file(s) installed to ${destDir.path}/'
        : 'All web assets up to date.',
  );
  if (lean) {
    stdout.writeln(
      'Lean WASM installed — no bundled CLDR. Load locale data via '
      'IcuData (postcards) before formatting.',
    );
  }
  stdout.writeln('Add to your app: import "package:icu_kit/icu_kit.dart";');
}

// ── Native ────────────────────────────────────────────────────────

// 'flutter' on PATH is safe here — this script runs via
// `flutter pub run`, so the invoking flutter (bare or FVM)
// adds itself to PATH for child processes.
Future<void> _setupNative(String target, bool force) async {
  final buildArgs = _nativeBuildArgs[target]!;

  stdout.writeln('=== Native ($target) ===');

  if (force) {
    stdout.writeln('  flutter clean');
    final clean = await Process.start('flutter', [
      'clean',
    ], mode: ProcessStartMode.inheritStdio);
    await clean.exitCode;
  }

  stdout.writeln('  flutter build ${buildArgs.join(' ')}');
  final process = await Process.start('flutter', [
    'build',
    ...buildArgs,
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('  Build failed (exit $exitCode).');
    exit(exitCode);
  }
  stdout.writeln('  Native binary cached for $target.');
}
