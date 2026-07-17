// Chrome half of the drift guard. The built browser-engine module must
// RESOLVE every module-class name the snapshot lists — implemented or a
// throwing stub, never absent (an absent class is a runtime
// `undefined.getProperty(...)` crash when that binding runs). Behavior of the
// resolved classes is the family suites' job, not this one.
//
// A binding/dispatch change fails the VM guard (snapshot drift); once the
// snapshot is regenerated it fails HERE until the shim registers the new
// class. See docs/PLAN_BROWSER_INTL.md §4e.
//
// All js_interop is behind module_probe (its web half); this file stays
// VM-compilable so the VM-import guard is satisfied.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'module_probe.dart' as probe;
import 'surface_snapshot.g.dart';
import 'surface_spec.dart';

void main() {
  final names = parseClasses(moduleClassesSnapshot.trim());
  setUpAll(() => IcuKit.init(webEngine: WebEngine.browserIntl));

  test('snapshot has 81 module classes', () => expect(names.length, 81));

  group('every module class resolves on the built module', () {
    for (final name in names) {
      test(name, () {
        expect(
          probe.moduleResolves(name),
          isTrue,
          reason: '$name missing from the shim module',
        );
      });
    }
  });

  test('an unimplemented (throw-all) class throws on construction', () {
    // Bidi is a permanent THROW capability; constructing it via the module
    // must raise IcuUnsupportedError (which the facade rethrows unchanged).
    expect(probe.constructingThrowsUnsupported('Bidi'), isTrue);
  });

  test('a throw-all static throws when called', () {
    expect(
      probe.staticThrowsUnsupported('CodePointSetData', 'createAlphabetic'),
      isTrue,
    );
  });
}
