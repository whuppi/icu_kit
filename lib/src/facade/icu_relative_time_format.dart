import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';
import 'icu_number_format.dart' show toDecimalFfi;

/// Locale-aware relative-time formatting — STABLE.
///
/// Equivalent to ECMA-402's `Intl.RelativeTimeFormat`. Pinned to one
/// `(width, unit)` combo at construction; pass a signed numeric value at
/// format time (negative = past, positive = future).
final class IcuRelativeTimeFormat {
  IcuRelativeTimeFormat._(this._ffi);

  /// Construct a relative-time formatter pinned to one [unit] and [width].
  ///
  /// [numeric] controls whether special CLDR forms (`tomorrow`, `今日`,
  /// `dernier mois`) are used when available (Auto), or only numeric
  /// renderings (Always — the default).
  factory IcuRelativeTimeFormat({
    required String locale,
    required IcuRelativeTimeUnit unit,
    IcuRelativeTimeWidth width = IcuRelativeTimeWidth.long,
    IcuRelativeTimeNumeric numeric = IcuRelativeTimeNumeric.always,
  }) {
    final loc = IcuLocale.parse(locale);
    final ffiNumeric = _toFfiNumeric(numeric);
    try {
      final ffi = _build(locale, loc.ffi, width, unit, ffiNumeric);
      return IcuRelativeTimeFormat._(ffi);
    } catch (e) {
      throw IcuDataError(
        'Relative-time formatter unavailable for $locale ($width, $unit): $e',
        locale: locale,
        marker: 'RelativeTimeFormatter.${width.name}.${unit.name}',
      );
    }
  }
  final icu.RelativeTimeFormatterFfi _ffi;

  /// Format [value]. Negative = past ("X ago"), positive = future ("in X").
  ///
  /// Examples (en, day, Auto):
  ///   * `format(0)`  → "today"
  ///   * `format(1)`  → "tomorrow"
  ///   * `format(-1)` → "yesterday"
  ///   * `format(2)`  → "in 2 days"
  ///   * `format(-3)` → "3 days ago"
  String format(num value) {
    final decimal = toDecimalFfi(value);
    return _ffi.format(decimal);
  }
}

icu.RelativeTimeFormatterFfi _build(
  String localeStr,
  icu.Locale loc,
  IcuRelativeTimeWidth width,
  IcuRelativeTimeUnit unit,
  icu.RelativeTimeNumeric? numeric,
) => switch ((width, unit)) {
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.second) =>
    dispatch.relativeTimeFormatterFfiLongSecond(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.minute) =>
    dispatch.relativeTimeFormatterFfiLongMinute(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.hour) =>
    dispatch.relativeTimeFormatterFfiLongHour(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.day) =>
    dispatch.relativeTimeFormatterFfiLongDay(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.week) =>
    dispatch.relativeTimeFormatterFfiLongWeek(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.month) =>
    dispatch.relativeTimeFormatterFfiLongMonth(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.quarter) =>
    dispatch.relativeTimeFormatterFfiLongQuarter(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.long, IcuRelativeTimeUnit.year) =>
    dispatch.relativeTimeFormatterFfiLongYear(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.second) =>
    dispatch.relativeTimeFormatterFfiShortSecond(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.minute) =>
    dispatch.relativeTimeFormatterFfiShortMinute(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.hour) =>
    dispatch.relativeTimeFormatterFfiShortHour(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.day) =>
    dispatch.relativeTimeFormatterFfiShortDay(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.week) =>
    dispatch.relativeTimeFormatterFfiShortWeek(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.month) =>
    dispatch.relativeTimeFormatterFfiShortMonth(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.quarter) =>
    dispatch.relativeTimeFormatterFfiShortQuarter(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.short, IcuRelativeTimeUnit.year) =>
    dispatch.relativeTimeFormatterFfiShortYear(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.second) =>
    dispatch.relativeTimeFormatterFfiNarrowSecond(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.minute) =>
    dispatch.relativeTimeFormatterFfiNarrowMinute(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.hour) =>
    dispatch.relativeTimeFormatterFfiNarrowHour(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.day) =>
    dispatch.relativeTimeFormatterFfiNarrowDay(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.week) =>
    dispatch.relativeTimeFormatterFfiNarrowWeek(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.month) =>
    dispatch.relativeTimeFormatterFfiNarrowMonth(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.quarter) =>
    dispatch.relativeTimeFormatterFfiNarrowQuarter(localeStr, loc, numeric),
  (IcuRelativeTimeWidth.narrow, IcuRelativeTimeUnit.year) =>
    dispatch.relativeTimeFormatterFfiNarrowYear(localeStr, loc, numeric),
};

icu.RelativeTimeNumeric _toFfiNumeric(IcuRelativeTimeNumeric n) => switch (n) {
  IcuRelativeTimeNumeric.always => icu.RelativeTimeNumeric.always,
  IcuRelativeTimeNumeric.auto => icu.RelativeTimeNumeric.auto,
};

/// Width preset for relative-time output.
///
/// Maps to ECMA-402's `Intl.RelativeTimeFormat` `style`:
///   * `long` — full word ("3 hours ago", "in 5 days")
///   * `short` — abbreviated ("3 hr ago", "in 5 days")
///   * `narrow` — most compact ("3h ago", "in 5d")
enum IcuRelativeTimeWidth {
  /// Full word (e.g. "3 hours ago" in en-US).
  long,

  /// Abbreviated (e.g. "3 hr. ago" in en-US).
  short,

  /// Most compact (e.g. "3h ago" in en-US).
  narrow,
}

/// The unit of time being formatted.
///
/// Maps to ECMA-402's `Intl.RelativeTimeFormat` `unit`. ICU4X 2.2 supports
/// these eight units; smaller units like `nanosecond` / `millisecond` are
/// not in CLDR's relative-time data.
enum IcuRelativeTimeUnit {
  /// Seconds.
  second,

  /// Minutes.
  minute,

  /// Hours.
  hour,

  /// Days.
  day,

  /// Weeks.
  week,

  /// Months.
  month,

  /// Quarters.
  quarter,

  /// Years.
  year,
}

/// Whether to always emit numeric forms or fall back to special CLDR
/// renderings when available (e.g. "yesterday" instead of "1 day ago").
///
/// Mirrors ECMA-402's `numeric: 'always' | 'auto'` and ICU4X's `Numeric`.
enum IcuRelativeTimeNumeric {
  /// Always numeric (e.g. "1 day ago").
  always,

  /// Use special renderings when CLDR has them (e.g. "yesterday").
  auto,
}
