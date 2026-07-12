// §3c — plural rules, over `Intl.PluralRules`. See PLAN_BROWSER_INTL.md §3c.
//
// DOCUMENTED GAP: plural operands are parsed as a JS number, so explicit
// trailing fraction zeros ("1.0") lose their CLDR v/f operands — categories
// may differ for locales whose rules depend on them. PARTIAL. When
// Intl.PluralRules gains string/BigInt operand support (the operand-preserving
// proposal, Stage 3), pass the raw operand string to select() instead of
// double.parse to keep the v/f operands.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

const _categoryNames = ['zero', 'one', 'two', 'few', 'many', 'other'];

String _pascal(String s) => s[0].toUpperCase() + s.substring(1);

JSObject _pluralRules(String tag, String type) {
  final pr = intlFormat('PluralRules', tag, jsOptions({'type': type.toJS}));

  // categories: which the locale's rule set uses (resolvedOptions).
  final used = pr
      .callMethod<JSObject>('resolvedOptions'.toJS)
      .getProperty<JSArray<JSString>>('pluralCategories'.toJS)
      .toDart
      .map((s) => s.toDart)
      .toSet();
  final categories = JSObject();
  for (final c in _categoryNames) {
    categories.setProperty(c.toJS, used.contains(c).toJS);
  }

  final o = JSObject()..setProperty('categories'.toJS, categories);
  // categoryFor(operands) → {value: 'One'} (Diplomat's PascalCase).
  JSObject categoryFor(JSObject operands) {
    final s = operands.getProperty<JSString>('s'.toJS).toDart;
    final cat = pr
        .callMethod<JSString>('select'.toJS, double.parse(s).toJS)
        .toDart;
    return enumString(_pascal(cat));
  }

  o.setProperty('categoryFor'.toJS, categoryFor.toJS);
  return o;
}

/// Register §3c, overriding throw-all defaults.
void registerPluralRules(JSObject module) {
  put(
    module,
    'PluralRules',
    staticClass({
      'createCardinal': ((JSObject locale) => _pluralRules(
        localeTag(locale),
        'cardinal',
      )).toJS,
      'createOrdinal': ((JSObject locale) => _pluralRules(
        localeTag(locale),
        'ordinal',
      )).toJS,
    }),
  );

  // PluralOperands opaque carries the numeric string; a non-numeric string
  // throws when categoryFor parses it (matches the wasm binding's reject).
  put(
    module,
    'PluralOperands',
    staticClass({
      'fromString': ((JSString s) => JSObject()..setProperty('s'.toJS, s)).toJS,
    }),
  );
}
