// Mirror of the native `UnitsFormatter` binding plus the `UnitsWidth`
// enum, over the Diplomat JS `UnitsFormatter` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'number_format.dart' show Decimal;

/// Web mirror of the FFI `UnitsFormatter`.
extension type UnitsFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory UnitsFormatter.fromDispatch(JSObject o) = UnitsFormatter._;

  /// Format [value] with this formatter's unit (e.g. "5 hours" in
  /// en-US).
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;
}

/// Web mirror of the FFI `UnitsWidth` enum.
enum UnitsWidth {
  /// Long form (e.g. "5 hours" in en-US).
  long,

  /// Short form (e.g. "5 hr" in en-US).
  short,

  /// Narrowest form (e.g. "5h" in en-US).
  narrow;

  /// The JS enum value for this width.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('UnitsWidth'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      UnitsWidth.long => 'Long'.toJS,
      UnitsWidth.short => 'Short'.toJS,
      UnitsWidth.narrow => 'Narrow'.toJS,
    });
  }
}
