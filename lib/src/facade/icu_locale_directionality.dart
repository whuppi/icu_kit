import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale directionality lookup — STABLE.
///
/// Answers "is this locale RTL or LTR?" for setting Flutter's
/// `Directionality` widget or HTML's `dir` attribute per user locale.
///
/// Example:
///
/// ```dart
/// final dir = IcuLocaleDirectionality();
/// dir.directionOf('ar');     // IcuLocaleDirection.rightToLeft
/// dir.directionOf('en');     // IcuLocaleDirection.leftToRight
/// dir.directionOf('zxx');    // IcuLocaleDirection.unknown (no language data)
/// dir.isRtl('he');           // true
/// dir.isLtr('en');           // true
/// ```
final class IcuLocaleDirectionality {
  IcuLocaleDirectionality._(this._ffi);

  /// Create a directionality lookup; [extended] covers more locales
  /// at the cost of a larger data table.
  ///
  /// Throws [IcuDataError] when the data is unavailable.
  factory IcuLocaleDirectionality({bool extended = false}) {
    try {
      return IcuLocaleDirectionality._(
        extended
            ? dispatch.localeDirectionalityExtended()
            : dispatch.localeDirectionalityDefault(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'LocaleDirectionality unavailable: $e',
        marker: 'LocaleDirectionality',
      );
    }
  }
  final icu.LocaleDirectionality _ffi;

  /// Direction for [locale]: ltr / rtl / unknown.
  IcuLocaleDirection directionOf(String locale) {
    final loc = IcuLocale.parse(locale);
    return switch (_ffi[loc.ffi]) {
      icu.LocaleDirection.leftToRight => IcuLocaleDirection.leftToRight,
      icu.LocaleDirection.rightToLeft => IcuLocaleDirection.rightToLeft,
      icu.LocaleDirection.unknown => IcuLocaleDirection.unknown,
    };
  }

  /// True if [locale] is left-to-right.
  bool isLtr(String locale) {
    final loc = IcuLocale.parse(locale);
    return _ffi.isLeftToRight(loc.ffi);
  }

  /// True if [locale] is right-to-left.
  bool isRtl(String locale) {
    final loc = IcuLocale.parse(locale);
    return _ffi.isRightToLeft(loc.ffi);
  }
}

/// Direction of a locale.
enum IcuLocaleDirection {
  /// Left-to-right script (e.g. Latin, Cyrillic).
  leftToRight,

  /// Right-to-left script (e.g. Arabic, Hebrew).
  rightToLeft,

  /// Direction could not be determined.
  unknown,
}
