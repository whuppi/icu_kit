import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Canonicalize BCP-47 locale identifiers per CLDR alias rules — STABLE.
///
/// CLDR maintains a canonical form for every locale: `cka` aliases to
/// `cmr`, `nob-bokmal` to `nb`, mixed-case tags get cased correctly.
/// Required for ECMA-402-conformant locale handling.
///
/// Example:
///
/// ```dart
/// final c = IcuLocaleCanonicalizer();
/// c.canonicalize('Pl');             // 'pl'
/// c.canonicalize('eN-uS');          // 'en-US'
/// c.canonicalize('cka');            // 'cmr'
/// c.canonicalize('nob-bokmal');     // 'nb'
/// ```
final class IcuLocaleCanonicalizer {
  IcuLocaleCanonicalizer._(this._ffi);

  /// Construct a canonicalizer with common CLDR data.
  ///
  /// Set [extended] for the larger BCP-47 extension data set. Default
  /// (false) suffices for ECMA-402 use.
  factory IcuLocaleCanonicalizer({bool extended = false}) {
    try {
      return IcuLocaleCanonicalizer._(
        extended
            ? dispatch.localeCanonicalizerExtended()
            : dispatch.localeCanonicalizerDefault(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'LocaleCanonicalizer unavailable: $e',
        marker: 'LocaleCanonicalizer',
      );
    }
  }
  final icu.LocaleCanonicalizer _ffi;

  /// Returns the canonical form of [tag].
  ///
  /// Throws [IcuLocaleParseError] if [tag] is not a valid BCP-47
  /// identifier.
  String canonicalize(String tag) {
    final icu.Locale loc;
    try {
      loc = icu.Locale.fromString(tag);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuLocaleParseError(tag, cause: e);
    }
    _ffi.canonicalize(loc);
    return loc.asBcp47;
  }
}
