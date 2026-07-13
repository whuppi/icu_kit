// The locale-error law on the BROWSER engine: every public entry point that
// takes a BCP-47 tag throws IcuLocaleParseError on an unparseable tag — the
// same 27-case battery the wasm runner uses, so both engines prove the law
// from ONE source. On the browser engine the throw comes from the shim's
// Locale.fromString (Intl.getCanonicalLocales → RangeError); the facades all
// parse the locale before touching their formatter, so bad tags surface as
// IcuLocaleParseError even where the formatter itself is still a throw-all.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import '../batteries/locale_grammar_battery.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  registerLocaleGrammarBattery(allLocaleLawCases());
}
