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
// wasm-opt resolution: the PINNED binaryen release only — installed by
// compile_rust.sh --wasm-opt into a version-keyed cache, hash-verified via
// tool/fetch_verified.sh against the pins in tool/versions.env. No
// Flutter-SDK copy, no $PATH fallback: every build optimizes with the
// same verified binary, so the wasm output is reproducible.
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

/// Feature lists and the base tag come from build.json — the single source
/// of truth the compile script and analysis gate also read. Do not add a
/// features or tag const here; that drifts on the next submodule bump.
String _baseTagFromBuildJson() =>
    (jsonDecode(File('build.json').readAsStringSync())
            as Map<String, dynamic>)['baseTag']
        as String;

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

  // 1. Materialize the pinned wasm-opt. Doing this BEFORE the multi-minute
  //    wasm build means no wasted compute if the download fails.
  final wasmOpt = await _locateWasmOpt(pkgRoot.path);

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

/// Resolves the path to `wasm-opt` — the pinned binaryen release, nothing
/// else.
///
/// Delegates to `tool/compile_rust.sh --wasm-opt`: hash-verified download
/// into a cache keyed by `BINARYEN_VERSION` (so a pin bump structurally
/// invalidates the old binary), then prints the path. Fails loud if the
/// download or verification fails — there is deliberately no Flutter-SDK
/// or $PATH fallback, which would float the wasm-opt version with the
/// environment.
Future<String> _locateWasmOpt(String pkgRoot) async {
  final result = await Process.run('bash', [
    '$pkgRoot/tool/compile_rust.sh',
    '--wasm-opt',
  ], runInShell: Platform.isWindows);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    stderr.writeln('');
    stderr.writeln('  Could not install the pinned wasm-opt (binaryen).');
    stderr.writeln('  The pin lives in tool/versions.env (BINARYEN_*);');
    stderr.writeln(
      '  the download is hash-verified by tool/fetch_verified.sh.',
    );
    stderr.writeln('  Check network access and re-run:');
    stderr.writeln('    fvm dart run tool/build_wasm.dart');
    exit(1);
  }
  final path = result.stdout.toString().trim().split('\n').last;
  final v = await Process.run(path, ['--version']);
  if (v.exitCode != 0) {
    stderr.writeln('  Pinned wasm-opt at $path failed --version.');
    exit(1);
  }
  print('Found ${v.stdout.toString().trim().split('\n').first} (pinned)');
  return path;
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
  print(
    'Building $name from ${_baseTagFromBuildJson()} '
    '(this takes ~70 s clean)...',
  );

  // runInShell on Windows: a bare CreateProcess PATH search finds
  // System32's WSL bash.exe ("no installed distributions") before Git
  // Bash; going through cmd resolves Git Bash, same as _locateWasmOpt.
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
    runInShell: Platform.isWindows,
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
