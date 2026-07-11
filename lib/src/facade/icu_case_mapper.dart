import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale-aware case mapping — STABLE.
///
/// Provides locale-correct uppercase / lowercase / titlecase mapping that
/// Dart's stdlib `String` methods cannot do.
///
/// Example:
///
/// ```dart
/// final cm = IcuCaseMapper();
/// cm.uppercase('istanbul', locale: 'tr');     // "İSTANBUL" (dotted I)
/// cm.lowercase('STRASSE', locale: 'de');      // "strasse"
/// cm.titlecase('hello world', locale: 'en');  // "Hello world"
/// ```
final class IcuCaseMapper {
  IcuCaseMapper._(this._ffi, this._titlecase);

  /// Create a case mapper.
  ///
  /// Throws [IcuDataError] when case-mapping data is unavailable.
  factory IcuCaseMapper() {
    try {
      return IcuCaseMapper._(
        dispatch.caseMapperDefault(),
        dispatch.titlecaseMapperDefault(),
      );
    } catch (e) {
      throw IcuDataError('CaseMapper unavailable: $e', marker: 'CaseMapper');
    }
  }
  final icu.CaseMapper _ffi;
  final icu.TitlecaseMapper _titlecase;

  /// Locale-aware lowercase. Pass [locale] to control language-specific
  /// rules (e.g. Turkish 'I' → 'ı', not 'i').
  String lowercase(String s, {required String locale}) {
    final loc = IcuLocale.parse(locale);
    return _ffi.lowercase(s, loc.ffi);
  }

  /// Locale-aware uppercase. Pass [locale] to control language-specific
  /// rules (e.g. German 'ß' → 'SS' / 'ẞ', Turkish 'i' → 'İ').
  String uppercase(String s, {required String locale}) {
    final loc = IcuLocale.parse(locale);
    return _ffi.uppercase(s, loc.ffi);
  }

  /// Locale-aware titlecase. Operates on a single segment (typically a
  /// word) — pass each word separately for multi-word titlecase, OR use
  /// an `IcuSegmenter.word` iterator and call this on each segment.
  ///
  /// [leadingAdjustment] controls how the leading character is detected
  /// (defaults to `auto` which skips non-cased characters like quotation
  /// marks). [trailingCase] controls whether trailing letters are
  /// lowercased (`lower`, default) or left as-is (`unchanged`).
  String titlecaseSegment(
    String s, {
    required String locale,
    IcuLeadingAdjustment leadingAdjustment = IcuLeadingAdjustment.auto,
    IcuTrailingCase trailingCase = IcuTrailingCase.lower,
  }) {
    final loc = IcuLocale.parse(locale);
    final options = icu.TitlecaseOptions(
      leadingAdjustment: switch (leadingAdjustment) {
        IcuLeadingAdjustment.auto => icu.LeadingAdjustment.auto,
        IcuLeadingAdjustment.none => icu.LeadingAdjustment.none,
        IcuLeadingAdjustment.toCased => icu.LeadingAdjustment.toCased,
      },
      trailingCase: switch (trailingCase) {
        IcuTrailingCase.lower => icu.TrailingCase.lower,
        IcuTrailingCase.unchanged => icu.TrailingCase.unchanged,
      },
    );
    return _titlecase.titlecaseSegment(s, loc.ffi, options);
  }

  /// Case-fold for case-insensitive comparison. **Locale-independent.**
  ///
  /// Use this for case-insensitive search / equality. Output is NOT
  /// suitable for display — it's a normalized form that maps each cased
  /// codepoint to a representative.
  String fold(String s) => _ffi.fold(s);

  /// Turkic case-fold. Variant of [fold] that handles the Turkic dotted/
  /// dotless I correctly for case-insensitive compare in tr / az locales.
  String foldTurkic(String s) => _ffi.foldTurkic(s);
}

/// How the leading character of a titlecase segment is detected.
///
/// Mirrors ICU4X's `LeadingAdjustment`:
///   * `auto` (default) — skip leading non-cased characters
///     (quotes, parens) before applying titlecase
///   * `none` — apply to the literal first character
///   * `toCased` — adjust the first cased character
enum IcuLeadingAdjustment {
  /// Skip leading non-cased characters (quotes, parens) — the default.
  auto,

  /// Apply to the literal first character.
  none,

  /// Adjust the first cased character.
  toCased,
}

/// Whether trailing letters in a titlecase segment are lowercased.
///
/// Mirrors ICU4X's `TrailingCase`:
///   * `lower` (default) — "HELLO" → "Hello"
///   * `unchanged` — "HELLO" → "HELLO" (only first char adjusted)
enum IcuTrailingCase {
  /// Lowercase the rest ("HELLO" → "Hello") — the default.
  lower,

  /// Leave the rest as-is ("HELLO" → "HELLO").
  unchanged,
}
