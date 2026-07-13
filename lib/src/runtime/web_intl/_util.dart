// Primitives for building the browser-engine module object — the JSObject
// that stands in for the Diplomat-generated wasm module at the
// `IcuKit.module` seam. The web bindings resolve each class by name off this
// module and call statics / construct / call instance methods dynamically;
// these helpers build class slots of the right JS shape from Dart closures.
//
// Proven viable on dart2js AND dart2wasm (see docs/PLAN_BROWSER_INTL.md §0):
// a Dart-closure `JSFunction` can be `callAsConstructor`-ed, and a plain
// JSObject with closure properties satisfies getProperty + callMethod.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../errors/icu_error.dart';

/// The engine name carried in every [IcuUnsupportedError] the shim raises.
const engineName = 'browser-intl';

/// A non-constructable class slot exposing [statics] as callable members.
/// Used for classes the bindings only ever reach via `getProperty('X')` then
/// `X.callMethod('create…', …)` (the 147 static-factory dispatch paths).
JSObject staticClass(Map<String, JSFunction> statics) {
  final o = JSObject();
  for (final e in statics.entries) {
    o.setProperty(e.key.toJS, e.value);
  }
  return o;
}

/// A `new`-able class slot that also carries [statics]. Dispatch retrieves
/// the SAME slot as a `JSFunction` (for `callAsConstructor`) and as a
/// `JSObject` (for `callMethod('create…')`), so the slot is a function with
/// static properties. [ctor]'s return value becomes the constructed instance
/// (JS `new` yields an explicitly-returned object).
JSFunction ctorClass(
  JSFunction ctor, {
  Map<String, JSFunction> statics = const {},
}) {
  if (statics.isNotEmpty) {
    final asObj = ctor as JSObject; // a JS function IS a JS object at runtime
    for (final e in statics.entries) {
      asObj.setProperty(e.key.toJS, e.value);
    }
  }
  return ctor;
}

/// Register [slot] on [module] under [name].
void put(JSObject module, String name, JSAny slot) =>
    module.setProperty(name.toJS, slot);

/// Throw [IcuUnsupportedError] for [capability]. Used by THROW-family classes
/// and by every dead `*WithProvider` stub. The Dart exception propagates back
/// through the js_interop call into the binding/facade (see §3g).
Never unsupported(String capability) =>
    throw IcuUnsupportedError(capability, engine: engineName);

/// An enum-member instance: `{value: <int>}`. The int MUST match the Dart
/// enum's declaration order in the binding (see §3 law 4).
JSObject enumValue(int value) {
  final o = JSObject();
  o.setProperty('value'.toJS, value.toJS);
  return o;
}

/// An enum member carrying a STRING `{value: 'Name'}` — for enums the
/// bindings map by name (`LocaleDirection` → `'LeftToRight'`) or read as
/// option members off the class.
JSObject enumString(String value) {
  final o = JSObject();
  o.setProperty('value'.toJS, value.toJS);
  return o;
}

/// Read an enum member's string `value`.
String enumStringValue(JSObject member) =>
    member.getProperty<JSString>('value'.toJS).toDart;

/// An option-enum class object `{Member: {value:'Member'}, …}` — the members
/// the bindings read via `cls.getProperty('Member')` in their `toJs()` switch.
JSObject enumClass(List<String> members) {
  final o = JSObject();
  for (final m in members) {
    o.setProperty(m.toJS, enumString(m));
  }
  return o;
}

/// The global `Intl` object.
JSObject get intl => globalContext.getProperty<JSObject>('Intl'.toJS);

/// `Intl.getCanonicalLocales(tag)` — throws a RangeError (surfaced to Dart as
/// an ArgumentError) on a malformed tag, which is how `Locale.fromString`
/// reproduces the wasm binding's bad-tag throw.
List<String> canonicalLocales(String tag) => intl
    .callMethod<JSArray<JSString>>('getCanonicalLocales'.toJS, tag.toJS)
    .toDart
    .map((s) => s.toDart)
    .toList();

/// `new Intl.Locale(tag)`.
JSObject intlLocale(String tag) => intl
    .getProperty<JSFunction>('Locale'.toJS)
    .callAsConstructor<JSObject>(tag.toJS);

/// The BCP-47 string of an `Intl.Locale` (or any object with a JS toString).
String jsToString(JSObject o) => o.callMethod<JSString>('toString'.toJS).toDart;

/// JS `String(v)` — the platform's canonical stringification. Round-trips a
/// JS number (what `Decimal.fromNumberWithRoundTripPrecision` relies on).
String jsStringify(JSAny? v) =>
    globalContext.callMethod<JSString>('String'.toJS, v).toDart;

/// `new Intl.<name>(tag, options)` — e.g. `intlFormat('NumberFormat', tag, o)`.
JSObject intlFormat(String name, String tag, JSObject options) => intl
    .getProperty<JSFunction>(name.toJS)
    .callAsConstructor<JSObject>(tag.toJS, options);

/// A JS options object built from Dart entries. Values are already JS.
JSObject jsOptions(Map<String, JSAny?> entries) {
  final o = JSObject();
  for (final e in entries.entries) {
    if (e.value != null) o.setProperty(e.key.toJS, e.value!);
  }
  return o;
}

/// A mutable shim Locale opaque carrying [tag]. `toString()` returns the
/// current tag; [setLocaleTag] updates both so in-place mutators
/// (canonicalize / maximize / minimize) are observable through the binding's
/// `asBcp47` (which calls `toString`).
JSObject makeLocale(String tag) {
  final o = JSObject();
  setLocaleTag(o, tag);
  return o;
}

/// Update a shim Locale opaque's tag in place.
void setLocaleTag(JSObject locale, String tag) {
  locale.setProperty('tag'.toJS, tag.toJS);
  // toString captures this tag; re-set on every mutation (Dart-exported
  // closures don't bind JS `this`, so a fresh closure is how the value moves).
  JSString toStr() => tag.toJS;
  locale.setProperty('toString'.toJS, toStr.toJS);
}

/// Read a Locale opaque's canonical tag. Every shim Locale carries `{tag}`.
String localeTag(JSObject locale) =>
    locale.getProperty<JSString>('tag'.toJS).toDart;
