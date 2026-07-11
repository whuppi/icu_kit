// Marker presets for slicing postcards (`bin/slice.dart`). The single
// source of truth for preset definitions — do not duplicate them elsewhere.
//
// CLDR is a set of ~300 "markers" (DecimalSymbolsV1, SegmenterBreakWordV1,
// …), each a slice of data for one capability. `datagen --markers all`
// pulls every one (7 MB+ per locale); a real app needs a handful. These
// presets map icu_kit's FACADE FAMILIES to the markers they use, so a
// consumer writes `--markers=format-core` instead of naming 14 markers.
//
// The marker UNIVERSE is read live from the vendored registry
// (`vendor/icu4x/provider/registry/src/lib.rs`) — so it never drifts when
// the icu4x submodule is bumped; new markers in a family are picked up
// automatically. Presets are prefix rules over that universe. Both callers
// have `vendor/` present (they run datagen from it), so the registry is
// always readable when presets resolve.

import 'dart:io';

/// The proven "format-core" set — decimal, plurals, Gregorian date/time,
/// likely-subtags, and UTS46 (IDNA). Exact names (each matches only
/// itself), kept identical to `tool/regen_test_postcards.dart`'s
/// `stableMarkers` — the set the postcard round-trip tests already prove.
/// Covers: IcuNumberFormat.decimal, IcuPluralRules, IcuDate/Time/
/// DateTimeFormat (Gregorian), IcuLocale parse/expand, IcuIdna.
const List<String> _formatCore = [
  'DecimalSymbolsV1',
  'DecimalDigitsV1',
  'PluralsCardinalV1',
  'PluralsOrdinalV1',
  'DatetimeNamesMonthGregorianV1',
  'DatetimeNamesYearGregorianV1',
  'DatetimeNamesWeekdayV1',
  'DatetimeNamesDayperiodV1',
  'DatetimePatternsDateGregorianV1',
  'DatetimePatternsTimeV1',
  'DatetimePatternsGlueV1',
  'LocaleLikelySubtagsLanguageV1',
  'LocaleLikelySubtagsScriptRegionV1',
  'NormalizerUts46DataV1',
];

/// format-core PLUS the experimental formatters (currency, percent, unit,
/// relative-time) and lists / compact / duration. Prefixes match whole
/// families: `Currency*`, `Unit*`, `{Long,Short,Narrow}*Relative*`, `List*`.
const List<String> _formatExtendedExtra = [
  'Currency',
  'PercentEssentials',
  'Unit',
  'List',
  'Long', // {Long,Short,Narrow}<span>RelativeV1
  'Short', // (also ShortCurrencyCompactV1 — currency-adjacent, fine)
  'Narrow',
  'DecimalCompact',
  'DigitalDuration',
];

/// The Unicode-machinery facades: IcuSegmenter, IcuCaseMapper,
/// IcuNormalizer, IcuBidi, IcuProperties, IcuExemplarCharacters.
const List<String> _text = [
  'Segmenter',
  'CaseMap',
  'Normalizer',
  'Property',
  'LocaleExemplarCharacters',
  'LocaleScriptDirection', // bidi/direction
];

/// The locale-algebra facades: IcuCollator, IcuLocaleExpander/Fallbacker/
/// Directionality, IcuLocaleCanonicalizer, IcuRegion/LocaleDisplayNames.
const List<String> _locale = [
  'Collation',
  'LanguageDisplayNames',
  'LocaleDisplayNames',
  'RegionDisplayNames',
  'ScriptDisplayNames',
  'VariantDisplayNames',
  'LocaleNames',
  'LocaleLikelySubtags',
  'LocaleAliases',
  'LocaleParents',
  'LocaleScriptDirection',
];

/// Preset name → the marker-name prefixes that define it. A marker joins a
/// preset when its name starts with any prefix (an exact marker name is a
/// prefix of itself). `kit` is the union of the three families — everything
/// the example app uses, minus non-Gregorian calendars / time zones.
Map<String, List<String>> get markerPresets => {
  'format-core': _formatCore,
  'format-extended': [..._formatCore, ..._formatExtendedExtra],
  'text': _text,
  'locale': _locale,
  'kit': {
    ..._formatCore,
    ..._formatExtendedExtra,
    ..._text,
    ..._locale,
  }.toList(),
};

/// The names a user can pass to `--markers`.
List<String> get markerPresetNames => [...markerPresets.keys, 'all'];

/// Every marker name in the vendored registry. Read live so it tracks the
/// pinned icu4x — no hardcoded list to fall out of sync on a submodule bump.
///
/// [vendorIcu4x] is the `vendor/icu4x` directory.
List<String> readMarkerUniverse(Directory vendorIcu4x) {
  final registry = File('${vendorIcu4x.path}/provider/registry/src/lib.rs');
  if (!registry.existsSync()) {
    throw StateError(
      'Marker registry not found at ${registry.path}. Marker presets need '
      'the vendored icu4x submodule — run `git submodule update --init`.',
    );
  }
  // Marker names are CamelCase identifiers ending in V<n> (DecimalSymbolsV1,
  // SegmenterBreakWordV1, …). The registry file is the marker registry, so
  // every such identifier is a real marker.
  final names =
      RegExp(r'\b[A-Z][A-Za-z0-9]+V\d+\b')
          .allMatches(registry.readAsStringSync())
          .map((m) => m[0]!)
          .toSet()
          .toList()
        ..sort();
  return names;
}

/// Resolve a `--markers` spec to concrete datagen marker names.
///
/// [spec] is one of:
///   * `'all'` — returns `['all']`, the datagen keyword (every marker).
///   * a preset name (see [markerPresetNames]) — expanded via [readMarkerUniverse].
///   * a comma-separated list of exact marker names — split and passed through.
///
/// [vendorIcu4x] is only read for preset expansion.
List<String> resolveMarkerSpec(String spec, Directory vendorIcu4x) {
  if (spec == 'all') return const ['all'];

  final prefixes = markerPresets[spec];
  if (prefixes != null) {
    final universe = readMarkerUniverse(vendorIcu4x);
    final matched = universe.where((m) => prefixes.any(m.startsWith)).toList();
    if (matched.isEmpty) {
      throw StateError(
        'Preset "$spec" matched no markers in the registry — the icu4x '
        'marker naming may have changed. Re-verify the preset prefixes in '
        'lib/src/hook/marker_presets.dart against '
        'vendor/icu4x/provider/registry/src/lib.rs.',
      );
    }
    return matched;
  }

  // A single token that isn't a preset and doesn't look like a marker name
  // (CamelCase…V<n>) is almost certainly a mistyped preset — hint, don't
  // fall through to a cryptic datagen "Unknown marker" error.
  final markerName = RegExp(r'^[A-Z][A-Za-z0-9]+V\d+$');
  if (!spec.contains(',') && !markerName.hasMatch(spec)) {
    throw StateError(
      'Unknown preset "$spec". Valid presets: ${markerPresetNames.join(', ')} '
      '(or a comma-separated list of exact marker names like '
      'DecimalSymbolsV1).',
    );
  }

  // Exact, comma-separated marker names.
  final names = spec
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    throw StateError('Empty --markers spec.');
  }
  return names;
}
