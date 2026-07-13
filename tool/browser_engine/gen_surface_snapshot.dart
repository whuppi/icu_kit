// Regenerates test/browser_engine/surface_snapshot.g.dart — the reviewed set
// of module-class names the browser-engine shim must register (see
// surface_extractor.dart). Run from the package root when the binding/dispatch
// surface changes; the VM contract guard fails until this is current, and the
// chrome guard fails until the shim registers (or throw-all-stubs) every name.
//
//   fvm dart run tool/browser_engine/gen_surface_snapshot.dart
//
// The generated file is test data, so it lives under test/; this generator
// lives under tool/ with the extractor (both use dart:io).
import 'dart:io';

import 'surface_extractor.dart';

// The pure serialize/parse spec stays in test/ (gate-clean, and the chrome
// guard parses the snapshot at runtime); the generator reaches into test/ for
// it — the same coupling as writing the snapshot there.
import '../../test/browser_engine/surface_spec.dart';

void main() {
  final text = serializeClasses(deriveModuleClasses());
  final n = text.split('\n').length;
  File('test/browser_engine/surface_snapshot.g.dart').writeAsStringSync('''
// GENERATED — do not edit. Regenerate with:
//   fvm dart run tool/browser_engine/gen_surface_snapshot.dart
//
// The reviewed set of module classes the browser-engine shim must register:
// every class the web bindings + dispatch reach via
// `IcuKit.module.getProperty('X')`. The VM contract guard asserts the freshly
// derived set equals this; the chrome guard asserts the built module resolves
// every name. See docs/PLAN_BROWSER_INTL.md §4e.

/// One module-class name per line, sorted. Parse with `parseClasses`.
const moduleClassesSnapshot = r"""
$text
""";
''');
  stdout.writeln(
    'wrote test/browser_engine/surface_snapshot.g.dart ($n names)',
  );
}
