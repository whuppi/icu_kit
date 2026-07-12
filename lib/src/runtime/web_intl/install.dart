// The browser-Intl engine module. `web/init.dart` loads this DEFERRED (only
// when `IcuKit.init(webEngine: WebEngine.browserIntl)` is called), builds the
// module, and installs it at the IcuKit seam — so WASM-mode web bundles never
// ship this code. Pure: builds and returns a JSObject, touches no IcuKit
// state. See docs/PLAN_BROWSER_INTL.md §1 / §4c / §4d.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../errors/icu_error.dart';
import 'collator_case_normalize_segment.dart';
import 'datetime.dart';
import 'list_relative_display.dart';
import 'locale.dart';
import 'number_format.dart';
import 'plural_rules.dart';
import 'throwing.dart';

/// Build the browser-engine module: a plain JS object whose class slots are
/// served off the browser's `Intl`. Every facade class is registered — a
/// throw-all stub first, then the family registrars override the ones the
/// browser can serve. `web/init.dart` sets this as `IcuKit.module`.
JSObject buildBrowserIntlModule() {
  // Fail fast if this environment has no ECMA-402 Intl (a pre-2017 browser, or
  // a non-browser web-like host): every family below reads globalThis.Intl, so
  // a clear error here beats an opaque TypeError deep in the first format call.
  if (globalContext.getProperty<JSAny?>('Intl'.toJS).isUndefinedOrNull) {
    throw IcuUnsupportedError(
      'the browser-Intl engine (this environment has no ECMA-402 Intl object)',
      engine: 'browser-intl',
    );
  }
  final module = JSObject();
  // Throw-all every class first; the family registrars below override the
  // ones the browser engine implements. Whatever stays a throw-all is a
  // genuine THROW capability (§3g).
  registerThrowAllDefaults(module);
  // Family registrars (§3a–§3f) override implemented classes here as they land.
  registerLocale(module);
  registerNumberFormat(module);
  registerPluralRules(module);
  registerListRelativeDisplay(module);
  registerCollatorCaseNormalizeSegment(module);
  registerDatetime(module);
  return module;
}
