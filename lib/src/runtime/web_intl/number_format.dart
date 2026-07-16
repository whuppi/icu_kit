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

// ── Decimal opaque: {s: <decimal string>, minFrac?, maxFrac?, minInt?} ────
//
// The digit-shaping methods (padStart / padEnd / roundWithMode, invoked by
// the shared web Decimal mirror) don't rewrite the string here — they RECORD
// the requested digit intent on the object. Intl.NumberFormat then does the
// actual rounding + padding at format time (its default rounding is
// halfExpand, matching ECMA-402 and the native fixed_decimal path). This
// keeps the browser-Intl engine's output identical to native/WASM without
// re-implementing decimal rounding.

JSObject _decimal(String s) {
  final o = JSObject()..setProperty('s'.toJS, s.toJS);
  // The position of the most significant digit — the sig-digit path reads it
  // to compute how far to pad. Matches ICU4X magnitude_range's `end`.
  final magEnd = _magnitudeEnd(s);
  o.setProperty('magnitudeEnd'.toJS, magEnd.toJS);
  void rec(String key, int v) => o.setProperty(key.toJS, v.toJS);
  void recStr(String key, String v) => o.setProperty(key.toJS, v.toJS);
  // Record the rounding cutoff. Fraction positions (<= 0) map onto
  // maximumFractionDigits; a pre-integer position (> 0 — the facade's
  // significant-digits + custom-mode path) has no fraction-digit
  // equivalent, so it maps onto maximumSignificantDigits instead:
  // rounding at 10^p keeps (magnitudeEnd - p + 1) significant digits.
  void recCutoff(int position) {
    if (position > 0) {
      rec('maxSig', magEnd - position + 1);
    } else {
      rec('maxFrac', -position);
    }
  }

  // padEnd(position): at least (-position) fraction digits.
  o.setProperty(
    'padEnd'.toJS,
    ((JSNumber position) => rec('minFrac', -position.toDartInt)).toJS,
  );
  // padStart(position): at least `position` integer digits (native
  // pad_start(N) yields N integer digits, so position IS the count).
  o.setProperty(
    'padStart'.toJS,
    ((JSNumber position) => rec('minInt', position.toDartInt)).toJS,
  );
  // roundWithMode(position, mode): record the cutoff + the ECMA-402 mode.
  // Intl.NumberFormat v3 does the actual rounding at format time.
  o.setProperty(
    'roundWithMode'.toJS,
    ((JSNumber position, JSObject mode) {
      recCutoff(position.toDartInt);
      recStr('roundingMode', enumStringValue(mode));
    }).toJS,
  );
  // roundWithModeAndIncrement(position, mode, increment): additionally
  // record the increment BASE ({1, 2, 5, 25}) and the raw position; the
  // Intl-facing roundingIncrement is derived later against the recorded
  // fraction digits (see _digitJsOptions) because (base, position) alone
  // is ambiguous — increment 50 @ 2fd and increment 5 @ 1fd share both.
  o.setProperty(
    'roundWithModeAndIncrement'.toJS,
    ((JSNumber position, JSObject mode, JSObject increment) {
      final name = enumStringValue(increment); // 'MultiplesOf25' etc.
      rec('incrementBase', int.parse(name.substring('MultiplesOf'.length)));
      rec('incrementPos', position.toDartInt);
      recStr('roundingMode', enumStringValue(mode));
    }).toJS,
  );
  // applySignDisplay(display): record for Intl's signDisplay option.
  o.setProperty(
    'applySignDisplay'.toJS,
    ((JSObject display) =>
            recStr('signDisplay', enumStringValue(display)))
        .toJS,
  );
  // trimEndIfInteger(): record for Intl's trailingZeroDisplay option.
  o.setProperty(
    'trimEndIfInteger'.toJS,
    (() => rec('stripIfInteger', 1)).toJS,
  );
  return o;
}

String _decimalStr(JSObject d) => d.getProperty<JSString>('s'.toJS).toDart;

int _fractionDigits(String s) {
  final dot = s.indexOf('.');
  return dot < 0 ? 0 : s.length - dot - 1;
}

/// Power-of-ten position of the most significant digit in [s] (a plain
/// decimal literal). 1234 → 3, 1.2 → 0, 0.05 → -2, 0 → 0.
int _magnitudeEnd(String s) {
  final str = s.startsWith('-') ? s.substring(1) : s;
  final dot = str.indexOf('.');
  final intPart = dot < 0 ? str : str.substring(0, dot);
  final fracPart = dot < 0 ? '' : str.substring(dot + 1);
  for (var i = 0; i < intPart.length; i++) {
    if (intPart[i] != '0') return intPart.length - 1 - i;
  }
  for (var j = 0; j < fracPart.length; j++) {
    if (fracPart[j] != '0') return -(j + 1);
  }
  return 0; // zero
}

/// [f] rounded to [digits] significant figures as a plain decimal string.
/// `toStringAsPrecision` is Dart's `Number.toPrecision`; expand any
/// exponential form so the shim's Decimal stays a plain literal.
String _sigString(double f, int digits) {
  final s = f.toStringAsPrecision(digits);
  return (s.contains('e') || s.contains('E')) ? _deExponent(s) : s;
}

/// Expand `1.2e+5` / `1.2e-7` scientific notation to a plain decimal literal.
String _deExponent(String s) {
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  final eIdx = body.indexOf(RegExp('[eE]'));
  final mantissa = body.substring(0, eIdx);
  final exp = int.parse(body.substring(eIdx + 1));
  final dot = mantissa.indexOf('.');
  final intPart = dot < 0 ? mantissa : mantissa.substring(0, dot);
  final fracPart = dot < 0 ? '' : mantissa.substring(dot + 1);
  final digits = intPart + fracPart;
  final pointPos = intPart.length + exp;
  String out;
  if (pointPos <= 0) {
    out = '0.${'0' * -pointPos}$digits';
  } else if (pointPos >= digits.length) {
    out = digits + '0' * (pointPos - digits.length);
  } else {
    out = '${digits.substring(0, pointPos)}.${digits.substring(pointPos)}';
  }
  return neg ? '-$out' : out;
}

int? _recorded(JSObject d, String key) =>
    d.getProperty<JSNumber?>(key.toJS)?.toDartInt;

String? _recordedStr(JSObject d, String key) =>
    d.getProperty<JSString?>(key.toJS)?.toDart;

/// Resolve the Intl digit options for [d] from its own string digits plus any
/// recorded shaping intent. With no shaping recorded this pins min == max ==
/// the string's own fraction digits (preserving trailing zeros exactly, the
/// original behavior); shaping widens/narrows per ECMA-402.
({int minFrac, int maxFrac, int? minInt}) _digitOpts(JSObject d) {
  final own = _fractionDigits(_decimalStr(d));
  final recMinFrac = _recorded(d, 'minFrac');
  final recMaxFrac = _recorded(d, 'maxFrac');
  final minInt = _recorded(d, 'minInt');
  final fracShaped = recMinFrac != null || recMaxFrac != null;
  final minFrac = fracShaped ? (recMinFrac ?? 0) : own;
  var maxFrac = fracShaped ? (recMaxFrac ?? (own > minFrac ? own : minFrac)) : own;
  if (maxFrac < minFrac) maxFrac = minFrac;
  return (minFrac: minFrac, maxFrac: maxFrac, minInt: minInt);
}

/// PascalCase enum sentinel name → the lowerCamel ECMA-402 option value
/// ('HalfExpand' → 'halfExpand', 'ExceptZero' → 'exceptZero').
String _lowerCamel(String v) => v[0].toLowerCase() + v.substring(1);

/// The digit-shaping keys added to a bare jsOptions map for a decimal [d] —
/// fraction/integer bounds plus every recorded ECMA-402 rounding intent
/// (roundingMode / roundingIncrement / signDisplay / trailingZeroDisplay /
/// max significant digits). Every formatter here builds its number options
/// through this, so the recorded intents reach Intl uniformly.
///
/// [pinOwnFraction] — when no fraction intent was recorded, pin min == max
/// to the decimal string's own fraction digits (exact-digit parity with the
/// native Decimal). The compact formatter passes false: pinning would force
/// `maximumFractionDigits: 0` on integer inputs and Intl would render "1M"
/// where ICU4X's own significand rounding gives "1.2M" — unshaped compact
/// input must get Intl's compact defaults instead.
Map<String, JSAny?> _digitJsOptions(JSObject d, {bool pinOwnFraction = true}) {
  final o = _digitOpts(d);
  final magEnd = _recorded(d, 'magnitudeEnd') ?? 0;
  final maxSig = _recorded(d, 'maxSig');
  final recMinFrac = _recorded(d, 'minFrac');
  final recMaxFrac = _recorded(d, 'maxFrac');
  final roundingMode = _recordedStr(d, 'roundingMode');
  final signDisplay = _recordedStr(d, 'signDisplay');
  final incrementBase = _recorded(d, 'incrementBase');

  // The facade's minSig padding calls padEnd(magnitudeEnd - minSig + 1),
  // which goes NEGATIVE as a fraction count for values whose padding stops
  // left of the decimal point (1234 @ minSig 2 → padEnd(2) → "-2 fraction
  // digits"). Intl rejects negative fraction bounds, so recover the
  // significant-digit intent instead: minSig = recorded + magnitudeEnd + 1.
  // The same recovery applies whenever the sig path is active (maxSig set).
  int? minSig;
  if (recMinFrac != null && (maxSig != null || recMinFrac < 0)) {
    minSig = recMinFrac + magEnd + 1;
    if (minSig < 1) minSig = 1;
  }
  final sigMode = maxSig != null || minSig != null;

  // Reconstruct the Intl-facing increment from (base, position): the
  // shaper rounded to multiples of base × 10^position, and Intl expresses
  // that as roundingIncrement = base × 10^(position + maxFrac) applied at
  // maxFrac fraction digits (min == max, guaranteed by the facade).
  int? intlIncrement;
  if (incrementBase != null) {
    final position = _recorded(d, 'incrementPos')!;
    var inc = incrementBase;
    for (var k = position + o.maxFrac; k > 0; k--) {
      inc *= 10;
    }
    intlIncrement = inc;
  }

  final fracRecorded = recMinFrac != null || recMaxFrac != null;
  return {
    if (sigMode) ...{
      if (minSig != null) 'minimumSignificantDigits': minSig.toJS,
      if (maxSig != null) 'maximumSignificantDigits': maxSig.toJS,
    } else if (pinOwnFraction || fracRecorded) ...{
      'minimumFractionDigits': o.minFrac.toJS,
      'maximumFractionDigits': o.maxFrac.toJS,
    },
    if (o.minInt != null) 'minimumIntegerDigits': o.minInt!.toJS,
    if (roundingMode != null) 'roundingMode': _lowerCamel(roundingMode).toJS,
    if (signDisplay != null) 'signDisplay': _lowerCamel(signDisplay).toJS,
    if (intlIncrement != null && intlIncrement != 1)
      'roundingIncrement': intlIncrement.toJS,
    if (_recorded(d, 'stripIfInteger') != null)
      'trailingZeroDisplay': 'stripIfInteger'.toJS,
  };
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
  JSObject options(JSObject decimal) =>
      jsOptions({'useGrouping': grouping, ..._digitJsOptions(decimal)});

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(decimal), s);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(decimal), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

// ── Compact (EXPERIMENTAL) ───────────────────────────────────────────────

JSObject _compactFormatter(
  JSObject locale,
  String display, [
  JSObject? grouping,
]) {
  final tag = localeTag(locale);
  final useGrouping = _useGrouping(grouping);
  final o = JSObject();
  JSObject options(JSObject decimal) => jsOptions({
    'notation': 'compact'.toJS,
    'compactDisplay': display.toJS,
    'useGrouping': useGrouping,
    ..._digitJsOptions(decimal, pinOwnFraction: false),
  });

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(decimal), s);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(decimal), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

// ── Currency (EXPERIMENTAL, PARTIAL) ─────────────────────────────────────

// CurrencyWidth sentinel → currencyDisplay for the symbol formatter.
String _currencyDisplay(JSObject? width) {
  final v = width == null ? 'Short' : enumStringValue(width);
  return switch (v) {
    'Narrow' => 'narrowSymbol',
    'Code' => 'code',
    _ => 'symbol',
  };
}

JSObject _currencyFormatter(
  JSObject locale,
  JSObject? width, [
  JSObject? grouping,
]) {
  final tag = localeTag(locale);
  final display = _currencyDisplay(width);
  final useGrouping = _useGrouping(grouping);
  final o = JSObject();
  // Symbol form: currency code arrives at format time.
  JSObject options(JSObject decimal, JSString currencyCode) => jsOptions({
    'style': 'currency'.toJS,
    'currency': currencyCode,
    'currencyDisplay': display.toJS,
    'useGrouping': useGrouping,
    ..._digitJsOptions(decimal),
  });

  JSString format(JSObject decimal, JSString currencyCode) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(decimal, currencyCode), s);
  }

  JSObject formatToParts(JSObject decimal, JSString currencyCode) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(decimal, currencyCode), s);
  }

  o.setProperty('format'.toJS, format.toJS);
  o.setProperty('formatToParts'.toJS, formatToParts.toJS);
  return o;
}

JSObject _longCurrencyFormatter(
  JSObject locale,
  JSString currencyCode, [
  JSObject? grouping,
]) {
  final tag = localeTag(locale);
  final useGrouping = _useGrouping(grouping);
  final o = JSObject();
  JSObject options(JSObject decimal) => jsOptions({
    'style': 'currency'.toJS,
    'currency': currencyCode,
    'currencyDisplay': 'name'.toJS,
    'useGrouping': useGrouping,
    ..._digitJsOptions(decimal),
  });

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmt(tag, options(decimal), s);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _fmtParts(tag, options(decimal), s);
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

JSObject _percentFormatter(
  JSObject locale,
  JSObject? display, [
  JSObject? grouping,
]) {
  final tag = localeTag(locale);
  final mode = display == null ? 'Standard' : enumStringValue(display);
  // ExplicitSign → always show sign. Approximate has no Intl equivalent;
  // rendered as Standard (documented PARTIAL).
  final signDisplay = (mode == 'ExplicitSign' ? 'always' : 'auto').toJS;
  final useGrouping = _useGrouping(grouping);
  final (beforeParts, afterParts) = _percentAffixParts(tag);
  final before = beforeParts.map((p) => p.$2).join();
  final after = afterParts.map((p) => p.$2).join();
  final o = JSObject();
  JSObject numOptions(JSObject decimal) => jsOptions({
    'signDisplay': signDisplay,
    'useGrouping': useGrouping,
    ..._digitJsOptions(decimal),
  });

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    final num = _fmt(tag, numOptions(decimal), s).toDart;
    return '$before$num$after'.toJS;
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    final numParts = _intlParts(
      intlFormat(
        'NumberFormat',
        tag,
        numOptions(decimal),
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

JSObject _unitsFormatter(
  JSObject locale,
  JSString unitId,
  JSObject? width, [
  JSObject? grouping,
]) {
  final tag = localeTag(locale);
  final display = _unitDisplay(width);
  final base = <String, JSAny?>{
    'style': 'unit'.toJS,
    'unit': unitId,
    'unitDisplay': display.toJS,
    'useGrouping': _useGrouping(grouping),
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
  // The reused int formatter for un-shaped integer values, else one pinned to
  // the resolved digit options.
  JSObject fmtFor(JSObject decimal) {
    final d = _digitOpts(decimal);
    if (d.minFrac == 0 && d.maxFrac == 0 && d.minInt == null) return intFmt;
    return intlFormat(
      'NumberFormat',
      tag,
      jsOptions({...base, ..._digitJsOptions(decimal)}),
    );
  }

  JSString format(JSObject decimal) {
    final s = _decimalStr(decimal);
    return fmtFor(decimal).callMethod<JSString>('format'.toJS, s.toJS);
  }

  JSObject formatToParts(JSObject decimal) {
    final s = _decimalStr(decimal);
    return _wrapParts(
      _intlParts(
        fmtFor(
          decimal,
        ).callMethod<JSArray<JSObject>>('formatToParts'.toJS, s.toJS),
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
      'fromNumberWithSignificantDigits':
          ((JSNumber v, JSNumber digits) =>
                  _decimal(_sigString(v.toDartDouble, digits.toDartInt)))
              .toJS,
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
  // The full ECMA-402 sets — the shared Decimal mirror's toJs() resolves
  // sentinels here, and the intent recorder reads their names back to
  // build the Intl options.
  put(
    module,
    'DecimalSignedRoundingMode',
    enumClass(const [
      'Expand', 'Trunc', 'HalfExpand', 'HalfTrunc', 'HalfEven', //
      'Ceil', 'Floor', 'HalfCeil', 'HalfFloor',
    ]),
  );
  put(
    module,
    'DecimalSignDisplay',
    enumClass(const ['Auto', 'Never', 'Always', 'ExceptZero', 'Negative']),
  );
  put(
    module,
    'CompactDecimalFormatter',
    staticClass({
      'createShort':
          ((JSObject locale, [JSObject? grouping]) =>
                  _compactFormatter(locale, 'short', grouping))
              .toJS,
      'createLong':
          ((JSObject locale, [JSObject? grouping]) =>
                  _compactFormatter(locale, 'long', grouping))
              .toJS,
    }),
  );
  put(
    module,
    'DecimalRoundingIncrement',
    enumClass(const [
      'MultiplesOf1', 'MultiplesOf2', 'MultiplesOf5', 'MultiplesOf25', //
    ]),
  );

  put(
    module,
    'CurrencyFormatter',
    staticClass({
      'createWithWidth':
          ((JSObject locale, [JSObject? width, JSObject? grouping]) =>
                  _currencyFormatter(locale, width, grouping))
              .toJS,
    }),
  );
  put(module, 'CurrencyWidth', enumClass(const ['Short', 'Narrow', 'Code']));

  put(
    module,
    'LongCurrencyFormatter',
    staticClass({
      'createForCurrency':
          ((JSObject locale, JSString code, [JSObject? grouping]) =>
                  _longCurrencyFormatter(locale, code, grouping))
              .toJS,
    }),
  );

  put(
    module,
    'PercentFormatter',
    staticClass({
      'createWithDisplay':
          ((JSObject locale, [JSObject? display, JSObject? grouping]) =>
                  _percentFormatter(locale, display, grouping))
              .toJS,
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
          ((JSObject locale, JSString unit,
                      [JSObject? width, JSObject? grouping]) =>
                  _unitsFormatter(locale, unit, width, grouping))
              .toJS,
    }),
  );
  put(module, 'UnitsWidth', enumClass(const ['Long', 'Short', 'Narrow']));
}
