/// icu_kit — pure Dart bindings to ICU4X for full ECMA-402 / Unicode i18n.
///
/// All 6 Flutter platforms supported. Native via `dart:ffi`, web via
/// `dart:js_interop` + WebAssembly. Independent of `unicode.org/package:icu4x`.
///
/// ECMA-402 coverage:
///   * `Intl.PluralRules`     → IcuPluralRules
///   * `Intl.NumberFormat`    → IcuNumberFormat (decimal STABLE) +
///                              IcuCurrencyFormat (currency EXPERIMENTAL) +
///                              IcuPercentFormat (percent EXPERIMENTAL) +
///                              IcuUnitFormat (unit EXPERIMENTAL)
///   * `Intl.DateTimeFormat`  → IcuDateFormat / IcuTimeFormat /
///                              IcuDateTimeFormat / IcuZonedDateTimeFormat /
///                              IcuTimeZoneFormat (standalone)
///   * `Intl.ListFormat`      → IcuListFormat
///   * `Intl.Collator`        → IcuCollator
///   * `Intl.RelativeTimeFormat` → IcuRelativeTimeFormat
///   * `Intl.Segmenter`       → IcuSegmenter (+ IcuLineSegmenter for UAX #14)
///   * `Intl.DisplayNames`    → IcuRegionDisplayNames + IcuLocaleDisplayNames
///   * `Intl.Locale.textInfo.direction` → IcuLocaleDirectionality
///
/// Beyond ECMA-402:
///   * Locale-aware case mapping (Turkish I, German ß) → IcuCaseMapper
///   * Unicode normalization (NFC/NFD/NFKC/NFKD) → IcuNormalizer
///   * Bidirectional algorithm (UAX #9) → IcuBidi
///   * Unicode binary properties (45 properties) → IcuProperties
///   * Unicode enum properties (GeneralCategory, Script, BidiClass,
///     LineBreak, WordBreak, SentenceBreak, EastAsianWidth, etc.)
///     → IcuEnumProperty family
///   * Locale exemplar character sets → IcuExemplarCharacters
///   * Property name ↔ code resolver → IcuPropertyName
///   * Locale fallback chains → IcuLocaleFallbacker
///   * Non-Gregorian calendar arithmetic (17 calendars) → IcuCalendar
///   * Custom CLDR data blobs (subsetting) → IcuDataProvider
///     (paired with `bin/datagen.dart` build tool)
///   * IDNA processing (UTS #46 + RFC 3492 Punycode codec) → IcuIdna
///
/// See `docs/CAPABILITY_ROADMAP.md` for full status.
library;

// ── Init — call IcuKit.init() once before any facade ──────────────────

// ── Init — call IcuKit.init() once before any facade ──────────────────

// ── Init — call IcuKit.init() once before any facade ──────────────────
export 'src/icu_kit.dart';

// ── Data model — where CLDR bytes come from ───────────────────────────
export 'src/data/icu_data.dart';
export 'src/data/icu_data_source.dart';

// ── Errors — sealed; pattern-match on the variants ────────────────────
export 'src/errors/icu_error.dart';

// ── Locale — the input type every facade takes ────────────────────────
export 'src/facade/icu_locale.dart';
export 'src/facade/icu_locale_canonicalizer.dart';
export 'src/facade/icu_locale_directionality.dart';
export 'src/facade/icu_locale_expander.dart';
export 'src/facade/icu_locale_fallbacker.dart';

// ── Formatters — numbers, dates, lists, relative time ─────────────────
export 'src/facade/icu_number_format.dart';
export 'src/facade/icu_currency_format.dart';
export 'src/facade/icu_percent_format.dart';
export 'src/facade/icu_unit_format.dart';
export 'src/facade/icu_date_format.dart';
export 'src/facade/icu_time_format.dart';
export 'src/facade/icu_date_time_format.dart';
export 'src/facade/icu_zoned_date_time_format.dart';
export 'src/facade/icu_time_zone_format.dart';
export 'src/facade/icu_relative_time_format.dart';
export 'src/facade/icu_list_format.dart';
export 'src/facade/icu_plural_rules.dart';

// ── Text & Unicode — segmentation, collation, casing, normalization, bidi, IDNA ──
export 'src/facade/icu_segmenter.dart';
export 'src/facade/icu_collator.dart';
export 'src/facade/icu_case_mapper.dart';
export 'src/facade/icu_normalizer.dart';
export 'src/facade/icu_bidi.dart';
export 'src/facade/icu_idna.dart';
export 'src/facade/icu_exemplar_characters.dart';

// ── Properties, calendars, display names ──────────────────────────────
export 'src/facade/icu_properties.dart';
export 'src/facade/icu_enum_property.dart';
export 'src/facade/icu_property_name.dart';
export 'src/facade/icu_calendar.dart';
export 'src/facade/icu_display_names.dart';
export 'src/facade/icu_data_provider.dart';

// ── Version ───────────────────────────────────────────────────────────
export 'src/version.dart' show packageVersion;
