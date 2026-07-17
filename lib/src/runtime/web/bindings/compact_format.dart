// Mirror of the native `CompactDecimalFormatter` binding, over the
// Diplomat JS `CompactDecimalFormatter` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'number_format.dart' show Decimal, FormattedNumberParts;

/// Web mirror of the FFI `CompactDecimalFormatter`.
extension type CompactDecimalFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CompactDecimalFormatter.fromDispatch(JSObject o) =
      CompactDecimalFormatter._;

  /// Format [value] in compact notation (e.g. "1.2M" / "1.2 million").
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;

  /// Format [value] into typed parts.
  FormattedNumberParts formatToParts(Decimal value) =>
      FormattedNumberParts.fromDispatch(
        _self.callMethod<JSObject>('formatToParts'.toJS, value),
      );
}
