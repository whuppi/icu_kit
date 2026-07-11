// Mirror of the native `RelativeTimeFormatterFfi` binding plus the
// `RelativeTimeNumeric` enum, over the Diplomat JS
// `RelativeTimeFormatterFfi` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'number_format.dart' show Decimal;

/// Web mirror of the FFI `RelativeTimeFormatterFfi`.
extension type RelativeTimeFormatterFfi._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory RelativeTimeFormatterFfi.fromDispatch(JSObject o) =
      RelativeTimeFormatterFfi._;

  /// Format [value] with this formatter's unit (e.g. "3 hours ago"
  /// in en-US); negative means past, positive means future.
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;
}

/// Web mirror of the FFI `RelativeTimeNumeric` enum.
enum RelativeTimeNumeric {
  /// Always numeric (e.g. "1 day ago").
  always,

  /// Use special renderings when CLDR has them (e.g. "yesterday").
  auto;

  /// The JS enum value for this mode.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('RelativeTimeNumeric'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      RelativeTimeNumeric.always => 'Always'.toJS,
      RelativeTimeNumeric.auto => 'Auto'.toJS,
    });
  }
}
