// Mirror of the native `PercentFormatter` binding plus the `PercentDisplay`
// enum, over the Diplomat JS `PercentFormatter` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'number_format.dart' show Decimal, FormattedNumberParts;

/// Web mirror of the FFI `PercentFormatter`.
extension type PercentFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory PercentFormatter.fromDispatch(JSObject o) = PercentFormatter._;

  /// Format [value] as a percentage (e.g. "42%" in en-US).
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;

  /// Format [value] into typed parts.
  FormattedNumberParts formatToParts(Decimal value) =>
      FormattedNumberParts.fromDispatch(
        _self.callMethod<JSObject>('formatToParts'.toJS, value),
      );
}

/// Web mirror of the FFI `PercentDisplay` enum.
enum PercentDisplay {
  /// Plain percent (e.g. "42%").
  standard,

  /// Approximate marker (e.g. "~42%").
  approximate,

  /// Always show the sign (e.g. "+42%").
  explicitSign;

  /// The JS enum value for this display mode.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('PercentDisplay'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      PercentDisplay.standard => 'Standard'.toJS,
      PercentDisplay.approximate => 'Approximate'.toJS,
      PercentDisplay.explicitSign => 'ExplicitSign'.toJS,
    });
  }
}
