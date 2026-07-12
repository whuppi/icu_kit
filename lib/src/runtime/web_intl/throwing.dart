// Throw-all class slots + the default registration for every module class.
//
// install.dart registers a throw-all for all 61 classes FIRST; the family
// registrars (§3a–§3f) then override the ones the browser engine implements.
// Whatever stays a throw-all is a genuine THROW capability (§3g) — bidi,
// Unicode properties, IDNA, exemplar characters, line segmentation. The
// facade catch turns the thrown IcuUnsupportedError into the same type
// (facades rethrow it; see §3 law 8).
//
// A throw-all is a JS Proxy over a function target: the `get` trap answers
// ANY static name with a throwing function and the `construct`/`apply` traps
// throw — so no per-class slot list is enumerated in lib (the drift guard,
// not a hand-list, owns completeness). See docs/PLAN_BROWSER_INTL.md §3g/§4d.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

@JS('Proxy')
extension type _Proxy._(JSObject _) implements JSObject {
  external _Proxy(JSAny target, JSObject handler);
}

/// A class slot where every access / construction throws
/// `IcuUnsupportedError` naming [capability]. `typeof` is `'function'`, so it
/// satisfies both the `callAsConstructor` and the `getProperty` binding paths.
JSObject throwAllClass(String capability) {
  // Declared JS return types (never `Never Function`, which `.toJS` rejects).
  JSObject construct(JSObject t, JSArray<JSAny?> a, JSObject nt) =>
      unsupported(capability);
  JSAny? apply(JSObject t, JSAny? thiz, JSArray<JSAny?> a) =>
      unsupported(capability);
  JSAny? get(JSObject t, JSAny prop, JSObject recv) {
    // Symbol keys (Symbol.toPrimitive, then, toStringTag, …) are read by JS
    // internals — hand those back unchanged so a throwing function can't be
    // mistaken for a thenable / coercion hook. Only named (string) accesses,
    // i.e. the binding's static lookups, get a thrower.
    if (!prop.typeofEquals('string')) return t.getProperty(prop);
    JSAny? thrower() => unsupported(capability);
    return thrower.toJS;
  }

  JSObject target() => unsupported(capability);
  final handler = JSObject()
    ..setProperty('construct'.toJS, construct.toJS)
    ..setProperty('apply'.toJS, apply.toJS)
    ..setProperty('get'.toJS, get.toJS);
  return _Proxy(target.toJS, handler);
}

/// Every module class the web bindings + dispatch reference. install.dart
/// throw-alls each one before the family registrars override the implemented
/// ones. NOT a curated allow-list: if a binding adds a class, the contract
/// guard (which derives the required set from source) fails until this list
/// and a registrar cover it. Keep sorted.
const kAllClasses = <String>[
  'Bidi',
  'BidiClass',
  'Calendar',
  'CalendarKind',
  'CanonicalCombiningClass',
  'CaseMapper',
  'CodePointMapData16',
  'CodePointMapData8',
  'CodePointSetData',
  'Collator',
  'CollatorAlternateHandling',
  'CollatorCaseLevel',
  'CollatorMaxVariable',
  'CollatorStrength',
  'ComposingNormalizer',
  'CurrencyFormatter',
  'CurrencyWidth',
  'DataProvider',
  'Date',
  'DateFormatter',
  'DateTimeAlignment',
  'DateTimeFormatter',
  'DateTimeLength',
  'Decimal',
  'DecimalFormatter',
  'DecimalGroupingStrategy',
  'DecomposingNormalizer',
  'DisplayNamesFallback',
  'DisplayNamesStyle',
  'EastAsianWidth',
  'ExemplarCharacters',
  'GraphemeClusterBreak',
  'GraphemeClusterSegmenter',
  'HangulSyllableType',
  'IdnaProcessor',
  'IsoDate',
  'LanguageDisplay',
  'LeadingAdjustment',
  'LineBreak',
  'LineSegmenter',
  'ListFormatter',
  'ListLength',
  'Locale',
  'LocaleCanonicalizer',
  'LocaleDirectionality',
  'LocaleDisplayNamesFormatter',
  'LocaleExpander',
  'LocaleFallbackConfig',
  'LocaleFallbackPriority',
  'LocaleFallbacker',
  'LongCurrencyFormatter',
  'NumericType',
  'PercentDisplay',
  'PercentFormatter',
  'PluralOperands',
  'PluralRules',
  'PropertyValueNameToEnumMapper',
  'RegionDisplayNames',
  'RelativeTimeFormatterFfi',
  'RelativeTimeNumeric',
  'Script',
  'SentenceBreak',
  'SentenceSegmenter',
  'Time',
  'TimeFormatter',
  'TimePrecision',
  'TimeZone',
  'TimeZoneFormatter',
  'TitlecaseMapper',
  'TrailingCase',
  'UnitsFormatter',
  'UnitsWidth',
  'UtcOffset',
  'WordBreak',
  'WordSegmenter',
  'YearStyle',
  'ZonedDateTimeFormatter',
];

/// Register a throw-all slot for every class in [kAllClasses]. Called first
/// by install.dart; family registrars override the implemented ones.
void registerThrowAllDefaults(JSObject module) {
  for (final name in kAllClasses) {
    put(module, name, throwAllClass(name));
  }
}
