import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'datetime.dart' show IsoDate;
import 'js_bool.dart';

/// Calendar systems — same variant names as the FFI `CalendarKind` (the
/// 17 facade-constructable kinds). `toJs()` builds the JS enum value.
enum CalendarKind {
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
  roc;

  /// The JS `CalendarKind` enum value for this kind.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('CalendarKind'.toJS);
    return cls.getProperty<JSObject>(
      switch (this) {
        iso => 'Iso',
        gregorian => 'Gregorian',
        buddhist => 'Buddhist',
        japanese => 'Japanese',
        ethiopian => 'Ethiopian',
        ethiopianAmeteAlem => 'EthiopianAmeteAlem',
        indian => 'Indian',
        coptic => 'Coptic',
        dangi => 'Dangi',
        chinese => 'Chinese',
        hebrew => 'Hebrew',
        hijriTabularTypeIiFriday => 'HijriTabularTypeIiFriday',
        hijriSimulatedMecca => 'HijriSimulatedMecca',
        hijriTabularTypeIiThursday => 'HijriTabularTypeIiThursday',
        hijriUmmAlQura => 'HijriUmmAlQura',
        persian => 'Persian',
        roc => 'Roc',
      }.toJS,
    );
  }
}

/// Day of week — same variant names as the FFI `Weekday`.
enum Weekday {
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
  sunday;

  static Weekday _fromJs(JSObject js) {
    final v = js.getProperty<JSString>('value'.toJS).toDart;
    return switch (v) {
      'Monday' => monday,
      'Tuesday' => tuesday,
      'Wednesday' => wednesday,
      'Thursday' => thursday,
      'Friday' => friday,
      'Saturday' => saturday,
      'Sunday' => sunday,
      _ => throw StateError('Unknown Weekday value: $v'),
    };
  }
}

/// Web mirror of the FFI `Calendar`.
extension type Calendar._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory Calendar.fromDispatch(JSObject o) = Calendar._;
}

/// Web mirror of the FFI `Date` (calendar-specific date).
extension type Date._(JSObject _self) implements JSObject {
  /// Native `Date.fromIsoInCalendar(y,m,d, Calendar)`; JS dispatches the
  /// same name via varargs.
  factory Date.fromIsoInCalendar(int year, int month, int day, Calendar cal) {
    final cls = IcuKit.module.getProperty<JSObject>('Date'.toJS);
    return Date._(
      cls.callMethodVarArgs<JSObject>('fromIsoInCalendar'.toJS, [
        year.toJS,
        month.toJS,
        day.toJS,
        cal,
      ]),
    );
  }

  /// Convert back to the ISO calendar.
  IsoDate toIso() =>
      IsoDate.fromDispatch(_self.callMethod<JSObject>('toIso'.toJS));

  /// Era code (e.g. `"reiwa"`, `"ce"`). May be empty for era-less calendars.
  String get era => _self.getProperty<JSString>('era'.toJS).toDart;

  /// Year in its era, or the related ISO year for era-less calendars.
  int get eraYearOrRelatedIso =>
      _self.getProperty<JSNumber>('eraYearOrRelatedIso'.toJS).toDartInt;

  /// Full year offset from a single epoch.
  int get extendedYear =>
      _self.getProperty<JSNumber>('extendedYear'.toJS).toDartInt;

  /// Locale-independent month code (e.g. `"M04"`; `"M07L"` for leap months).
  String get monthCode => _self.getProperty<JSString>('monthCode'.toJS).toDart;

  /// 1-based ordinal month number within the year.
  int get monthNumber =>
      _self.getProperty<JSNumber>('monthNumber'.toJS).toDartInt;

  /// True if this month is a leap month.
  bool get monthIsLeap =>
      readJsBool(_self.getProperty<JSAny?>('monthIsLeap'.toJS));

  /// Day of month (1-based).
  int get dayOfMonth =>
      _self.getProperty<JSNumber>('dayOfMonth'.toJS).toDartInt;

  /// Day of year (1-based).
  int get dayOfYear => _self.getProperty<JSNumber>('dayOfYear'.toJS).toDartInt;

  /// Day of week.
  Weekday get weekday =>
      Weekday._fromJs(_self.getProperty<JSObject>('weekday'.toJS));

  /// Total months in this year.
  int get monthsInYear =>
      _self.getProperty<JSNumber>('monthsInYear'.toJS).toDartInt;

  /// Total days in this month.
  int get daysInMonth =>
      _self.getProperty<JSNumber>('daysInMonth'.toJS).toDartInt;

  /// Total days in this year.
  int get daysInYear =>
      _self.getProperty<JSNumber>('daysInYear'.toJS).toDartInt;

  /// True if this date falls in a leap year.
  bool get isInLeapYear =>
      readJsBool(_self.getProperty<JSAny?>('isInLeapYear'.toJS));

  /// Rata Die day count.
  int get rataDie => _self.getProperty<JSNumber>('rataDie'.toJS).toDartInt;
}
