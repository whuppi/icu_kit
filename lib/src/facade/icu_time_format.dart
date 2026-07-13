import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_datetime_shared.dart';
import 'icu_locale.dart';

// Re-export the shared enums used by IcuTimeFormat callers.
export 'icu_datetime_shared.dart'
    show IcuDateAlignment, IcuDateLength, IcuTimePrecision;

/// Locale-aware time-only formatting — STABLE.
///
/// Maps Dart's `DateTime` (always proleptic Gregorian) to ICU4X's `Time`,
/// then renders via the locale's hour cycle (12-hour vs 24-hour, driven
/// by the locale; can be overridden via BCP47 `-u-hc-h11/h12/h23/h24`).
final class IcuTimeFormat {
  IcuTimeFormat._(this._ffi);

  /// Time-only formatter for [locale].
  ///
  /// Example: `IcuTimeFormat(locale: 'en-US', length: short)` → "2:32 PM"
  factory IcuTimeFormat({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      final formatter = dispatch.timeFormatterDefault(
        locale,
        loc.ffi,
        length: toFfiLength(length),
        timePrecision: toFfiPrecision(precision),
        alignment: toFfiAlignment(alignment),
      );
      return IcuTimeFormat._(formatter);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Time formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'TimeFormatter',
      );
    }
  }
  final icu.TimeFormatter _ffi;

  /// Format the time portion of a Dart [DateTime].
  ///
  /// Date portion + time-zone of the input are ignored — the wall-clock
  /// hour/minute/second/microsecond are taken as-is. Use IcuZonedDateTimeFormat
  /// when time-zone-aware formatting is needed.
  String format(DateTime time) {
    return _ffi.format(timeFromDart(time));
  }
}
