import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale-aware string comparison — STABLE.
///
/// Equivalent to ECMA-402's `Intl.Collator`. Returns negative/zero/positive
/// `int` like Dart's `Comparator<String>` so the result plugs straight
/// into `List<String>.sort(collator.compare)`.
///
/// Example:
///
/// ```dart
/// final c = IcuCollator(locale: 'sv'); // Swedish: ä, ö are distinct letters
/// final names = ['Östen', 'Anna', 'Åsa'];
/// names.sort(c.compare);
/// // ['Anna', 'Åsa', 'Östen']
/// ```
final class IcuCollator {
  IcuCollator._(this._ffi);

  /// Construct a collator for [locale].
  ///
  /// All option arguments are optional; passing none gives the locale's
  /// default collation. Beyond these options, ECMA-402 features map via
  /// BCP47 locale extensions:
  ///
  ///   * `-u-kf-upper` / `-u-kf-lower` — case-first ordering
  ///   * `-u-kn`        — numeric collation ("file2" < "file10")
  ///   * `-u-co-search` — search-mode collation (ICU4X 2.2 doesn't ship
  ///     search-mode CLDR data)
  factory IcuCollator({
    required String locale,
    IcuCollatorStrength? strength,
    IcuCollatorAlternateHandling? alternateHandling,
    IcuCollatorMaxVariable? maxVariable,
    IcuCollatorCaseLevel? caseLevel,
  }) {
    final loc = IcuLocale.parse(locale);
    final options = icu.CollatorOptions(
      strength: _toFfiStrength(strength),
      alternateHandling: _toFfiAlt(alternateHandling),
      maxVariable: _toFfiMax(maxVariable),
      caseLevel: _toFfiCaseLevel(caseLevel),
    );
    try {
      return IcuCollator._(dispatch.collatorDefault(locale, loc.ffi, options));
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Collator unavailable for $locale: $e',
        locale: locale,
        marker: 'Collator',
      );
    }
  }
  final icu.Collator _ffi;

  /// Compare [left] and [right]. Returns < 0 if `left < right`, 0 if equal,
  /// > 0 if `left > right`. Plugs into `Comparator<String>`.
  int compare(String left, String right) => _ffi.compare(left, right);
}

icu.CollatorStrength? _toFfiStrength(IcuCollatorStrength? s) => switch (s) {
  null => null,
  IcuCollatorStrength.primary => icu.CollatorStrength.primary,
  IcuCollatorStrength.secondary => icu.CollatorStrength.secondary,
  IcuCollatorStrength.tertiary => icu.CollatorStrength.tertiary,
  IcuCollatorStrength.quaternary => icu.CollatorStrength.quaternary,
  IcuCollatorStrength.identical => icu.CollatorStrength.identical,
};

icu.CollatorAlternateHandling? _toFfiAlt(IcuCollatorAlternateHandling? a) =>
    switch (a) {
      null => null,
      IcuCollatorAlternateHandling.nonIgnorable =>
        icu.CollatorAlternateHandling.nonIgnorable,
      IcuCollatorAlternateHandling.shifted =>
        icu.CollatorAlternateHandling.shifted,
    };

icu.CollatorMaxVariable? _toFfiMax(IcuCollatorMaxVariable? m) => switch (m) {
  null => null,
  IcuCollatorMaxVariable.space => icu.CollatorMaxVariable.space,
  IcuCollatorMaxVariable.punctuation => icu.CollatorMaxVariable.punctuation,
  IcuCollatorMaxVariable.symbol => icu.CollatorMaxVariable.symbol,
  IcuCollatorMaxVariable.currency => icu.CollatorMaxVariable.currency,
};

icu.CollatorCaseLevel? _toFfiCaseLevel(IcuCollatorCaseLevel? c) => switch (c) {
  null => null,
  IcuCollatorCaseLevel.off => icu.CollatorCaseLevel.off,
  IcuCollatorCaseLevel.on => icu.CollatorCaseLevel.on,
};

/// Collation strength — how aggressively differences are weighted.
///
/// Mirrors ICU4X's `Strength`. Maps roughly to ECMA-402's `sensitivity`:
///   * `primary` — base letters only ("a" = "A" = "à")
///   * `secondary` — base + diacritics ("a" = "A" but ≠ "à")
///   * `tertiary` — base + diacritics + case (default; "a" ≠ "A")
///   * `quaternary` — adds punctuation distinction
///   * `identical` — full Unicode codepoint equivalence
enum IcuCollatorStrength {
  /// Base letters only ("a" == "A" == "à").
  primary,

  /// Adds diacritics ("a" == "A" but != "à").
  secondary,

  /// Adds case ("a" != "A") — the default.
  tertiary,

  /// Adds punctuation distinction under shifted handling.
  quaternary,

  /// Full Unicode code-point equivalence.
  identical,
}

/// How variable characters (punctuation, symbols) are weighted.
///
/// Mirrors ICU4X's `AlternateHandling`:
///   * `nonIgnorable` (default) — punctuation IS distinguishing
///   * `shifted` — punctuation is shifted to a lower priority,
///     enabling ECMA-402's `ignorePunctuation` semantics
enum IcuCollatorAlternateHandling {
  /// Punctuation IS distinguishing — the default.
  nonIgnorable,

  /// Punctuation shifts to a lower priority (ignorePunctuation
  /// semantics).
  shifted,
}

/// Threshold for what counts as "variable" when `alternateHandling` is
/// [IcuCollatorAlternateHandling.shifted]. Mirrors ICU4X's `MaxVariable`.
enum IcuCollatorMaxVariable {
  /// Only spaces are variable.
  space,

  /// Spaces and punctuation are variable.
  punctuation,

  /// Spaces, punctuation, and symbols are variable.
  symbol,

  /// Spaces, punctuation, symbols, and currency signs are variable.
  currency,
}

/// Whether case is treated as a separate level (between secondary and
/// tertiary) — useful for case-sensitive sorting with primary strength.
enum IcuCollatorCaseLevel {
  /// No dedicated case level — the default.
  off,

  /// Insert a case level between secondary and tertiary.
  on,
}
