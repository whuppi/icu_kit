// §3f — collation, case mapping, normalization, segmentation. Over
// Intl.Collator, String.toLocale{Upper,Lower}Case, String.normalize,
// Intl.Segmenter. See PLAN_BROWSER_INTL.md §3f.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

// String.prototype methods as external members on JSString — no runtime cast,
// no unsafe callMethod. These dispatch straight to the JS string wrapper.
extension on JSString {
  external JSString toLocaleLowerCase(JSString locale);
  external JSString toLocaleUpperCase(JSString locale);
  external JSString normalize(JSString form);
}

// ── Collator (PARTIAL) ───────────────────────────────────────────────────

JSObject _collator(JSObject locale, JSObject options) {
  final strengthOpt = options.getProperty<JSObject?>('strength'.toJS);
  final sensitivity = strengthOpt == null
      ? null
      : switch (enumStringValue(strengthOpt)) {
          'Primary' => 'base',
          'Secondary' => 'accent',
          'Tertiary' => 'variant',
          // quaternary / identical have no Intl.Collator equivalent.
          _ => unsupported('IcuCollator strength quaternary/identical'),
        };
  final altOpt = options.getProperty<JSObject?>('alternateHandling'.toJS);
  final ignorePunctuation = altOpt == null
      ? null
      : enumStringValue(altOpt) == 'Shifted';
  // caseLevel / maxVariable have no Intl.Collator mapping (PARTIAL).

  final col = intlFormat(
    'Collator',
    localeTag(locale),
    jsOptions({
      if (sensitivity != null) 'sensitivity': sensitivity.toJS,
      if (ignorePunctuation != null)
        'ignorePunctuation': ignorePunctuation.toJS,
    }),
  );
  final o = JSObject();
  JSNumber compare(JSString a, JSString b) =>
      col.callMethod<JSNumber>('compare'.toJS, a, b);
  o.setProperty('compare'.toJS, compare.toJS);
  return o;
}

// ── CaseMapper (PARTIAL) / TitlecaseMapper (THROW methods) ───────────────

JSObject _caseMapper() {
  final o = JSObject();
  JSString lower(JSString s, JSObject locale) =>
      s.toLocaleLowerCase(localeTag(locale).toJS);
  JSString upper(JSString s, JSObject locale) =>
      s.toLocaleUpperCase(localeTag(locale).toJS);
  // JS has no Unicode case folding; lowercase is NOT fold.
  JSString fold(JSString s) => unsupported('IcuCaseMapper.fold');
  JSString foldTurkic(JSString s) => unsupported('IcuCaseMapper.foldTurkic');
  o.setProperty('lowercase'.toJS, lower.toJS);
  o.setProperty('uppercase'.toJS, upper.toJS);
  o.setProperty('fold'.toJS, fold.toJS);
  o.setProperty('foldTurkic'.toJS, foldTurkic.toJS);
  return o;
}

// TitlecaseMapper must CONSTRUCT (IcuCaseMapper builds it alongside the case
// mapper) but its method throws — no browser titlecasing API. §3g exception.
JSObject _titlecaseMapper() {
  final o = JSObject();
  JSString seg(JSString s, JSObject l, JSObject opts) =>
      unsupported('IcuCaseMapper.titlecase');
  o.setProperty('titlecaseSegment'.toJS, seg.toJS);
  return o;
}

// ── Normalizers (FULL — String.normalize) ────────────────────────────────

JSObject _normalizer(String form) {
  final o = JSObject();
  JSString normalize(JSString s) => s.normalize(form.toJS);
  // Diplomat returns bools as 0/1 (binding reads toDartInt).
  JSNumber isNormalized(JSString s) =>
      (s.toDart == s.toDart.normalizedWith(form) ? 1 : 0).toJS;
  JSNumber isNormalizedUpTo(JSString s) {
    final str = s.toDart;
    final n = str.normalizedWith(form);
    if (n == str) return str.length.toJS;
    var i = 0;
    final min = str.length < n.length ? str.length : n.length;
    while (i < min && str.codeUnitAt(i) == n.codeUnitAt(i)) {
      i++;
    }
    return i.toJS;
  }

  o.setProperty('normalize'.toJS, normalize.toJS);
  o.setProperty('isNormalized'.toJS, isNormalized.toJS);
  o.setProperty('isNormalizedUpTo'.toJS, isNormalizedUpTo.toJS);
  return o;
}

// ── Segmenters (grapheme/word/sentence FULL; line THROW) ─────────────────

// The break iterator over one input: next() yields 0, then each boundary, then
// input length, then -1 (the facade does `prev = next()` expecting the leading
// 0). [seg] is the reused Intl.Segmenter for this formatter.
JSObject _breakIterator(JSObject seg, String input) {
  final segments = seg.callMethod<JSObject>('segment'.toJS, input.toJS);
  // Array.from materializes the Segments iterable; each segment's `.index` is
  // its UTF-16 start. Boundaries = [0, starts…, length]; the leading 0 is the
  // first segment's index (the facade reads it as `prev`). The facade's next()
  // loop walks every boundary to -1, so this is the same total work as ICU4X's
  // native iterator walk — full materialization, not a lazy stream, is fine.
  final arr = globalContext
      .getProperty<JSObject>('Array'.toJS)
      .callMethod<JSArray<JSObject>>('from'.toJS, segments)
      .toDart;
  final bounds = [
    for (final s in arr) s.getProperty<JSNumber>('index'.toJS).toDartInt,
    input.length,
  ];
  var i = 0;
  final o = JSObject();
  JSNumber next() => (i < bounds.length ? bounds[i++] : -1).toJS;
  o.setProperty('next'.toJS, next.toJS);
  return o;
}

JSObject _segmenter(String tag, String granularity) {
  // Build the Intl.Segmenter ONCE — it is keyed only on (tag, granularity),
  // both fixed for this formatter — and reuse it across segment() calls,
  // matching ICU4X's create-once / segment-many shape.
  final seg = intlFormat(
    'Segmenter',
    tag,
    jsOptions({'granularity': granularity.toJS}),
  );
  final o = JSObject();
  JSObject segment(JSString input) => _breakIterator(seg, input.toDart);
  o.setProperty('segment'.toJS, segment.toJS);
  return o;
}

/// Register §3f, overriding throw-all defaults.
void registerCollatorCaseNormalizeSegment(JSObject module) {
  // Collator (new(locale, options)).
  put(
    module,
    'Collator',
    ctorClass(((JSObject l, JSObject o) => _collator(l, o)).toJS),
  );
  put(
    module,
    'CollatorStrength',
    enumClass(const [
      'Primary',
      'Secondary',
      'Tertiary',
      'Quaternary',
      'Identical',
    ]),
  );
  put(
    module,
    'CollatorAlternateHandling',
    enumClass(const ['NonIgnorable', 'Shifted']),
  );
  put(
    module,
    'CollatorMaxVariable',
    enumClass(const ['Space', 'Punctuation', 'Symbol', 'Currency']),
  );
  put(module, 'CollatorCaseLevel', enumClass(const ['Off', 'On']));

  // CaseMapper (new) + TitlecaseMapper (new, method throws).
  put(module, 'CaseMapper', ctorClass(_caseMapper.toJS));
  put(module, 'TitlecaseMapper', ctorClass(_titlecaseMapper.toJS));
  put(
    module,
    'LeadingAdjustment',
    enumClass(const ['Auto', 'None', 'ToCased']),
  );
  put(module, 'TrailingCase', enumClass(const ['Lower', 'Unchanged']));

  // Normalizers.
  put(
    module,
    'ComposingNormalizer',
    staticClass({
      'createNfc': (() => _normalizer('NFC')).toJS,
      'createNfkc': (() => _normalizer('NFKC')).toJS,
    }),
  );
  put(
    module,
    'DecomposingNormalizer',
    staticClass({
      'createNfd': (() => _normalizer('NFD')).toJS,
      'createNfkd': (() => _normalizer('NFKD')).toJS,
    }),
  );

  // Segmenters (grapheme new; word static; sentence new). Line stays
  // throw-all — Intl.Segmenter has no line granularity.
  put(
    module,
    'GraphemeClusterSegmenter',
    ctorClass((() => _segmenter('und', 'grapheme')).toJS),
  );
  put(
    module,
    'WordSegmenter',
    staticClass({
      'createAuto': (() => _segmenter('und', 'word')).toJS,
      'createAutoWithContentLocale': ((JSObject l) => _segmenter(
        localeTag(l),
        'word',
      )).toJS,
    }),
  );
  put(
    module,
    'SentenceSegmenter',
    ctorClass(
      (() => _segmenter('und', 'sentence')).toJS,
      statics: {
        'createWithContentLocale': ((JSObject l) => _segmenter(
          localeTag(l),
          'sentence',
        )).toJS,
      },
    ),
  );
}

extension _Norm on String {
  String normalizedWith(String form) {
    // Dart has no String.normalize; round-trip through JS.
    return toJS.normalize(form.toJS).toDart;
  }
}
