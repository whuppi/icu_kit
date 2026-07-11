// Build the WebAssembly artifact + Diplomat-generated JS bindings for the
// web target. Runs the canonical upstream wasm build against our pinned
// vendor/icu4x submodule, then vendors the JS-interop bindings under
// web_assets/.
//
// Usage:
//
//   fvm dart run tool/build_wasm.dart          # bundled-CLDR wasm + bindings
//   fvm dart run tool/build_wasm.dart --lean   # lean wasm only (no CLDR)
//
// Output:
//   web_assets/icu4x.wasm        — bundled CLDR (compiled_data), wasm-opt -Os
//   web_assets/icu4x-lean.wasm   — no CLDR (--lean); postcards required
//   web_assets/lib/*.mjs         — Diplomat-generated JS bindings + runtime
//   web_assets/lib/*.d.ts        — TypeScript types (helpful for js_interop)
//
// The JS bindings are flavor-independent — one committed tree serves both
// wasm variants. A lean wasm simply lacks the compiled-data exports; the
// runtime flavor probe (lib/src/runtime/web/flavor_probe.dart) detects that
// and dispatch never calls the missing functions. --lean therefore skips
// the bindings regen entirely.
//
// wasm-opt resolution:
//   1. Flutter SDK's bundled binary (preferred — Flutter ships it)
//   2. wasm-opt on $PATH (for pure-Dart installs without Flutter)
// Failing to locate either fails the build with an install hint.
//
// The setup script (tool/setup.dart) copies web_assets/* into a consumer
// app's web/icu_kit/ folder so flutter run -d chrome serves them as static
// assets. The Dart-side js_interop mirrors in lib/src/runtime/web/ load
// the wasm at runtime via fetch() relative to the page URL.
//
// Prerequisites:
//   1. ICU4X submodule initialized: `git submodule update --init`
//   2. Rust nightly with rust-src: handled by the upstream build.sh
//
// All build complexity lives in upstream's vendor/icu4x/ffi/capi/build.sh —
// we only invoke it with the right env vars + copy the result.

import 'dart:convert';
import 'dart:io';

const _icu4xTag = 'icu@2.2.0';

/// Feature lists come from build.json (`features.wasm` / `features.wasmLean`)
/// — the single source of truth the compile script and analysis gate also
/// read. Do not add a features const here; that drifts.
String _featuresFromBuildJson(Directory pkgRoot, {required bool lean}) {
  final json =
      jsonDecode(File('${pkgRoot.path}/build.json').readAsStringSync())
          as Map<String, dynamic>;
  final features = json['features'] as Map<String, dynamic>;
  return features[lean ? 'wasmLean' : 'wasm'] as String;
}

void main(List<String> args) async {
  final lean = args.contains('--lean');
  final pkgRoot = Directory.current;
  final submodule = Directory('${pkgRoot.path}/vendor/icu4x');
  if (!File('${submodule.path}/Cargo.lock').existsSync()) {
    stderr.writeln('Missing vendor/icu4x. Run:');
    stderr.writeln('  git submodule update --init');
    exit(1);
  }

  final webAssets = Directory('${pkgRoot.path}/web_assets');
  webAssets.createSync(recursive: true);
  final wasmPath =
      '${webAssets.path}/${lean ? 'icu4x-lean.wasm' : 'icu4x.wasm'}';

  // 1. Locate wasm-opt — prefer Flutter SDK's bundled copy, fall back to PATH.
  //    Verifying BEFORE the multi-minute wasm build means no wasted compute
  //    if binaryen is missing.
  final wasmOpt = await _locateWasmOpt();

  // 2. Build the wasm via upstream's build.sh.
  await _buildWasm(
    submodule: submodule,
    outWasm: wasmPath,
    features: _featuresFromBuildJson(pkgRoot, lean: lean),
  );

  // 3. Vendor the JS bindings (Diplomat regen + copy). Bundled build only —
  //    the bindings are flavor-independent (see header note).
  if (!lean) {
    await _vendorJsBindings(submodule: submodule, webAssets: webAssets);
  }

  // 4. Optimize the wasm with wasm-opt -Os. Mandatory.
  await _optimizeWasm(wasmPath: wasmPath, wasmOpt: wasmOpt);

  print('Done. web_assets/ ready.');
  print('Next: dart run icu_kit:setup (from a consuming app) to install.');
}

/// Resolves the path to `wasm-opt`. Returns the absolute path the rest of the
/// flow should invoke.
///
/// **Resolution order (matches dart2wasm's own bundled-first pattern):**
///   1. Flutter SDK bundle: `$FLUTTER_ROOT/bin/cache/dart-sdk/bin/utils/wasm-opt`
///      Discovered via `flutter --version --machine` → `flutterRoot`.
///      Flutter ships `wasm-opt` (binaryen) inside its SDK so `dart compile
///      wasm` works out of the box; we reuse the same binary so icu_kit
///      consumers don't need to install binaryen separately.
///   2. System PATH: a manually-installed `wasm-opt` (binaryen). Useful for
///      pure-Dart toolchain installs that don't have Flutter, or when the
///      developer wants a newer binaryen than Flutter ships.
///
/// Fails loud with an actionable install hint if neither resolves.
Future<String> _locateWasmOpt() async {
  // Try Flutter SDK first.
  try {
    final result = await Process.run('flutter', [
      '--version',
      '--machine',
    ], runInShell: Platform.isWindows);
    if (result.exitCode == 0) {
      // The output is JSON; extract `flutterRoot` without pulling in
      // dart:convert just to parse one field — this script otherwise has
      // zero deps. A regex match is fine for a well-known shape.
      final stdout = result.stdout.toString();
      final match = RegExp(r'"flutterRoot"\s*:\s*"([^"]+)"').firstMatch(stdout);
      if (match != null) {
        final flutterRoot = match.group(1)!;
        final ext = Platform.isWindows ? '.exe' : '';
        final candidate =
            '$flutterRoot/bin/cache/dart-sdk/bin/utils/wasm-opt$ext';
        if (File(candidate).existsSync()) {
          final v = await Process.run(candidate, ['--version']);
          if (v.exitCode == 0) {
            final version = v.stdout.toString().trim().split('\n').first;
            print('Found $version (Flutter SDK)');
            return candidate;
          }
        }
      }
    }
  } on ProcessException {
    // Flutter not on PATH — fine, fall through to the next strategy.
  }

  // Fall back to PATH.
  try {
    final result = await Process.run('wasm-opt', ['--version']);
    if (result.exitCode == 0) {
      final version = result.stdout.toString().trim().split('\n').first;
      print('Found $version (PATH)');
      return 'wasm-opt';
    }
  } on ProcessException {
    // Not on PATH either — fall through.
  }

  // Neither — fail loud.
  stderr.writeln('');
  stderr.writeln('  wasm-opt (binaryen) is required but was not found.');
  stderr.writeln('');
  stderr.writeln('  Tried:');
  stderr.writeln(
    '    1. Flutter SDK (\$FLUTTER_ROOT/bin/cache/dart-sdk/bin/utils/wasm-opt)',
  );
  stderr.writeln('    2. \$PATH');
  stderr.writeln('');
  stderr.writeln(
    '  If you have Flutter installed: ensure `flutter` is on PATH so',
  );
  stderr.writeln('  this script can locate the bundled wasm-opt.');
  stderr.writeln('');
  stderr.writeln('  If you DO NOT have Flutter, install binaryen manually:');
  stderr.writeln('    macOS:    brew install binaryen');
  stderr.writeln('    Linux:    apt install binaryen   # or build from source');
  stderr.writeln('    Windows:  scoop install binaryen # or download release');
  stderr.writeln(
    '  Source:     https://github.com/WebAssembly/binaryen/releases',
  );
  stderr.writeln('');
  stderr.writeln('  After install, re-run:  fvm dart run tool/build_wasm.dart');
  stderr.writeln('');
  exit(1);
}

/// Runs wasm-opt -Os on the just-built wasm. Replaces the file in place.
///
/// `-Os` is "optimize for size" — strips debug info, dead-code-eliminates,
/// and shrinks the code section. Note the bundled build stays large after
/// optimization: compiled CLDR data is real data, not shrinkable code. The
/// lean build shows the true code size.
/// `--all-features` keeps every wasm feature flag the rustc-emitted module
/// declares; default-feature optimization would refuse to recognize features
/// like reference-types/multi-value that ICU4X's wasm uses.
Future<void> _optimizeWasm({
  required String wasmPath,
  required String wasmOpt,
}) async {
  final inWasm = wasmPath;
  final beforeSize = File(inWasm).statSync().size;

  print('Optimizing ${inWasm.split('/').last} with wasm-opt -Os...');

  // Optimize in-place via a temp file (wasm-opt can't safely write to its
  // input file on every platform).
  final tmpOut = '$inWasm.opt';
  final result = await Process.run(wasmOpt, [
    '-Os',
    '--all-features',
    inWasm,
    '-o',
    tmpOut,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    throw ProcessException(wasmOpt, ['-Os'], '', result.exitCode);
  }

  // Atomic replace.
  File(tmpOut).renameSync(inWasm);

  final afterSize = File(inWasm).statSync().size;
  final savedPct = (1.0 - afterSize / beforeSize) * 100.0;
  print(
    '  → $inWasm '
    '(${(beforeSize / (1024 * 1024)).toStringAsFixed(1)} MB → '
    '${(afterSize / (1024 * 1024)).toStringAsFixed(1)} MB, '
    '-${savedPct.toStringAsFixed(0)}%)',
  );
}

/// Invokes upstream's canonical build.sh with TYPE=dynamic and the wasm32
/// target. The script handles nightly toolchain install, -Zbuild-std, and
/// the size-optimization RUSTFLAGS automatically.
Future<void> _buildWasm({
  required Directory submodule,
  required String outWasm,
  required String features,
}) async {
  final name = outWasm.split('/').last;
  print('Building $name from $_icu4xTag (this takes ~70 s clean)...');

  final result = await Process.start(
    'bash',
    ['ffi/capi/build.sh'],
    workingDirectory: submodule.path,
    environment: {
      'TARGET': 'wasm32-unknown-unknown',
      'TYPE': 'dynamic',
      'OUT': outWasm,
      'FEATURES': features,
      'RUSTFLAGS':
          '-Copt-level=s -Clink-args=-zstack-size=100000 '
          '-Zwasm-c-abi=spec',
    },
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await result.exitCode;
  if (code != 0) {
    throw ProcessException('bash', ['ffi/capi/build.sh'], '', code);
  }

  final size = File(outWasm).statSync().size;
  print('  → $outWasm (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
}

/// Diplomat ships Dart bindings AND JS bindings from the same Rust source.
/// We already regenerate the Dart bindings via tool/regen_bindings.dart;
/// here we vendor the parallel JS output for our js_interop facade to use.
///
/// Like the Dart regen, we invoke `cargo run -p diplomat-gen -- js` from
/// inside the vendored ICU4X workspace. Diplomat-gen writes JS output to
/// upstream's hardcoded path under `ffi/capi/bindings/js/` (and mirrors to
/// `ffi/npm/lib/`). We copy from `bindings/js/` since it sits at the same
/// level as the Dart bindings we already track.
Future<void> _vendorJsBindings({
  required Directory submodule,
  required Directory webAssets,
}) async {
  print('Vendoring Diplomat JS bindings...');

  // Run upstream's diplomat-gen — same canonical pattern as the Dart bindings.
  final cargo = await Process.start(
    'cargo',
    ['run', '-p', 'diplomat-gen', '--', 'js'],
    workingDirectory: submodule.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await cargo.exitCode;
  if (code != 0) throw ProcessException('cargo', [], '', code);

  // Upstream emits JS bindings to ffi/capi/bindings/js/. Copy into web_assets/lib/.
  final upstreamJs = Directory('${submodule.path}/ffi/capi/bindings/js');
  if (!upstreamJs.existsSync()) {
    throw StateError('Upstream JS bindings not found at ${upstreamJs.path}');
  }
  final ourLib = Directory('${webAssets.path}/lib');
  if (ourLib.existsSync()) ourLib.deleteSync(recursive: true);
  ourLib.createSync(recursive: true);

  var count = 0;
  for (final entity in upstreamJs.listSync()) {
    if (entity is File) {
      final name = entity.path.split(Platform.pathSeparator).last;
      entity.copySync('${ourLib.path}${Platform.pathSeparator}$name');
      count++;
    }
  }

  // Write our own diplomat.config.mjs pointing at icu4x.wasm one dir up.
  // Diplomat's diplomat-wasm.mjs reads `cfg['wasm_path']` from this file.
  final configFile = File('${webAssets.path}/diplomat.config.mjs');
  configFile.writeAsStringSync('''
// Auto-written by tool/build_wasm.dart. Do not edit by hand.
// Diplomat's diplomat-wasm.mjs uses cfg['wasm_path'] to locate the binary.
export default {
    wasm_path: new URL('icu4x.wasm', import.meta.url),
};
''');

  print('  → web_assets/lib/ ($count files) + diplomat.config.mjs');
}
