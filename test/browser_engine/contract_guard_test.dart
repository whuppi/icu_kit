// The drift radar for the browser-engine shim (VM half). Re-derives, from the
// SHIPPED web bindings + dispatch, the set of module classes the shim must
// register — every class reached via `IcuKit.module.getProperty('X')` — and
// asserts it equals the reviewed snapshot. A binding/dispatch change (icu4x
// bump, regen) shifts the set; if the snapshot wasn't regenerated, this fails
// and says how.
//
// The chrome half (contract_guard_chrome_test.dart) asserts the built shim
// module resolves every name (implemented or throw-all stub). Finer
// correctness — that each formatter/option/segmenter actually behaves — is
// the family suites' job, not source parsing. See docs/PLAN_BROWSER_INTL.md
// §4e.
@TestOn('vm')
library;

import 'package:test/test.dart';

// The dart:io extractor lives in tool/ (kept out of test/ so the VM-import
// guard doesn't flag it); the pure serialize/parse spec stays here.
import '../../tool/browser_engine/surface_extractor.dart';
import 'surface_snapshot.g.dart';
import 'surface_spec.dart';

void main() {
  group('browser-engine contract guard (VM)', () {
    final derived = deriveModuleClasses();

    test('derived module-class set equals the committed snapshot', () {
      // .trim(): the generated raw-string literal wraps the payload in
      // newlines; names have no edge whitespace.
      final snapshot = parseClasses(moduleClassesSnapshot.trim());
      expect(
        serializeClasses(derived),
        serializeClasses(snapshot),
        reason:
            'The web binding/dispatch module-class set changed but the '
            'committed snapshot did not. Regenerate it:\n'
            '  fvm dart run tool/browser_engine/gen_surface_snapshot.dart\n'
            'then register (or throw-all-stub) the new/renamed classes in '
            'lib/src/runtime/web_intl/ until the chrome guard passes.',
      );
    });

    test('module-class count is 77', () {
      expect(derived.length, 77);
    });
  });
}
