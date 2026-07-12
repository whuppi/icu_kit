import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Locale likely-subtag expansion / minimization — STABLE.
///
/// CLDR's "likely subtags" data lets you fill in missing fields:
/// `en` → `en-Latn-US`, `zh-Hant` → `zh-Hant-TW`. The reverse drops
/// fields the expansion would have added.
///
/// Mirrors ECMA-402's `Intl.Locale.prototype.maximize()` and
/// `.minimize()` methods.
///
/// Example:
///
/// ```dart
/// final e = IcuLocaleExpander();
/// e.maximize('en');                 // 'en-Latn-US'
/// e.maximize('zh-Hant');            // 'zh-Hant-TW'
/// e.minimize('en-Latn-US');         // 'en'
/// e.minimize('zh-Hant-TW');         // 'zh-Hant' (favoring region by default)
/// e.minimizeFavorScript('zh-Hant-TW');  // 'zh-Hant'
/// ```
final class IcuLocaleExpander {
  IcuLocaleExpander._(this._ffi);

  /// Construct an expander.
  ///
  /// Set [extended] for the larger likely-subtags data set covering
  /// historical / minority locales. Default (false) suffices for
  /// ECMA-402 conformance.
  factory IcuLocaleExpander({bool extended = false}) {
    try {
      return IcuLocaleExpander._(
        extended
            ? dispatch.localeExpanderExtended()
            : dispatch.localeExpanderDefault(),
      );
    } catch (e) {
      throw IcuDataError(
        'LocaleExpander unavailable: $e',
        marker: 'LocaleExpander',
      );
    }
  }
  final icu.LocaleExpander _ffi;

  /// Returns [tag] with likely subtags filled in.
  String maximize(String tag) {
    final loc = _parse(tag);
    _ffi.maximize(loc);
    return loc.asBcp47;
  }

  /// Returns [tag] with subtags removed that match likely-subtag
  /// defaults. Region is favored over script in ambiguous cases (use
  /// [minimizeFavorScript] for the opposite preference).
  String minimize(String tag) {
    final loc = _parse(tag);
    _ffi.minimize(loc);
    return loc.asBcp47;
  }

  /// Like [minimize] but keeps the script when minimizing would force
  /// a choice between script and region.
  String minimizeFavorScript(String tag) {
    final loc = _parse(tag);
    _ffi.minimizeFavorScript(loc);
    return loc.asBcp47;
  }

  icu.Locale _parse(String tag) {
    try {
      return icu.Locale.fromString(tag);
    } catch (e) {
      throw IcuLocaleParseError(tag, cause: e);
    }
  }
}
