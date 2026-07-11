import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'datetime.dart' show IsoDate, Time;

/// Web mirror of the FFI `UtcOffset`.
extension type UtcOffset._(JSObject _self) implements JSObject {
  /// Create a UTC offset of [seconds] east of UTC (negative = west).
  factory UtcOffset.fromSeconds(int seconds) {
    final cls = IcuKit.module.getProperty<JSObject>('UtcOffset'.toJS);
    return UtcOffset._(
      cls.callMethod<JSObject>('fromSeconds'.toJS, seconds.toJS),
    );
  }
}

/// Web mirror of the FFI `TimeZoneInfo` (result of `TimeZone.withOffset`).
extension type TimeZoneInfo._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory TimeZoneInfo.fromDispatch(JSObject o) = TimeZoneInfo._;

  /// This zone info pinned to a local datetime, enabling zone-variant
  /// (standard vs daylight) resolution.
  TimeZoneInfo atDateTimeIso(IsoDate iso, Time time) => TimeZoneInfo._(
    _self.callMethodVarArgs<JSObject>('atDateTimeIso'.toJS, [iso, time]),
  );
}

/// Web mirror of the FFI `TimeZone`.
extension type TimeZone._(JSObject _self) implements JSObject {
  /// Look up a time zone by IANA ID (e.g. "America/New_York");
  /// unknown IDs yield the unknown zone.
  factory TimeZone.fromIanaId(String ianaId) {
    final cls = IcuKit.module.getProperty<JSObject>('TimeZone'.toJS);
    return TimeZone._(
      cls.callMethod<JSObject>('createFromIanaId'.toJS, ianaId.toJS),
    );
  }

  /// This zone combined with a known UTC [offset].
  TimeZoneInfo withOffset(UtcOffset offset) => TimeZoneInfo.fromDispatch(
    _self.callMethod<JSObject>('withOffset'.toJS, offset),
  );
}

/// Web mirror of the FFI `TimeZoneFormatter`.
extension type TimeZoneFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory TimeZoneFormatter.fromDispatch(JSObject o) = TimeZoneFormatter._;

  /// Format [zone] as locale-appropriate text.
  String format(TimeZoneInfo zone) =>
      _self.callMethod<JSString>('format'.toJS, zone).toDart;
}

/// Web mirror of the FFI `ZonedDateTimeFormatter`.
extension type ZonedDateTimeFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory ZonedDateTimeFormatter.fromDispatch(JSObject o) =
      ZonedDateTimeFormatter._;

  /// Format an [IsoDate] plus [Time] handle pair in [zone] as
  /// locale-appropriate text.
  String formatIso(JSObject isoDate, JSObject time, TimeZoneInfo zone) => _self
      .callMethodVarArgs<JSString>('formatIso'.toJS, [isoDate, time, zone])
      .toDart;
}
