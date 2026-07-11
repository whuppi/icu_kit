import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// CLDR plural categories.
///
/// Mirrors ICU4X's `PluralCategory` and ECMA-402's `Intl.PluralRules` output.
/// Categories are language-specific subsets — English uses `one`/`other` for
/// cardinals; Arabic uses all six.
enum IcuPluralCategory {
  /// CLDR `zero` (e.g. 0 in Latvian).
  zero,

  /// CLDR `one` — singular (e.g. 1 in en-US).
  one,

  /// CLDR `two` — dual (e.g. 2 in Arabic).
  two,

  /// CLDR `few` — paucal (e.g. 2-4 in Czech).
  few,

  /// CLDR `many` (e.g. 5+ in Arabic, fractions in Czech).
  many,

  /// CLDR `other` — the catch-all every locale has.
  other;

  /// Lookup by lowercase name (`'one'`, `'other'`, etc.).
  static IcuPluralCategory? tryParse(String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// CLDR plural rules for a given locale.
///
/// Construct via [IcuPluralRules.cardinal] or [IcuPluralRules.ordinal]. Use
/// [category] to classify a numeric value into a [IcuPluralCategory].
///
/// Examples:
/// ```dart
/// final cardinal = IcuPluralRules.cardinal('en');
/// cardinal.category(1);     // → IcuPluralCategory.one
/// cardinal.category(2);     // → IcuPluralCategory.other
///
/// final ordinal = IcuPluralRules.ordinal('en');
/// ordinal.category(1);      // → IcuPluralCategory.one    ("1st")
/// ordinal.category(2);      // → IcuPluralCategory.two    ("2nd")
/// ordinal.category(3);      // → IcuPluralCategory.few    ("3rd")
/// ordinal.category(4);      // → IcuPluralCategory.other  ("4th")
/// ```
final class IcuPluralRules {
  IcuPluralRules._(this._ffi);

  /// Construct cardinal plural rules (1 apple / 2 apples) for [locale].
  ///
  /// Throws [IcuLocaleParseError] if [locale] doesn't parse, or
  /// [IcuDataError] if CLDR plural data is unavailable for the locale.
  factory IcuPluralRules.cardinal(String locale) {
    final parsed = IcuLocale.parse(locale);
    try {
      final rules = dispatch.pluralRulesCardinal(locale, parsed.ffi);
      return IcuPluralRules._(rules);
    } catch (e) {
      throw IcuDataError(
        'Cardinal plural rules unavailable for $locale: $e',
        locale: locale,
        marker: 'PluralRules.cardinal',
      );
    }
  }

  /// Construct ordinal plural rules (1st / 2nd / 3rd) for [locale].
  ///
  /// Throws [IcuLocaleParseError] if [locale] doesn't parse, or
  /// [IcuDataError] if CLDR ordinal data is unavailable for the locale.
  factory IcuPluralRules.ordinal(String locale) {
    final parsed = IcuLocale.parse(locale);
    try {
      final rules = dispatch.pluralRulesOrdinal(locale, parsed.ffi);
      return IcuPluralRules._(rules);
    } catch (e) {
      throw IcuDataError(
        'Ordinal plural rules unavailable for $locale: $e',
        locale: locale,
        marker: 'PluralRules.ordinal',
      );
    }
  }
  final icu.PluralRules _ffi;

  /// Classify [value] into a CLDR plural category.
  ///
  /// Accepts integers and doubles. Negative numbers are categorized by their
  /// absolute value (per CLDR convention).
  IcuPluralCategory category(num value) {
    final operands = icu.PluralOperands.fromString(value.toString());
    final ffiCategory = _ffi.categoryFor(operands);
    return _toFacadeCategory(ffiCategory);
  }

  /// Returns the set of categories this rule set may produce.
  Set<IcuPluralCategory> get supportedCategories {
    final c = _ffi.categories;
    final out = <IcuPluralCategory>{};
    if (c.zero) out.add(IcuPluralCategory.zero);
    if (c.one) out.add(IcuPluralCategory.one);
    if (c.two) out.add(IcuPluralCategory.two);
    if (c.few) out.add(IcuPluralCategory.few);
    if (c.many) out.add(IcuPluralCategory.many);
    if (c.other) out.add(IcuPluralCategory.other);
    return out;
  }
}

IcuPluralCategory _toFacadeCategory(icu.PluralCategory ffi) {
  return switch (ffi) {
    icu.PluralCategory.zero => IcuPluralCategory.zero,
    icu.PluralCategory.one => IcuPluralCategory.one,
    icu.PluralCategory.two => IcuPluralCategory.two,
    icu.PluralCategory.few => IcuPluralCategory.few,
    icu.PluralCategory.many => IcuPluralCategory.many,
    icu.PluralCategory.other => IcuPluralCategory.other,
  };
}
