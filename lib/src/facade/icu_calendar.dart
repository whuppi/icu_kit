import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// A calendar system — STABLE.
///
/// Wraps ICU4X's `Calendar` opaque type. Construct by [IcuCalendarKind]
/// and use it to convert ISO/Gregorian dates to calendar-specific dates.
///
/// Example:
///
/// ```dart
/// final japanese = IcuCalendar(IcuCalendarKind.japanese);
/// final date = IcuCalendarDate.fromGregorian(
///   year: 2026, month: 4, day: 28,
///   calendar: japanese,
/// );
/// print(date.era);              // "reiwa"
/// print(date.eraYearOrRelatedIso);  // 8 (Reiwa year 8)
/// print(date.monthCode);        // "M04"
/// print(date.dayOfMonth);       // 28
/// ```
final class IcuCalendar {
  IcuCalendar._(this._ffi, this.kind);

  /// Create the calendar system identified by [kind].
  ///
  /// Throws [IcuDataError] when the calendar data is unavailable.
  factory IcuCalendar(IcuCalendarKind kind) {
    try {
      return IcuCalendar._(dispatch.calendarDefault(_toFfi(kind)), kind);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Calendar unavailable for ${kind.name}: $e',
        marker: 'Calendar.${kind.name}',
      );
    }
  }
  final icu.Calendar _ffi;

  /// Which calendar this is.
  final IcuCalendarKind kind;
}

/// One date in a specific calendar system.
final class IcuCalendarDate {
  IcuCalendarDate._(this._ffi);

  /// Build a date from Gregorian (proleptic ISO) [year]/[month]/[day]
  /// converted into [calendar]'s system.
  factory IcuCalendarDate.fromGregorian({
    required int year,
    required int month,
    required int day,
    required IcuCalendar calendar,
  }) {
    try {
      return IcuCalendarDate._(
        icu.Date.fromIsoInCalendar(year, month, day, calendar._ffi),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Invalid date $year-$month-$day for ${calendar.kind.name}: $e',
        marker: 'Date.fromIsoInCalendar',
      );
    }
  }

  /// Build a date from a Dart [DateTime] (its date portion only) converted
  /// into [calendar]'s system.
  factory IcuCalendarDate.fromDartDateTime(
    DateTime dt, {
    required IcuCalendar calendar,
  }) => IcuCalendarDate.fromGregorian(
    year: dt.year,
    month: dt.month,
    day: dt.day,
    calendar: calendar,
  );
  final icu.Date _ffi;

  /// Convert this date back to the proleptic Gregorian (ISO) calendar.
  ///
  /// Returns `(year, month, day)` in the Gregorian system.
  ({int year, int month, int day}) toGregorian() {
    final iso = _ffi.toIso();
    return (year: iso.year, month: iso.month, day: iso.dayOfMonth);
  }

  /// Era code (e.g. `"reiwa"` for Japanese, `"ce"` for Gregorian, `"ah"`
  /// for Hijri). May be empty for calendars without eras.
  String get era => _ffi.era;

  /// The year IN ITS ERA, or — for calendars without eras — the related
  /// ISO year. For Japanese, year 8 of Reiwa is era="reiwa", value=8.
  int get eraYearOrRelatedIso => _ffi.eraYearOrRelatedIso;

  /// The calendar's full year offset from a single epoch (e.g. 5784 for
  /// Hebrew, 4722 for Chinese cyclic year).
  int get extendedYear => _ffi.extendedYear;

  /// Locale-independent month code (e.g. `"M04"` for the 4th month;
  /// `"M07L"` for the leap 7th month in Hebrew).
  String get monthCode => _ffi.monthCode;

  /// 1-based ordinal month number within the year.
  int get monthNumber => _ffi.monthNumber;

  /// True if this month is a leap month (e.g. an extra month in lunisolar
  /// calendars).
  bool get monthIsLeap => _ffi.monthIsLeap;

  /// Day of month (1-based).
  int get dayOfMonth => _ffi.dayOfMonth;

  /// Day of year (1-based).
  int get dayOfYear => _ffi.dayOfYear;

  /// Weekday (1-based; Monday=1 ... Sunday=7 per ISO 8601).
  IcuWeekday get weekday => switch (_ffi.weekday) {
    icu.Weekday.monday => IcuWeekday.monday,
    icu.Weekday.tuesday => IcuWeekday.tuesday,
    icu.Weekday.wednesday => IcuWeekday.wednesday,
    icu.Weekday.thursday => IcuWeekday.thursday,
    icu.Weekday.friday => IcuWeekday.friday,
    icu.Weekday.saturday => IcuWeekday.saturday,
    icu.Weekday.sunday => IcuWeekday.sunday,
  };

  /// Total months in this year (e.g. 13 in a leap year of a lunisolar
  /// calendar).
  int get monthsInYear => _ffi.monthsInYear;

  /// Total days in this month.
  int get daysInMonth => _ffi.daysInMonth;

  /// Total days in this year.
  int get daysInYear => _ffi.daysInYear;

  /// True if this date falls in a leap year.
  bool get isInLeapYear => _ffi.isInLeapYear;

  /// Rata Die day count.
  int get rataDie => _ffi.rataDie;
}

icu.CalendarKind _toFfi(IcuCalendarKind k) => switch (k) {
  IcuCalendarKind.iso => icu.CalendarKind.iso,
  IcuCalendarKind.gregorian => icu.CalendarKind.gregorian,
  IcuCalendarKind.buddhist => icu.CalendarKind.buddhist,
  IcuCalendarKind.japanese => icu.CalendarKind.japanese,
  IcuCalendarKind.ethiopian => icu.CalendarKind.ethiopian,
  IcuCalendarKind.ethiopianAmeteAlem => icu.CalendarKind.ethiopianAmeteAlem,
  IcuCalendarKind.indian => icu.CalendarKind.indian,
  IcuCalendarKind.coptic => icu.CalendarKind.coptic,
  IcuCalendarKind.dangi => icu.CalendarKind.dangi,
  IcuCalendarKind.chinese => icu.CalendarKind.chinese,
  IcuCalendarKind.hebrew => icu.CalendarKind.hebrew,
  IcuCalendarKind.hijriTabularTypeIiFriday =>
    icu.CalendarKind.hijriTabularTypeIiFriday,
  IcuCalendarKind.hijriSimulatedMecca => icu.CalendarKind.hijriSimulatedMecca,
  IcuCalendarKind.hijriTabularTypeIiThursday =>
    icu.CalendarKind.hijriTabularTypeIiThursday,
  IcuCalendarKind.hijriUmmAlQura => icu.CalendarKind.hijriUmmAlQura,
  IcuCalendarKind.persian => icu.CalendarKind.persian,
  IcuCalendarKind.roc => icu.CalendarKind.roc,
};

/// Calendar systems supported by ICU4X 2.2.
///
/// `japaneseExtended` is intentionally absent — upstream marked it
/// deprecated in favor of `japanese` (identical in 2.2).
enum IcuCalendarKind {
  /// ISO 8601 (proleptic Gregorian with ISO week rules).
  iso,

  /// Gregorian.
  gregorian,

  /// Thai Buddhist (Gregorian + 543 years).
  buddhist,

  /// Japanese (Gregorian with imperial eras).
  japanese,

  /// Ethiopian (Amete Mihret epoch).
  ethiopian,

  /// Ethiopian with the Amete Alem epoch.
  ethiopianAmeteAlem,

  /// Indian national (Saka).
  indian,

  /// Coptic.
  coptic,

  /// Korean lunisolar (Dangi).
  dangi,

  /// Chinese lunisolar.
  chinese,

  /// Hebrew lunisolar.
  hebrew,

  /// Tabular Hijri, type II leap years, Friday epoch.
  hijriTabularTypeIiFriday,

  /// Hijri simulated for Mecca.
  hijriSimulatedMecca,

  /// Tabular Hijri, type II leap years, Thursday epoch.
  hijriTabularTypeIiThursday,

  /// Hijri per Saudi Arabia's Umm al-Qura calendar.
  hijriUmmAlQura,

  /// Persian (Solar Hijri).
  persian,

  /// Republic of China (Minguo).
  roc,
}

/// Day of week (1-based per ISO 8601).
enum IcuWeekday {
  /// Monday.
  monday,

  /// Tuesday.
  tuesday,

  /// Wednesday.
  wednesday,

  /// Thursday.
  thursday,

  /// Friday.
  friday,

  /// Saturday.
  saturday,

  /// Sunday.
  sunday,
}
