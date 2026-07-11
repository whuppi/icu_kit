// The LEAN WASM, end to end in a real browser — the web half of the
// single-door contract that lean_smoke_test.dart proves for native:
//
//   1. the flavor probe detects the lean wasm (no declaration anywhere),
//   2. init() without lazy data refuses loudly,
//   3. postcards make formatting fully functional,
//   4. an uncovered locale fails loudly, not silently.
//
// Needs `make test-web-lean`, which builds web_assets/icu4x-lean.wasm
// and prepares web_mirror/ — a copy of the committed bindings tree with
// the LEAN wasm installed under the standard icu4x.wasm name (exactly
// the layout `setup --lean` produces in a consumer's web/icu_kit/).
// `dart test -p chrome` serves this package's root over HTTP; the test
// page lives under test/, so the mirror is one level up.
@TestOn('chrome')
library;

import 'dart:js_interop';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url);

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

Future<IcuDataSource> _postcard(String locale) async {
  final url = '../web_mirror/${locale}_minimal.postcard';
  final response = await _fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'postcard fetch failed: $url (${response.status}) — '
      'run via `make test-web-lean`, which prepares web_mirror/.',
    );
  }
  final buffer = (await response.arrayBuffer().toDart).toDart;
  return IcuDataSource.bytes(buffer);
}

void main() {
  setUpAll(() {
    IcuKit.moduleUrl = '../web_mirror/lib/index.mjs';
  });

  test('bundled-data init refuses on the lean wasm', () async {
    await expectLater(
      IcuKit.init(),
      throwsA(
        isA<IcuMissingDataError>().having(
          (e) => e.message,
          'message',
          contains('LEAN'),
        ),
      ),
    );
  });

  test('the probe detected the lean wasm', () {
    // Set by the failed init above — the probe runs before validation.
    expect(IcuKit.hasCompiledData, isFalse);
  });

  test('postcard makes formatting fully functional', () async {
    await IcuKit.init(data: IcuData.lazy(await _postcard('en')));
    await IcuKit.preloadLocale('en');

    final format = IcuNumberFormat.decimal(locale: 'en');
    expect(format.format(1234567.89), '1,234,567.89');
  });

  test('uncovered locale fails loudly', () {
    expect(
      () => IcuNumberFormat.decimal(locale: 'ja'),
      throwsA(isA<IcuError>()),
    );
  });
}
