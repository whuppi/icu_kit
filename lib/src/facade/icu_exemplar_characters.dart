import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale exemplar character sets — STABLE.
///
/// Each locale ships five sets answering "which characters does this
/// locale use?" — see [IcuExemplarSet] for which set to pick.
///
/// Example:
///
/// ```dart
/// final main = IcuExemplarCharacters(locale: 'en', set: IcuExemplarSet.main);
/// main.contains(0x41);    // true ('A' is in the English main set)
/// main.contains(0x00E9);  // false ('é' is NOT in main, but in auxiliary)
///
/// final aux = IcuExemplarCharacters(locale: 'en', set: IcuExemplarSet.auxiliary);
/// aux.contains(0x00E9);   // true (é is in the English auxiliary set)
/// ```
final class IcuExemplarCharacters {
  IcuExemplarCharacters._(this._ffi);

  /// Create the exemplar set [set] for [locale].
  ///
  /// Throws [IcuDataError] when exemplar data is unavailable.
  factory IcuExemplarCharacters({
    required String locale,
    required IcuExemplarSet set,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      return IcuExemplarCharacters._(switch (set) {
        IcuExemplarSet.main => dispatch.exemplarCharactersMain(locale, loc.ffi),
        IcuExemplarSet.auxiliary => dispatch.exemplarCharactersAuxiliary(
          locale,
          loc.ffi,
        ),
        IcuExemplarSet.punctuation => dispatch.exemplarCharactersPunctuation(
          locale,
          loc.ffi,
        ),
        IcuExemplarSet.numbers => dispatch.exemplarCharactersNumbers(
          locale,
          loc.ffi,
        ),
        IcuExemplarSet.indexHeaders => dispatch.exemplarCharactersIndex(
          locale,
          loc.ffi,
        ),
      });
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Exemplar characters unavailable for $locale (${set.name}): $e',
        locale: locale,
        marker: 'ExemplarCharacters.${set.name}',
      );
    }
  }
  final icu.ExemplarCharacters _ffi;

  /// True if [codePoint] is a member of this exemplar set.
  bool contains(int codePoint) => _ffi.contains(codePoint);

  /// True if every code point in [s] is a member of this exemplar set.
  bool containsString(String s) => _ffi.containsStr(s);
}

/// Which exemplar set to fetch for a locale.
///
///   * `main` — primary letters of the language (a-z for English,
///     а-я for Russian, ا-ي for Arabic)
///   * `auxiliary` — common foreign letters that appear in borrowings
///   * `punctuation` — common punctuation marks
///   * `numbers` — typical digit characters
///   * `indexHeaders` — characters used as A-Z–style index headers
///     (named `indexHeaders` rather than `index` to avoid shadowing
///     `Enum.index`)
enum IcuExemplarSet {
  /// Letters the language needs for ordinary writing.
  main,

  /// Common foreign letters that appear in borrowings.
  auxiliary,

  /// Common punctuation marks.
  punctuation,

  /// Typical digit characters.
  numbers,

  /// A-Z-style index headers (named to avoid shadowing `Enum.index`).
  indexHeaders,
}
