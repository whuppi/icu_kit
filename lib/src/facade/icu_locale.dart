import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';

/// A parsed BCP-47 locale identifier.
///
/// Wraps ICU4X's `Locale` opaque type with a Dart-friendly constructor and
/// finalization. Construct from a string (`'en-US'`, `'fr'`, `'zh-Hant-TW'`).
///
/// Throws [IcuLocaleParseError] if the string is not a valid BCP-47 identifier.
final class IcuLocale {
  IcuLocale._(this.ffi);

  /// Parse a BCP-47 locale tag.
  factory IcuLocale.parse(String tag) {
    try {
      final loc = icu.Locale.fromString(tag);
      return IcuLocale._(loc);
    } catch (e) {
      // The catch stays broad because the web binding can only throw a raw
      // JS Error on a bad tag — but the cause travels, so a non-parse
      // failure (a missing symbol, an FFI fault) stays diagnosable.
      throw IcuLocaleParseError(tag, cause: e);
    }
  }

  /// The underlying ICU4X locale handle. Internal — facade types pass it
  /// through to bindings.
  final icu.Locale ffi;

  @override
  String toString() => ffi.asBcp47;
}
