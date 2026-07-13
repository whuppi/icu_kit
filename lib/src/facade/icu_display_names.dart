import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale-aware region display names — STABLE.
///
/// Equivalent to `Intl.DisplayNames(locale, {type: 'region'})`. Renders
/// region codes (ISO 3166-1 alpha-2) in the `locale`'s language.
///
/// Example:
///
/// ```dart
/// final fr = IcuRegionDisplayNames(locale: 'fr');
/// fr.of('US');        // "États-Unis"
/// fr.of('FR');        // "France"
/// fr.of('JP');        // "Japon"
/// ```
final class IcuRegionDisplayNames {
  IcuRegionDisplayNames._(this._ffi);

  /// Create a region-name formatter rendering in [locale].
  ///
  /// Throws [IcuDataError] when display-name data is unavailable.
  factory IcuRegionDisplayNames({
    required String locale,
    IcuDisplayNamesStyle? style,
    IcuDisplayNamesFallback? fallback,
  }) {
    final loc = IcuLocale.parse(locale);
    final options = icu.DisplayNamesOptions(
      style: switch (style) {
        null => null,
        IcuDisplayNamesStyle.narrow => icu.DisplayNamesStyle.narrow,
        IcuDisplayNamesStyle.short => icu.DisplayNamesStyle.short,
        IcuDisplayNamesStyle.long => icu.DisplayNamesStyle.long,
        IcuDisplayNamesStyle.menu => icu.DisplayNamesStyle.menu,
      },
      fallback: switch (fallback) {
        null => null,
        IcuDisplayNamesFallback.code => icu.DisplayNamesFallback.code,
        IcuDisplayNamesFallback.none => icu.DisplayNamesFallback.none,
      },
    );
    try {
      return IcuRegionDisplayNames._(
        dispatch.regionDisplayNamesDefault(locale, loc.ffi, options),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Region display names unavailable for $locale: $e',
        locale: locale,
        marker: 'RegionDisplayNames',
      );
    }
  }
  final icu.RegionDisplayNames _ffi;

  /// Render [region] (e.g. "US", "FR", "JP") in this formatter's locale.
  ///
  /// If the region code isn't recognized:
  ///   * With [IcuDisplayNamesFallback.code] (default): returns the code
  ///     unchanged (e.g. "XX" → "XX").
  ///   * With [IcuDisplayNamesFallback.none]: returns an empty string.
  String of(String region) => _ffi.of(region);
}

/// Locale-aware locale-display names — STABLE.
///
/// Equivalent to `Intl.DisplayNames(locale, {type: 'language' | 'script'})`.
/// Renders BCP47 locale identifiers in the formatter's locale.
///
/// Example:
///
/// ```dart
/// final ja = IcuLocaleDisplayNames(locale: 'ja');
/// ja.of('en-GB');     // "イギリス英語"
/// ja.of('zh-Hant');   // "繁体字中国語"
/// ```
final class IcuLocaleDisplayNames {
  IcuLocaleDisplayNames._(this._ffi);

  /// Create a locale-name formatter rendering in [locale].
  ///
  /// Throws [IcuDataError] when display-name data is unavailable.
  factory IcuLocaleDisplayNames({
    required String locale,
    IcuDisplayNamesStyle? style,
    IcuDisplayNamesFallback? fallback,
    IcuLanguageDisplay? languageDisplay,
  }) {
    final loc = IcuLocale.parse(locale);
    final options = icu.DisplayNamesOptions(
      style: switch (style) {
        null => null,
        IcuDisplayNamesStyle.narrow => icu.DisplayNamesStyle.narrow,
        IcuDisplayNamesStyle.short => icu.DisplayNamesStyle.short,
        IcuDisplayNamesStyle.long => icu.DisplayNamesStyle.long,
        IcuDisplayNamesStyle.menu => icu.DisplayNamesStyle.menu,
      },
      fallback: switch (fallback) {
        null => null,
        IcuDisplayNamesFallback.code => icu.DisplayNamesFallback.code,
        IcuDisplayNamesFallback.none => icu.DisplayNamesFallback.none,
      },
      languageDisplay: switch (languageDisplay) {
        null => null,
        IcuLanguageDisplay.dialect => icu.LanguageDisplay.dialect,
        IcuLanguageDisplay.standard => icu.LanguageDisplay.standard,
      },
    );
    try {
      return IcuLocaleDisplayNames._(
        dispatch.localeDisplayNamesFormatterDefault(locale, loc.ffi, options),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Locale display names unavailable for $locale: $e',
        locale: locale,
        marker: 'LocaleDisplayNamesFormatter',
      );
    }
  }
  final icu.LocaleDisplayNamesFormatter _ffi;

  /// Render [locale] in this formatter's locale.
  String of(String locale) {
    final loc = IcuLocale.parse(locale);
    return _ffi.of(loc.ffi);
  }
}

/// Display-name style preset.
///
/// Mirrors ICU4X's `Style` (also matches ECMA-402's `style`):
///   * `narrow` — most compact (e.g. "US")
///   * `short` — abbreviated (e.g. "U.S.")
///   * `long` — full ("United States")
///   * `menu` — for selectors (locale-specific; usually equals long)
enum IcuDisplayNamesStyle {
  /// Most compact (e.g. "US").
  narrow,

  /// Abbreviated (e.g. "U.S.").
  short,

  /// Full name (e.g. "United States").
  long,

  /// For selectors; usually equals long.
  menu,
}

/// What to return when a code isn't recognized.
///
/// Mirrors ECMA-402's `fallback`:
///   * `code` (default) — return the input code as-is
///   * `none` — return empty string
enum IcuDisplayNamesFallback {
  /// Return the input code as-is — the default.
  code,

  /// Return an empty string.
  none,
}

/// How language locales are rendered when both language and region are
/// known. Mirrors ECMA-402's `languageDisplay`:
///   * `dialect` — "British English" (combine into a single name)
///   * `standard` — "English (United Kingdom)" (separate parts)
enum IcuLanguageDisplay {
  /// Combined dialect name (e.g. "British English").
  dialect,

  /// Separated parts (e.g. "English (United Kingdom)").
  standard,
}
