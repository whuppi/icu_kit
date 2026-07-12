// §3d — list formatting, relative time, display names. Over Intl.ListFormat,
// Intl.RelativeTimeFormat, Intl.DisplayNames. See PLAN_BROWSER_INTL.md §3d.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

// ── ListFormatter ────────────────────────────────────────────────────────

// ListLength sentinel → Intl ListFormat style.
String _listStyle(JSObject length) => switch (enumStringValue(length)) {
  'Short' => 'short',
  'Narrow' => 'narrow',
  _ => 'long', // Wide
};

JSObject _listFormatter(String tag, String type, JSObject length) {
  final lf = intlFormat(
    'ListFormat',
    tag,
    jsOptions({'type': type.toJS, 'style': _listStyle(length).toJS}),
  );
  final o = JSObject();
  JSString format(JSArray<JSString> items) =>
      lf.callMethod<JSString>('format'.toJS, items);
  o.setProperty('format'.toJS, format.toJS);
  return o;
}

// ── RelativeTimeFormatterFfi ─────────────────────────────────────────────

const _rtWidths = {'Long': 'long', 'Short': 'short', 'Narrow': 'narrow'};
const _rtUnits = {
  'Second': 'second', 'Minute': 'minute', 'Hour': 'hour', 'Day': 'day', //
  'Week': 'week', 'Month': 'month', 'Quarter': 'quarter', 'Year': 'year',
};

JSObject _relativeFormatter(
  String tag,
  String style,
  String unit,
  JSObject? numeric,
) {
  final n = (numeric == null
      ? 'always'
      : enumStringValue(numeric).toLowerCase());
  final rtf = intlFormat(
    'RelativeTimeFormat',
    tag,
    jsOptions({'style': style.toJS, 'numeric': n.toJS}),
  );
  final o = JSObject();
  JSString format(JSObject decimal) {
    final v = double.parse(decimal.getProperty<JSString>('s'.toJS).toDart);
    return rtf.callMethod<JSString>('format'.toJS, v.toJS, unit.toJS);
  }

  o.setProperty('format'.toJS, format.toJS);
  return o;
}

// ── DisplayNames (region + locale) ───────────────────────────────────────

// Read a DisplayNamesOptions field's sentinel value, or null if absent.
String? _opt(JSObject options, String field) {
  final v = options.getProperty<JSObject?>(field.toJS);
  return v == null ? null : enumStringValue(v);
}

String _dnStyle(String? s) => switch (s) {
  'Narrow' => 'narrow',
  'Short' => 'short',
  // Long + Menu → 'long' (Intl has no 'menu'; documented PARTIAL).
  _ => 'long',
};
String _dnFallback(String? f) => f == 'None' ? 'none' : 'code';
String _dnLanguageDisplay(String? l) =>
    l == 'Standard' ? 'standard' : 'dialect';

JSObject _regionDisplayNames(JSObject locale, JSObject options) {
  final dn = intlFormat(
    'DisplayNames',
    localeTag(locale),
    jsOptions({
      'type': 'region'.toJS,
      'style': _dnStyle(_opt(options, 'style')).toJS,
      'fallback': _dnFallback(_opt(options, 'fallback')).toJS,
    }),
  );
  final o = JSObject();
  JSString of(JSString region) {
    final name = dn.callMethod<JSString?>('of'.toJS, region);
    return name ?? region; // fallback:'none' can yield undefined
  }

  o.setProperty('of'.toJS, of.toJS);
  return o;
}

JSObject _localeDisplayNames(JSObject locale, JSObject options) {
  final dn = intlFormat(
    'DisplayNames',
    localeTag(locale),
    jsOptions({
      'type': 'language'.toJS,
      'style': _dnStyle(_opt(options, 'style')).toJS,
      'fallback': _dnFallback(_opt(options, 'fallback')).toJS,
      'languageDisplay': _dnLanguageDisplay(
        _opt(options, 'languageDisplay'),
      ).toJS,
    }),
  );
  final o = JSObject();
  JSString of(JSObject target) {
    final name = dn.callMethod<JSString?>('of'.toJS, localeTag(target).toJS);
    return name ?? localeTag(target).toJS;
  }

  o.setProperty('of'.toJS, of.toJS);
  return o;
}

/// Register §3d, overriding throw-all defaults.
void registerListRelativeDisplay(JSObject module) {
  // ListFormatter — and/or/unit × length.
  put(
    module,
    'ListFormatter',
    staticClass({
      'createAndWithLength': ((JSObject l, JSObject len) => _listFormatter(
        localeTag(l),
        'conjunction',
        len,
      )).toJS,
      'createOrWithLength': ((JSObject l, JSObject len) => _listFormatter(
        localeTag(l),
        'disjunction',
        len,
      )).toJS,
      'createUnitWithLength': ((JSObject l, JSObject len) => _listFormatter(
        localeTag(l),
        'unit',
        len,
      )).toJS,
    }),
  );
  put(module, 'ListLength', enumClass(const ['Wide', 'Short', 'Narrow']));

  // RelativeTimeFormatterFfi — 3 widths × 8 units generated.
  final rtStatics = <String, JSFunction>{};
  _rtWidths.forEach((wName, style) {
    _rtUnits.forEach((uName, unit) {
      rtStatics['create$wName$uName'] =
          ((JSObject l, [JSObject? numeric]) => _relativeFormatter(
            localeTag(l),
            style,
            unit,
            numeric,
          )).toJS;
    });
  });
  put(module, 'RelativeTimeFormatterFfi', staticClass(rtStatics));
  put(module, 'RelativeTimeNumeric', enumClass(const ['Always', 'Auto']));

  // DisplayNames — RegionDisplayNames + LocaleDisplayNamesFormatter (both
  // `new X(locale, options)`), plus the three option enums.
  put(
    module,
    'RegionDisplayNames',
    ctorClass(((JSObject l, JSObject o) => _regionDisplayNames(l, o)).toJS),
  );
  put(
    module,
    'LocaleDisplayNamesFormatter',
    ctorClass(((JSObject l, JSObject o) => _localeDisplayNames(l, o)).toJS),
  );
  put(
    module,
    'DisplayNamesStyle',
    enumClass(const ['Narrow', 'Short', 'Long', 'Menu']),
  );
  put(module, 'DisplayNamesFallback', enumClass(const ['Code', 'None']));
  put(module, 'LanguageDisplay', enumClass(const ['Dialect', 'Standard']));
}
