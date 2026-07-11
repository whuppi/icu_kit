// Regenerate Diplomat-emitted Dart FFI bindings from the vendored ICU4X
// Rust source.
//
// Run after bumping vendor/icu4x to a new release tag, or when ICU4X's
// Diplomat-annotated FFI surface changes:
//
//   fvm dart run tool/regen_bindings.dart
//
// Prerequisite: ICU4X submodule initialized:
//   git submodule update --init
//
// No global tool installation required. We invoke ICU4X's own `diplomat-gen`
// binary via `cargo run -p diplomat-gen`, which Cargo builds on demand from
// the vendored source. That's the canonical Diplomat pattern (see Diplomat's
// own Makefile.toml and ICU4X's tools/make/diplomat-gen).
//
// Output: lib/src/runtime/native/bindings/*.g.dart (175 part files + lib.g.dart barrel).
// `diplomat-gen` writes to upstream's hardcoded path
// (vendor/icu4x/ffi/dart/lib/src/bindings) which we then move into ours.
// The build hook registers the asset under the path of our lib.g.dart, so
// the `@Native` symbols inside the generated parts resolve to libicu_capi.

import 'dart:io';

const _icu4xTag = 'icu@2.2.0';

void main(List<String> args) async {
  final pkgRoot = Directory.current;
  final submodule = Directory('${pkgRoot.path}/vendor/icu4x');
  if (!File('${submodule.path}/Cargo.lock').existsSync()) {
    stderr.writeln('Missing vendor/icu4x. Run:');
    stderr.writeln('  git submodule update --init');
    exit(1);
  }

  final upstreamOut = Directory('${submodule.path}/ffi/dart/lib/src/bindings');
  final ours = Directory('${pkgRoot.path}/lib/src/runtime/native/bindings');

  print('Regenerating Dart bindings from $_icu4xTag');
  print('  cargo run -p diplomat-gen -- dart');
  print('  (in ${submodule.path})');

  final cargo = await Process.start(
    'cargo',
    ['run', '-p', 'diplomat-gen', '--', 'dart'],
    workingDirectory: submodule.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await cargo.exitCode;
  if (code != 0) {
    stderr.writeln('cargo run -p diplomat-gen failed (exit $code)');
    exit(code);
  }

  if (!upstreamOut.existsSync()) {
    stderr.writeln(
      'Expected ${upstreamOut.path} to exist after diplomat-gen ran. '
      'Did upstream change its output path?',
    );
    exit(1);
  }

  // Replace our bindings dir with the freshly-generated upstream output.
  if (ours.existsSync()) {
    ours.deleteSync(recursive: true);
  }
  ours.parent.createSync(recursive: true);
  await _copyDir(upstreamOut, ours);

  // Dart 3.12+ requires @RecordUse classes to be final; the vendored
  // Diplomat still emits a non-final _DiplomatFfiUse. Post-fix the copy
  // until the vendor's Diplomat catches up (drop this when a regen no
  // longer changes the line).
  final libG = File('${ours.path}${Platform.pathSeparator}lib.g.dart');
  if (libG.existsSync()) {
    final src = libG.readAsStringSync();
    libG.writeAsStringSync(
      src.replaceFirst(
        'class _DiplomatFfiUse {',
        'final class _DiplomatFfiUse {',
      ),
    );
  }

  final files = ours.listSync().whereType<File>().toList();
  print('  ${files.length} files in lib/src/runtime/native/bindings/');
  print('Done. Run `fvm dart analyze` to verify.');
}

Future<void> _copyDir(Directory src, Directory dst) async {
  dst.createSync(recursive: true);
  for (final e in src.listSync(recursive: false)) {
    final name = e.path.split(Platform.pathSeparator).last;
    if (e is File) {
      e.copySync('${dst.path}${Platform.pathSeparator}$name');
    } else if (e is Directory) {
      await _copyDir(e, Directory('${dst.path}${Platform.pathSeparator}$name'));
    }
  }
}
