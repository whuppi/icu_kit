// `webEngine` is a web-only selector; on native it is IGNORED, so a
// cross-platform app can call `IcuKit.init(webEngine: WebEngine.browserIntl)`
// everywhere. Here we prove it's a no-op on native: it does NOT throw, and the
// engine stays 'native' (dart:ffi + ICU4X). See docs/PLAN_BROWSER_INTL.md §4c.
@TestOn('vm')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  test('init(webEngine: browser) is a no-op on native (no throw)', () async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
    expect(IcuKit.engine, 'native');
  });

  test('IcuKit.engine is "native" on native', () {
    expect(IcuKit.engine, 'native');
  });
}
