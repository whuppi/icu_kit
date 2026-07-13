import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale-aware list formatting — STABLE.
///
/// Equivalent to ECMA-402's `Intl.ListFormat`. Joins a list of strings
/// using the locale's conjunction / disjunction / unit pattern.
///
/// Example:
///
/// ```dart
/// final fmt = IcuListFormat.and(locale: 'en');
/// fmt.format(['Alice', 'Bob', 'Carol']);    // "Alice, Bob, and Carol"
///
/// final or = IcuListFormat.or(locale: 'en');
/// or.format(['red', 'green', 'blue']);      // "red, green, or blue"
/// ```
final class IcuListFormat {
  IcuListFormat._(this._ffi);

  /// Conjunction list ("A, B, and C"). ECMA-402 `type: 'conjunction'`.
  factory IcuListFormat.and({
    required String locale,
    IcuListLength length = IcuListLength.long,
  }) => _build(
    locale: locale,
    marker: 'ListFormatter.and',
    build: (l, loc) =>
        dispatch.listFormatterAndWithLength(l, loc, _toFfiLength(length)),
  );

  /// Disjunction list ("A, B, or C"). ECMA-402 `type: 'disjunction'`.
  factory IcuListFormat.or({
    required String locale,
    IcuListLength length = IcuListLength.long,
  }) => _build(
    locale: locale,
    marker: 'ListFormatter.or',
    build: (l, loc) =>
        dispatch.listFormatterOrWithLength(l, loc, _toFfiLength(length)),
  );

  /// Unit list ("3 hr 4 min"). ECMA-402 `type: 'unit'`.
  factory IcuListFormat.unit({
    required String locale,
    IcuListLength length = IcuListLength.long,
  }) => _build(
    locale: locale,
    marker: 'ListFormatter.unit',
    build: (l, loc) =>
        dispatch.listFormatterUnitWithLength(l, loc, _toFfiLength(length)),
  );
  final icu.ListFormatter _ffi;

  /// Format [items] joined by the locale's pattern for this list type.
  ///
  /// Empty list → empty string. Single-item list → that item unchanged.
  /// Two-item list → locale-specific two-item pattern (en: "A and B").
  String format(List<String> items) => _ffi.format(items);

  // ---- internal helpers -------------------------------------------------

  static IcuListFormat _build({
    required String locale,
    required String marker,
    required icu.ListFormatter Function(String localeStr, icu.Locale loc) build,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      return IcuListFormat._(build(locale, loc.ffi));
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'List formatter unavailable for $locale: $e',
        locale: locale,
        marker: marker,
      );
    }
  }
}

icu.ListLength _toFfiLength(IcuListLength length) => switch (length) {
  IcuListLength.long => icu.ListLength.wide,
  IcuListLength.short => icu.ListLength.short,
  IcuListLength.narrow => icu.ListLength.narrow,
};

/// Length presets that mirror ECMA-402's `style` option for ListFormat.
///
/// Maps to ICU4X's `ListLength`:
///   * `IcuListLength.long`   → ICU4X `wide`   (e.g. "A, B, and C")
///   * `IcuListLength.short`  → ICU4X `short`  (e.g. "A, B, & C")
///   * `IcuListLength.narrow` → ICU4X `narrow` (e.g. "A, B, C")
enum IcuListLength {
  /// Full conjunction (e.g. "A, B, and C" in en-US).
  long,

  /// Abbreviated conjunction (e.g. "A, B, & C" in en-US).
  short,

  /// Separators only (e.g. "A, B, C").
  narrow,
}
