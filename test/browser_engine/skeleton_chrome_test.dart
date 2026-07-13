// Validates the two JS-shape primitives every class slot is built from, and
// that installing an (empty) browser-engine module + init() succeeds. The
// constructable-with-statics primitive backs the 18 `new`-able classes; if
// setProperty-on-a-Dart-function ever broke, this fails before any family
// does. See docs/PLAN_BROWSER_INTL.md Step 3 gate.
//
// The js_interop primitive checks live behind module_probe (its web half); the
// init path uses only the public API, so this file stays VM-compilable.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'module_probe.dart' as probe;

void main() {
  test(
    'ctorClass is new-able AND carries statics (the 18 `new` classes)',
    () => expect(probe.ctorClassRoundTrips(), isTrue),
  );

  test(
    'staticClass answers callMethod on closure properties (147 paths)',
    () => expect(probe.staticClassRoundTrips(), isTrue),
  );

  test(
    'init(webEngine: browser) succeeds; engine reports browser-intl',
    () async {
      await IcuKit.init(webEngine: WebEngine.browserIntl);
      expect(IcuKit.engine, 'browser-intl');
      expect(IcuKit.hasCompiledData, isTrue);
    },
  );
}
