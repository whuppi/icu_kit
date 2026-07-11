import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_datetime_shared.dart';
import 'icu_locale.dart';

export 'icu_datetime_shared.dart'
    show IcuDateAlignment, IcuDateLength, IcuTimePrecision, IcuYearStyle;

/// Locale-aware combined date + time formatting — STABLE.
///
/// Equivalent to ECMA-402's `Intl.DateTimeFormat({ dateStyle, timeStyle })`.
/// Maps Dart's `DateTime` (always proleptic Gregorian) to ICU4X's `IsoDate`
/// + `Time` pair, then renders via the locale's calendar and hour cycle.
///
/// Seven field-set constructors mirror ICU4X 2.2:
///
///   * `.dt()`   — day + time
///   * `.mdt()`  — month + day + time
///   * `.ymdt()` — year + month + day + time (most common)
///   * `.det()`  — day + weekday + time
///   * `.mdet()` — month + day + weekday + time
///   * `.ymdet()` — year + month + day + weekday + time
///   * `.et()`   — weekday + time
final class IcuDateTimeFormat {
  IcuDateTimeFormat._(this._ffi);

  /// Day + time. Use when context fixes the month/year (e.g. inside a list
  /// of "appointments today").
  factory IcuDateTimeFormat.dt({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.dt',
    build: (l, loc) => dispatch.dateTimeFormatterDt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Month + day + time.
  factory IcuDateTimeFormat.mdt({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.mdt',
    build: (l, loc) => dispatch.dateTimeFormatterMdt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Year + month + day + time. The ECMA-402 dateStyle+timeStyle workhorse.
  ///
  /// Example: `IcuDateTimeFormat.ymdt(locale: 'en-US', length: short)`
  /// → "4/28/26, 2:32 PM"
  factory IcuDateTimeFormat.ymdt({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.ymdt',
    build: (l, loc) => dispatch.dateTimeFormatterYmdt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
      yearStyle: toFfiYearStyle(yearStyle),
    ),
  );

  /// Day + weekday + time.
  factory IcuDateTimeFormat.det({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.det',
    build: (l, loc) => dispatch.dateTimeFormatterDet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Month + day + weekday + time.
  factory IcuDateTimeFormat.mdet({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.mdet',
    build: (l, loc) => dispatch.dateTimeFormatterMdet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );

  /// Year + month + day + weekday + time.
  factory IcuDateTimeFormat.ymdet({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.ymdet',
    build: (l, loc) => dispatch.dateTimeFormatterYmdet(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
      yearStyle: toFfiYearStyle(yearStyle),
    ),
  );

  /// Weekday + time.
  factory IcuDateTimeFormat.et({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuTimePrecision? precision,
    IcuDateAlignment? alignment,
  }) => _build(
    locale: locale,
    marker: 'DateTimeFormatter.et',
    build: (l, loc) => dispatch.dateTimeFormatterEt(
      l,
      loc,
      length: toFfiLength(length),
      timePrecision: toFfiPrecision(precision),
      alignment: toFfiAlignment(alignment),
    ),
  );
  final icu.DateTimeFormatter _ffi;

  /// Format a Dart [DateTime] (date + wall-clock time portions).
  ///
  /// Time-zone of the input is ignored — the wall-clock fields are taken
  /// as-is. Use `IcuZonedDateTimeFormat` when time-zone-aware formatting
  /// is needed.
  String format(DateTime dt) {
    return _ffi.formatIso(isoDateFromDart(dt), timeFromDart(dt));
  }

  // ---- internal helpers -------------------------------------------------

  static IcuDateTimeFormat _build({
    required String locale,
    required String marker,
    required icu.DateTimeFormatter Function(String localeStr, icu.Locale loc)
    build,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      return IcuDateTimeFormat._(build(locale, loc.ffi));
    } catch (e) {
      throw IcuDataError(
        'DateTime formatter unavailable for $locale: $e',
        locale: locale,
        marker: marker,
      );
    }
  }
}
