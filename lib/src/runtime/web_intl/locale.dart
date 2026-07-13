// §3a — Locale and the locale-algebra classes, over `Intl.Locale` /
// `Intl.getCanonicalLocales`. See docs/PLAN_BROWSER_INTL.md §3a.
//
// The locale classes MUTATE the Locale opaque in place (canonicalize /
// maximize / minimize edit `.tag`); the facade reads the result back via
// `asBcp47` (the opaque's `toString`). setLocaleTag keeps both in sync.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

// ── Intl.Locale subtag reads + likely-subtags ────────────────────────────

String _language(String tag) =>
    intlLocale(tag).getProperty<JSString>('language'.toJS).toDart;
String? _script(String tag) =>
    intlLocale(tag).getProperty<JSString?>('script'.toJS)?.toDart;
String? _region(String tag) =>
    intlLocale(tag).getProperty<JSString?>('region'.toJS)?.toDart;

String _maximize(String tag) =>
    jsToString(intlLocale(tag).callMethod<JSObject>('maximize'.toJS));
String _minimize(String tag) =>
    jsToString(intlLocale(tag).callMethod<JSObject>('minimize'.toJS));

// RTL scripts (maximized). Fallback when Intl.Locale.getTextInfo is absent.
const _rtlScripts = {
  'Arab', 'Hebr', 'Thaa', 'Syrc', 'Adlm', 'Rohg', 'Nkoo', //
  'Mand', 'Samr', 'Mend', 'Yezi',
};

/// `'LeftToRight'` / `'RightToLeft'` for [tag]. Prefers `getTextInfo`
/// (evergreen browsers), falls back to the maximized script against the RTL
/// set. Never `'Unknown'` — Intl always resolves a script via maximize, which
/// is a documented deviation from ICU4X's data-driven "unknown".
String _direction(String tag) {
  final loc = intlLocale(tag);
  if (loc.has('getTextInfo')) {
    final info = loc.callMethod<JSObject>('getTextInfo'.toJS);
    final dir = info.getProperty<JSString>('direction'.toJS).toDart;
    return dir == 'rtl' ? 'RightToLeft' : 'LeftToRight';
  }
  final script = _script(_maximize(tag));
  return _rtlScripts.contains(script) ? 'RightToLeft' : 'LeftToRight';
}

// ── the mutate-in-place algebra instances ────────────────────────────────

JSObject _canonicalizer() {
  final o = JSObject();
  JSAny? canonicalize(JSObject loc) {
    setLocaleTag(loc, canonicalLocales(localeTag(loc)).first);
    return null; // native returns a discarded TransformResult
  }

  o.setProperty('canonicalize'.toJS, canonicalize.toJS);
  return o;
}

JSObject _expander() {
  final o = JSObject();
  JSAny? maximize(JSObject loc) {
    setLocaleTag(loc, _maximize(localeTag(loc)));
    return null;
  }

  JSAny? minimize(JSObject loc) {
    setLocaleTag(loc, _minimize(localeTag(loc)));
    return null;
  }

  o.setProperty('maximize'.toJS, maximize.toJS);
  o.setProperty('minimize'.toJS, minimize.toJS);
  // Intl has one minimize; favor-script behaves as plain minimize (PARTIAL).
  o.setProperty('minimizeFavorScript'.toJS, minimize.toJS);
  return o;
}

JSObject _directionality() {
  final o = JSObject();
  JSObject get(JSObject loc) => enumString(_direction(localeTag(loc)));
  JSBoolean isLtr(JSObject loc) =>
      (_direction(localeTag(loc)) == 'LeftToRight').toJS;
  JSBoolean isRtl(JSObject loc) =>
      (_direction(localeTag(loc)) == 'RightToLeft').toJS;
  o.setProperty('get'.toJS, get.toJS);
  o.setProperty('isLeftToRight'.toJS, isLtr.toJS);
  o.setProperty('isRightToLeft'.toJS, isRtl.toJS);
  return o;
}

// ── fallbacker chain (PARTIAL — approximate for exotic locales) ───────────

/// The fallback tags AFTER the input (the facade yields the input itself
/// first). Language priority: drop script (keeping region), then drop region.
/// `en-Latn-US` → `en-US`, `en`. Region priority keeps the region one step
/// longer (approximation of ICU4X's data-driven region chain).
///
/// PARTIAL vs ICU4X's CLDR parent-locale data: script-only and region-only
/// tags collapse more simply than CLDR defines — `zh-Hant` → `zh` (script
/// dropped), `es-419` → `es` (region dropped), `sr-Latn` → `sr`. CLDR keeps
/// some of these distinctions through parent overrides; this chain does not.
List<String> _fallbackChain(String tag, {required bool regionPriority}) {
  final lang = _language(tag);
  final script = _script(tag);
  final region = _region(tag);
  final out = <String>[];
  if (regionPriority) {
    if (script != null && region != null) out.add('$lang-$region');
    if (region != null) out.add('und-$region');
  } else {
    if (script != null && region != null) out.add('$lang-$region');
    if (script != null || region != null) out.add(lang);
  }
  return out;
}

JSObject _fallbackIterator(List<String> chain) {
  var i = 0;
  final o = JSObject();
  JSObject next() {
    final step = JSObject();
    if (i >= chain.length) {
      step.setProperty('done'.toJS, true.toJS);
    } else {
      step.setProperty('done'.toJS, false.toJS);
      step.setProperty('value'.toJS, makeLocale(chain[i]));
      i++;
    }
    return step;
  }

  o.setProperty('next'.toJS, next.toJS);
  return o;
}

JSObject _fallbackerWithConfig({required bool regionPriority}) {
  final o = JSObject();
  JSObject fallbackForLocale(JSObject loc) => _fallbackIterator(
    _fallbackChain(localeTag(loc), regionPriority: regionPriority),
  );
  o.setProperty('fallbackForLocale'.toJS, fallbackForLocale.toJS);
  return o;
}

JSObject _fallbacker() {
  final o = JSObject();
  JSObject forConfig(JSObject config) {
    final priority = config.getProperty<JSObject>('priority'.toJS);
    final region = enumStringValue(priority) == 'Region';
    return _fallbackerWithConfig(regionPriority: region);
  }

  o.setProperty('forConfig'.toJS, forConfig.toJS);
  return o;
}

/// Register the §3a classes, overriding their throw-all defaults.
void registerLocale(JSObject module) {
  // Locale — static factory; instances are mutable {tag, toString}.
  put(
    module,
    'Locale',
    staticClass({
      'fromString': ((JSString name) => makeLocale(
        canonicalLocales(name.toDart).first,
      )).toJS,
    }),
  );

  // Canonicalizer / Expander / Directionality — `new X()` + createExtended,
  // both stateless (browser Intl needs no locale data provider).
  put(
    module,
    'LocaleCanonicalizer',
    ctorClass(
      _canonicalizer.toJS,
      statics: {'createExtended': _canonicalizer.toJS},
    ),
  );
  put(
    module,
    'LocaleExpander',
    ctorClass(_expander.toJS, statics: {'createExtended': _expander.toJS}),
  );
  put(
    module,
    'LocaleDirectionality',
    ctorClass(
      _directionality.toJS,
      statics: {'createExtended': _directionality.toJS},
    ),
  );

  // Fallbacker chain.
  put(module, 'LocaleFallbacker', ctorClass(_fallbacker.toJS));
  final priority = JSObject()
    ..setProperty('Language'.toJS, enumString('Language'))
    ..setProperty('Region'.toJS, enumString('Region'));
  put(module, 'LocaleFallbackPriority', priority);
  // The config IS its `{priority}` fields object; forConfig reads it back.
  put(
    module,
    'LocaleFallbackConfig',
    ctorClass(((JSObject fields) => fields).toJS),
  );
}
