import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `IsoDate`.
extension type IsoDate._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory IsoDate.fromDispatch(JSObject o) = IsoDate._;

  /// Create an ISO-8601 calendar date.
  factory IsoDate(int year, int month, int day) {
    final cls = IcuKit.module.getProperty<JSFunction>('IsoDate'.toJS);
    return IsoDate._(
      cls.callAsConstructor<JSObject>(year.toJS, month.toJS, day.toJS),
    );
  }

  /// ISO year.
  int get year => _self.getProperty<JSNumber>('year'.toJS).toDartInt;

  /// ISO month, 1-based.
  int get month => _self.getProperty<JSNumber>('month'.toJS).toDartInt;

  /// Day of the month, 1-based.
  int get dayOfMonth =>
      _self.getProperty<JSNumber>('dayOfMonth'.toJS).toDartInt;
}

/// Web mirror of the FFI `DateFormatter`.
extension type DateFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory DateFormatter.fromDispatch(JSObject o) = DateFormatter._;

  /// Format an [IsoDate] handle as locale-appropriate text.
  String formatIso(JSObject isoDate) =>
      _self.callMethod<JSString>('formatIso'.toJS, isoDate).toDart;
}

/// Web mirror of the FFI `TimeFormatter`.
extension type TimeFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory TimeFormatter.fromDispatch(JSObject o) = TimeFormatter._;

  /// Format a [Time] handle as locale-appropriate text.
  String format(JSObject time) =>
      _self.callMethod<JSString>('format'.toJS, time).toDart;
}

/// Web mirror of the FFI `DateTimeFormatter`.
extension type DateTimeFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory DateTimeFormatter.fromDispatch(JSObject o) = DateTimeFormatter._;

  /// Format an [IsoDate] plus [Time] handle pair as locale-appropriate
  /// text.
  String formatIso(JSObject isoDate, JSObject time) =>
      _self.callMethod<JSString>('formatIso'.toJS, isoDate, time).toDart;
}

/// Web mirror of the FFI `Time`.
extension type Time._(JSObject _self) implements JSObject {
  /// Create a time of day; [subsecond] is in nanoseconds.
  factory Time(int hour, int minute, int second, int subsecond) {
    final cls = IcuKit.module.getProperty<JSFunction>('Time'.toJS);
    return Time._(
      cls.callAsConstructor<JSObject>(
        hour.toJS,
        minute.toJS,
        second.toJS,
        subsecond.toJS,
      ),
    );
  }
}

/// Web mirror of the FFI `DateTimeLength` enum.
enum DateTimeLength {
  /// Long form (e.g. "January 15, 2024" in en-US).
  long,

  /// Medium form (e.g. "Jan 15, 2024" in en-US).
  medium,

  /// Short form (e.g. "1/15/24" in en-US).
  short;

  /// Convert to the JS enum object dispatch expects.
  JSObject toJs() => _jsEnum('DateTimeLength', switch (this) {
    DateTimeLength.long => 'Long',
    DateTimeLength.medium => 'Medium',
    DateTimeLength.short => 'Short',
  });
}

/// Web mirror of the FFI `DateTimeAlignment` enum.
enum DateTimeAlignment {
  /// Natural widths for running text.
  auto,

  /// Padded widths so values line up in columns.
  column;

  /// Convert to the JS enum object dispatch expects.
  JSObject toJs() => _jsEnum('DateTimeAlignment', switch (this) {
    DateTimeAlignment.auto => 'Auto',
    DateTimeAlignment.column => 'Column',
  });
}

/// Web mirror of the FFI `YearStyle` enum.
enum YearStyle {
  /// Era and century shown only when needed to disambiguate.
  auto,

  /// Full year, era only when needed (e.g. "2024").
  full,

  /// Always include the era (e.g. "2024 AD").
  withEra,

  /// Never include the era.
  noEra;

  /// Convert to the JS enum object dispatch expects.
  JSObject toJs() => _jsEnum('YearStyle', switch (this) {
    YearStyle.auto => 'Auto',
    YearStyle.full => 'Full',
    YearStyle.withEra => 'WithEra',
    YearStyle.noEra => 'NoEra',
  });
}

/// Web mirror of the FFI `TimePrecision` enum.
enum TimePrecision {
  /// Hour only (e.g. "3 PM").
  hour,

  /// Hour and minute (e.g. "3:05 PM").
  minute,

  /// Minute shown only when nonzero.
  minuteOptional,

  /// Hour, minute, and second (e.g. "3:05:07 PM").
  second,

  /// Seconds with 1 fractional digit.
  subsecond1,

  /// Seconds with 2 fractional digits.
  subsecond2,

  /// Seconds with 3 fractional digits.
  subsecond3,

  /// Seconds with 4 fractional digits.
  subsecond4,

  /// Seconds with 5 fractional digits.
  subsecond5,

  /// Seconds with 6 fractional digits.
  subsecond6,

  /// Seconds with 7 fractional digits.
  subsecond7,

  /// Seconds with 8 fractional digits.
  subsecond8,

  /// Seconds with 9 fractional digits.
  subsecond9;

  /// Convert to the JS enum object dispatch expects.
  JSObject toJs() => _jsEnum('TimePrecision', switch (this) {
    TimePrecision.hour => 'Hour',
    TimePrecision.minute => 'Minute',
    TimePrecision.minuteOptional => 'MinuteOptional',
    TimePrecision.second => 'Second',
    TimePrecision.subsecond1 => 'Subsecond1',
    TimePrecision.subsecond2 => 'Subsecond2',
    TimePrecision.subsecond3 => 'Subsecond3',
    TimePrecision.subsecond4 => 'Subsecond4',
    TimePrecision.subsecond5 => 'Subsecond5',
    TimePrecision.subsecond6 => 'Subsecond6',
    TimePrecision.subsecond7 => 'Subsecond7',
    TimePrecision.subsecond8 => 'Subsecond8',
    TimePrecision.subsecond9 => 'Subsecond9',
  });
}

JSObject _jsEnum(String cls, String name) => IcuKit.module
    .getProperty<JSObject>(cls.toJS)
    .getProperty<JSObject>(name.toJS);
