import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Standalone time-zone formatting — STABLE.
///
/// Renders a time-zone label without any date/time content. Use cases:
///
///   * "America/Los_Angeles" → "Pacific Daylight Time" / "PDT" / "GMT-7"
///     for a TZ-selector dropdown
///   * Render a list of supported zones in a settings page
///   * Show a one-line zone label next to a date/time elsewhere
///
/// For full date+time+zone formatting, use `IcuZonedDateTimeFormat`.
final class IcuTimeZoneFormat {
  IcuTimeZoneFormat._(this._ffi);

  /// Construct a time-zone formatter for [locale] in the given [style].
  factory IcuTimeZoneFormat({
    required String locale,
    IcuTimeZoneStyle style = IcuTimeZoneStyle.specificShort,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      return IcuTimeZoneFormat._(_buildStandalone(locale, loc.ffi, style));
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Time-zone formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'TimeZoneFormatter.${style.name}',
      );
    }
  }
  final icu.TimeZoneFormatter _ffi;

  /// Format a time zone for [date] (which controls daylight-saving choice
  /// for `specific*` styles).
  ///
  /// [ianaTimeZoneId] is the IANA name (e.g. `"America/Los_Angeles"`).
  /// [utcOffsetSeconds] is the UTC offset in seconds at [date]; pass it
  /// from a `DateTime`'s `timeZoneOffset.inSeconds` for the moment-aware
  /// answer (PDT vs PST), or hardcode for static labelling.
  String format({
    required String ianaTimeZoneId,
    required DateTime date,
    required int utcOffsetSeconds,
  }) {
    final tz = icu.TimeZone.fromIanaId(ianaTimeZoneId);
    final iso = icu.IsoDate(date.year, date.month, date.day);
    final time = icu.Time(date.hour, date.minute, date.second, 0);
    final tzInfo = tz
        .withOffset(icu.UtcOffset.fromSeconds(utcOffsetSeconds))
        .atDateTimeIso(iso, time);
    return _ffi.format(tzInfo);
  }
}

icu.TimeZoneFormatter _buildStandalone(
  String localeStr,
  icu.Locale loc,
  IcuTimeZoneStyle style,
) => switch (style) {
  IcuTimeZoneStyle.specificLong => dispatch.timeZoneFormatterSpecificLong(
    localeStr,
    loc,
  ),
  IcuTimeZoneStyle.specificShort => dispatch.timeZoneFormatterSpecificShort(
    localeStr,
    loc,
  ),
  IcuTimeZoneStyle.localizedOffsetLong =>
    dispatch.timeZoneFormatterLocalizedOffsetLong(localeStr, loc),
  IcuTimeZoneStyle.localizedOffsetShort =>
    dispatch.timeZoneFormatterLocalizedOffsetShort(localeStr, loc),
  IcuTimeZoneStyle.genericLong => dispatch.timeZoneFormatterGenericLong(
    localeStr,
    loc,
  ),
  IcuTimeZoneStyle.genericShort => dispatch.timeZoneFormatterGenericShort(
    localeStr,
    loc,
  ),
  IcuTimeZoneStyle.location => dispatch.timeZoneFormatterLocation(
    localeStr,
    loc,
  ),
  IcuTimeZoneStyle.exemplarCity => dispatch.timeZoneFormatterExemplarCity(
    localeStr,
    loc,
  ),
};

/// Time-zone rendering style. Mirrors ICU4X's eight `TimeZoneFormatter`
/// constructors.
enum IcuTimeZoneStyle {
  /// Specific non-location, long (e.g. "Pacific Daylight Time").
  specificLong,

  /// Specific non-location, short (e.g. "PDT").
  specificShort,

  /// Localized GMT offset, long (e.g. "GMT-07:00").
  localizedOffsetLong,

  /// Localized GMT offset, short (e.g. "GMT-7").
  localizedOffsetShort,

  /// Generic non-location, long (e.g. "Pacific Time").
  genericLong,

  /// Generic non-location, short (e.g. "PT").
  genericShort,

  /// Generic location (e.g. "Los Angeles Time").
  location,

  /// Exemplar city only (e.g. "Los Angeles").
  exemplarCity,
}
