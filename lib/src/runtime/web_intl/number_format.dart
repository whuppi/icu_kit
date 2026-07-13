// §3b — numbers, currency, percent, units, over `Intl.NumberFormat`.
// See docs/PLAN_BROWSER_INTL.md §3b.
//
// Precision: a shim Decimal stores the value as a STRING and every formatter
// hands that string to `Intl.NumberFormat.format` (ES2020+ accepts a string
// numeric and preserves every digit — `Number(s)` would round). Fraction
// digits are pinned to the decimal's own, so trailing zeros survive.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

// ── Decimal opaque: {s: <decimal string>} ────────────────────────────────

JSObject _decimal(String s) => JSObject()..setProperty('s'.toJS, s.toJS);
String _decimalStr(JSObject d) => d.getProperty<JSString>('s'.toJS).toDart;

int _fractionDigits(String s) {
  final dot = s.indexOf('.');
  return dot < 0 ? 0 : s.length - dot - 1;
}

// The grouping strategy sentinel (its `value`) → Intl `useGrouping`.
JSAny _useGrouping(JSObject? strategy) {
  final v = strategy == null ? 'Auto' : enumStringValue(strategy);
  return switch (v) {
    'Never' => false.toJS,
    'Always' => 'always'.toJS,
    'Min2' => 'min2'.toJS,
    _ => 'auto'.toJS, // Auto
  };
}

JSString _fmt(String tag, JSObject options, String s) => intlFormat(
  'NumberFormat',
  tag,
  options,
).callMethod<JSString>('format'.toJS, s.toJS);

// Wrap a Dart list of `(type, value)` parts in the shape the
// FormattedNumberParts web mirror reads: a `partCount` property plus
// `partTypeAt(i)` / `partValueAt(i)` methods. Shared by every formatter here.
JSObject _wrapParts(List<(String, String)> parts) {
  final o = JSObject()..setProperty('partCount'.toJS, parts.length.toJS);
  JSString? typeAt(JSNumber index) {
    final i = index.toDartInt;
    return (i >= 0 && i < parts.length) ? parts[i].$1.toJS : null;
  }

  JSString? valueAt(JSNumber index) {
    final i = index.toDartInt;
    return (i >= 0 && i < parts.length) ? parts[i].$2.toJS : null;
  }

  o.setProperty('partTypeAt'.toJS, typeAt.toJS);
  o.setProperty('partValueAt'.toJS, valueAt.toJS);
  return o;
}

// An `Intl.NumberFormat.formatToParts` result (a JS array of `{type, value}`)
// as a Dart part list. Intl already emits ECMA-402 type strings verbatim.
List<(String, String)> _intlParts(JSArray<JSObject> parts) => [
  for (final p in parts.toDart)
    (
      p.getProperty<JSString>('type'.toJS).toDart,
      p.getProperty<JSString>('value'.toJS).toDart,
    ),
];

/// Build an `Intl.NumberFormat` with [options] and return `formatToParts(s)`
/// wrapped for the mirror.
JSObject _fmtParts(String tag, JSObject options, String s) => _wrapParts(
  _intlParts(
    intlFormat(
      'NumberFormat',
      tag,
      options,
    ).callMethod<JSArray<JSObject>>('formatToParts'.toJS, s.toJS),
  ),
);

// ── Decimal + DecimalFormatter (STABLE) ──────────────────────────────────

JSObject _decimalFormatter(JSObject locale, JSObject? strategy) {
  final tag = localeTag(locale);
  final grouping = _useGrouping(strategy);
  final o = JSObject();
  JSObject options(String s) {
    final k = _fractionDigits(s);
    return jsOptions({
      'useGrouping': grouping,
      'minimumFractionDigits': k.toJS,
      'maximumFractionDigits': k.toJS,
    });
  }

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(s), s);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(s), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

// ── Currency (EXPERIMENTAL, PARTIAL) ─────────────────────────────────────

// CurrencyWidth sentinel → currencyDisplay for the symbol formatter.
String _currencyDisplay(JSObject? width) {
  final v = width == null ? 'Short' : enumStringValue(width);
  return v == 'Narrow' ? 'narrowSymbol' : 'symbol';
}

JSObject _currencyFormatter(JSObject locale, JSObject? width) {
  final tag = localeTag(locale);
  final display = _currencyDisplay(width);
  final o = JSObject();
  // Symbol form: currency code arrives at format time.
  JSObject options(String s, JSString currencyCode) {
    final k = _fractionDigits(s);
    return jsOptions({
      'style': 'currency'.toJS,
      'currency': currencyCode,
      'currencyDisplay': display.toJS,
      'minimumFractionDigits': k.toJS,
      'maximumFractionDigits': k.toJS,
    });
  }

  JSString format(JSObject decimal, JSString currencyCode) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(s, currencyCode), s);
  }

  JSObject formatToParts(JSObject decimal, JSString currencyCode) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(s, currencyCode), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

JSObject _longCurrencyFormatter(JSObject locale, JSString currencyCode) {
  final tag = localeTag(locale);
  final o = JSObject();
  JSObject options(String s) {
    final k = _fractionDigits(s);
    return jsOptions({
      'style': 'currency'.toJS,
      'currency': currencyCode,
      'currencyDisplay': 'name'.toJS,
      'minimumFractionDigits': k.toJS,
      'maximumFractionDigits': k.toJS,
    });
  }

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(s), s);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(s), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

// ── Percent (EXPERIMENTAL, PARTIAL) ──────────────────────────────────────
//
// icu4x formats the value AS-IS with a percent sign (42 → "42%", NOT ×100).
// So format the plain number, then splice the locale's percent affix taken
// from `formatToParts` — never pass value/100 through style:'percent'.

// Resolve the locale's percent affix as TYPED parts (the percentSign / literal
// text before and after the number) ONCE, at formatter construction —
// _percentFormatter captures the result and reuses it for every call. The
// number is formatted separately (icu4x renders the value as-is, not ×100), so
// the affix is spliced around it; the typed parts carry through to
// formatToParts and the joined strings give the flat `format` output.
(List<(String, String)> before, List<(String, String)> after)
_percentAffixParts(String tag) {
  final parts = intlFormat(
    'NumberFormat',
    tag,
    jsOptions({'style': 'percent'.toJS}),
  ).callMethod<JSArray<JSObject>>('formatToParts'.toJS, (1).toJS).toDart;
  final before = <(String, String)>[];
  final after = <(String, String)>[];
  var seenNumber = false;
  for (final part in parts) {
    final type = part.getProperty<JSString>('type'.toJS).toDart;
    final value = part.getProperty<JSString>('value'.toJS).toDart;
    if (type == 'percentSign' || type == 'literal') {
      (seenNumber ? after : before).add((type, value));
    } else {
      seenNumber = true;
    }
  }
  return (before, after);
}

JSObject _percentFormatter(JSObject locale, JSObject? display) {
  final tag = localeTag(locale);
  final mode = display == null ? 'Standard' : enumStringValue(display);
  // ExplicitSign → always show sign. Approximate has no Intl equivalent;
  // rendered as Standard (documented PARTIAL).
  final signDisplay = (mode == 'ExplicitSign' ? 'always' : 'auto').toJS;
  final (beforeParts, afterParts) = _percentAffixParts(tag);
  final before = beforeParts.map((p) => p.$2).join();
  final after = afterParts.map((p) => p.$2).join();
  final o = JSObject();
  JSObject numOptions(String s) {
    final k = _fractionDigits(s);
    return jsOptions({
      'signDisplay': signDisplay,
      'minimumFractionDigits': k.toJS,
      'maximumFractionDigits': k.toJS,
    });
  }

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    final num = _fmt(tag, numOptions(s), s).toDart;
    return '$before$num$after'.toJS;
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    final numParts = _intlParts(
      intlFormat(
        'NumberFormat',
        tag,
        numOptions(s),
      ).callMethod<JSArray<JSObject>>('formatToParts'.toJS, s.toJS),
    );
    return _wrapParts([...beforeParts, ...numParts, ...afterParts]);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

// ── Units (EXPERIMENTAL, PARTIAL) ────────────────────────────────────────

String _unitDisplay(JSObject? width) {
  final v = width == null ? 'Short' : enumStringValue(width);
  return switch (v) {
    'Long' => 'long',
    'Narrow' => 'narrow',
    _ => 'short',
  };
}

JSObject _unitsFormatter(JSObject locale, JSString unitId, JSObject? width) {
  final tag = localeTag(locale);
  final display = _unitDisplay(width);
  final base = <String, JSAny?>{
    'style': 'unit'.toJS,
    'unit': unitId,
    'unitDisplay': display.toJS,
  };
  // Build the zero-fraction formatter at CREATION — it doubles as the unit
  // validator (Intl.NumberFormat throws RangeError for a unit outside the
  // ECMA-402 set, smaller than ICU4X's), surfaced as a typed
  // IcuUnsupportedError here where the facade wraps creation errors, not as a
  // raw RangeError escaping the per-value format() call. Reused for integer
  // values (the common case, k == 0); only fractional inputs build a fresh
  // formatter with pinned fraction digits.
  final JSObject intFmt;
  try {
    intFmt = intlFormat(
      'NumberFormat',
      tag,
      jsOptions({
        ...base,
        'minimumFractionDigits': 0.toJS,
        'maximumFractionDigits': 0.toJS,
      }),
    );
  } catch (_) {
    unsupported(
      'IcuUnitFormat unit "${unitId.toDart}" (not in the browser Intl unit set)',
    );
  }
  final o = JSObject();
  // The reused int formatter for integer values, else one pinned to the
  // value's fraction digits.
  JSObject fmtFor(String s) {
    final k = _fractionDigits(s);
    return k == 0
        ? intFmt
        : intlFormat(
            'NumberFormat',
            tag,
            jsOptions({
              ...base,
              'minimumFractionDigits': k.toJS,
              'maximumFractionDigits': k.toJS,
            }),
          );
  }

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return fmtFor(s).callMethod<JSString>('format'.toJS, s.toJS);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _wrapParts(
      _intlParts(
        fmtFor(s).callMethod<JSArray<JSObject>>('formatToParts'.toJS, s.toJS),
      ),
    );
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

/// Register the §3b classes, overriding their throw-all defaults.
void registerNumberFormat(JSObject module) {
  put(
    module,
    'Decimal',
    staticClass({
      'fromNumber': ((JSAny v) => _decimal(jsStringify(v))).toJS,
      'fromNumberWithRoundTripPrecision': ((JSAny v) => _decimal(
        jsStringify(v),
      )).toJS,
    }),
  );

  put(
    module,
    'DecimalFormatter',
    staticClass({
      'createWithGroupingStrategy':
          ((JSObject locale, [JSObject? strategy]) => _decimalFormatter(
            locale,
            strategy,
          )).toJS,
    }),
  );
  put(
    module,
    'DecimalGroupingStrategy',
    enumClass(const ['Auto', 'Never', 'Always', 'Min2']),
  );

  put(
    module,
    'CurrencyFormatter',
    staticClass({
      'createWithWidth':
          ((JSObject locale, [JSObject? width]) => _currencyFormatter(
            locale,
            width,
          )).toJS,
    }),
  );
  put(module, 'CurrencyWidth', enumClass(const ['Short', 'Narrow']));

  put(
    module,
    'LongCurrencyFormatter',
    staticClass({
      'createForCurrency':
          ((JSObject locale, JSString code) => _longCurrencyFormatter(
            locale,
            code,
          )).toJS,
    }),
  );

  put(
    module,
    'PercentFormatter',
    staticClass({
      'createWithDisplay':
          ((JSObject locale, [JSObject? display]) => _percentFormatter(
            locale,
            display,
          )).toJS,
    }),
  );
  put(
    module,
    'PercentDisplay',
    enumClass(const ['Standard', 'Approximate', 'ExplicitSign']),
  );

  put(
    module,
    'UnitsFormatter',
    staticClass({
      'createForUnit':
          ((JSObject locale, JSString unit, [JSObject? width]) =>
                  _unitsFormatter(locale, unit, width))
              .toJS,
    }),
  );
  put(module, 'UnitsWidth', enumClass(const ['Long', 'Short', 'Narrow']));
}
