import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_datetime_shared.dart';
import 'icu_locale.dart';

export 'icu_datetime_shared.dart'
    show IcuDateAlignment, IcuDateLength, IcuTimePrecision, IcuYearStyle;

/// How the time-zone is rendered alongside the date+time.
///
/// Mirrors ICU4X 2.2's `ZonedDateTimeFormatter` constructors:
///
///   * `specificLong` / `specificShort` — daylight-aware names like
///     "Pacific Daylight Time" / "PDT". Different in summer vs. winter.
///   * `localizedOffsetLong` / `localizedOffsetShort` — UTC offsets like
///     "GMT-07:00" / "GMT-7".
///   * `genericLong` / `genericShort` — non-daylight-aware names like
///     "Pacific Time" / "PT". Same all year.
///   * `location` — locale-specific exemplar city, like "Los Angeles Time".
///     Requires extra CLDR data markers; available in self-built data
///     bundles, may throw `IcuDataError` (`DataMarkerNotFound`) on the
///     compiled-data path.
///   * `exemplarCity` — just the exemplar city, like "Los Angeles". Same
///     data caveat as `location`.
///
/// ECMA-402's `timeZoneName: 'short' | 'long' | 'shortOffset' | 'longOffset'
/// | 'shortGeneric' | 'longGeneric'` maps roughly to:
///
///   * `'long'` → `specificLong`
///   * `'short'` → `specificShort`
///   * `'longOffset'` → `localizedOffsetLong`
///   * `'shortOffset'` → `localizedOffsetShort`
///   * `'longGeneric'` → `genericLong`
///   * `'shortGeneric'` → `genericShort`
enum IcuZoneStyle {
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

/// Locale-aware time-zone-aware date+time formatting — STABLE.
///
/// 7 field-set constructors mirror `IcuDateTimeFormat`'s shape — pick
/// whichever combination of (Year, Month, Day, weekDay, Time) you want
/// to render. `yearStyle` only applies to constructors that include `y`
/// (.ymdt and .ymdet).
final class IcuZonedDateTimeFormat {
  IcuZonedDateTimeFormat._(this._ffi);

  /// Day + Time (e.g. "15, 14:30").
  factory IcuZonedDateTimeFormat.dt({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.dt',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterDt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Month + Day + Time (e.g. "Jan 15, 14:30").
  factory IcuZonedDateTimeFormat.mdt({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.mdt',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterMdt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Year + Month + Day + Time (e.g. "Jan 15, 2024, 14:30"). The most
  /// common shape; ECMA-402 `dateStyle` + `timeStyle` map here.
  factory IcuZonedDateTimeFormat.ymdt({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.ymdt',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterYmdt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
      yearStyle: toFfiYearStyle(yearStyle),
    ),
  );

  /// Day + weekDay + Time (e.g. "Mon 15, 14:30").
  factory IcuZonedDateTimeFormat.det({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.det',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterDet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Month + Day + weekDay + Time (e.g. "Mon, Jan 15, 14:30").
  factory IcuZonedDateTimeFormat.mdet({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.mdet',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterMdet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Year + Month + Day + weekDay + Time (e.g. "Mon, Jan 15, 2024, 14:30").
  factory IcuZonedDateTimeFormat.ymdet({
    required String locale,
    IcuZoneStyle zoneStyle = IcuZoneStyle.specificShort,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) => _build(
    locale: locale,
    zoneStyle: zoneStyle,
    marker: 'ZonedDateTimeFormatter.ymdet',
    innerBuilder: (l, loc) => dispatch.dateTimeFormatterYmdet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
      yearStyle: toFfiYearStyle(yearStyle),
    ),
  );
  final icu.ZonedDateTimeFormatter _ffi;

  // .et (weekDay + Time) is intentionally NOT exposed: ICU4X 2.2's CLDR
  // data has no preset pattern that combines weekDay + Time + zone for any
  // locale we tested. The Rust API rejects every (.et, zoneStyle) pair
  // with `DateTimeFormatterLoadError::ConflictingField`. Use [IcuDateTimeFormat.et]
  // for an unzoned weekDay+Time, or .det / .mdet / .ymdet to add a zone
  // alongside the weekday.

  /// Format [dt] for [ianaTimeZoneId] (e.g. "America/Los_Angeles", "Asia/Tokyo").
  ///
  /// The UTC offset is taken from [dt]'s `timeZoneOffset` if [dt] is a
  /// time-zone-aware Dart `DateTime`, OR an explicit [utcOffsetSeconds]
  /// can be passed (positive = east of UTC). Pacific Daylight Time would
  /// be `-7 * 3600 = -25200`.
  String format(
    DateTime dt, {
    required String ianaTimeZoneId,
    int? utcOffsetSeconds,
  }) {
    final tz = icu.TimeZone.fromIanaId(ianaTimeZoneId);
    final offset = utcOffsetSeconds ?? dt.timeZoneOffset.inSeconds;
    final tzInfo = tz.withOffset(icu.UtcOffset.fromSeconds(offset));
    return _ffi.formatIso(isoDateFromDart(dt), timeFromDart(dt), tzInfo);
  }
}

IcuZonedDateTimeFormat _build({
  required String locale,
  required IcuZoneStyle zoneStyle,
  required String marker,
  required icu.DateTimeFormatter Function(String localeStr, icu.Locale)
  innerBuilder,
}) {
  final loc = IcuLocale.parse(locale);
  try {
    final inner = innerBuilder(locale, loc.ffi);
    return IcuZonedDateTimeFormat._(
      _buildZoned(locale, loc.ffi, zoneStyle, inner),
    );
  } catch (e) {
    throw IcuDataError(
      'Zoned date-time formatter unavailable for $locale: $e',
      locale: locale,
      marker: marker,
    );
  }
}

icu.ZonedDateTimeFormatter _buildZoned(
  String localeStr,
  icu.Locale loc,
  IcuZoneStyle style,
  icu.DateTimeFormatter inner,
) => switch (style) {
  IcuZoneStyle.specificLong => dispatch.zonedDateTimeFormatterSpecificLong(
    localeStr,
    loc,
    inner,
  ),
  IcuZoneStyle.specificShort => dispatch.zonedDateTimeFormatterSpecificShort(
    localeStr,
    loc,
    inner,
  ),
  IcuZoneStyle.localizedOffsetLong =>
    dispatch.zonedDateTimeFormatterLocalizedOffsetLong(localeStr, loc, inner),
  IcuZoneStyle.localizedOffsetShort =>
    dispatch.zonedDateTimeFormatterLocalizedOffsetShort(localeStr, loc, inner),
  IcuZoneStyle.genericLong => dispatch.zonedDateTimeFormatterGenericLong(
    localeStr,
    loc,
    inner,
  ),
  IcuZoneStyle.genericShort => dispatch.zonedDateTimeFormatterGenericShort(
    localeStr,
    loc,
    inner,
  ),
  IcuZoneStyle.location => dispatch.zonedDateTimeFormatterLocation(
    localeStr,
    loc,
    inner,
  ),
  IcuZoneStyle.exemplarCity => dispatch.zonedDateTimeFormatterExemplarCity(
    localeStr,
    loc,
    inner,
  ),
};
