// Mirrors of the native `CurrencyFormatter` / `LongCurrencyFormatter`
// bindings plus the `CurrencyWidth` enum, over the Diplomat JS classes.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'number_format.dart' show Decimal, FormattedNumberParts;

/// Web mirror of the FFI `CurrencyFormatter` (symbol form).
extension type CurrencyFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CurrencyFormatter.fromDispatch(JSObject o) = CurrencyFormatter._;

  /// Format [value] with the symbol for ISO 4217 [currencyCode]
  /// (e.g. "$1,234.56" in en-US for "USD").
  String format(Decimal value, String currencyCode) => _self
      .callMethod<JSString>('format'.toJS, value, currencyCode.toJS)
      .toDart;

  /// Format [value] with [currencyCode] into typed parts.
  FormattedNumberParts formatToParts(Decimal value, String currencyCode) =>
      FormattedNumberParts.fromDispatch(
        _self.callMethod<JSObject>(
          'formatToParts'.toJS,
          value,
          currencyCode.toJS,
        ),
      );
}

/// Web mirror of the FFI `LongCurrencyFormatter` (long form).
extension type LongCurrencyFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LongCurrencyFormatter.fromDispatch(JSObject o) =
      LongCurrencyFormatter._;

  /// Format [value] with the long currency name (e.g. "1,234.56 US
  /// dollars" in en-US).
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;

  /// Format [value] into typed parts.
  FormattedNumberParts formatToParts(Decimal value) =>
      FormattedNumberParts.fromDispatch(
        _self.callMethod<JSObject>('formatToParts'.toJS, value),
      );
}

/// Web mirror of the FFI `CurrencyWidth` enum.
enum CurrencyWidth {
  /// Standard symbol (e.g. "US$" where disambiguation is needed).
  short,

  /// Narrowest symbol (e.g. "$" even where ambiguous).
  narrow;

  /// The JS enum value for this width.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('CurrencyWidth'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      CurrencyWidth.short => 'Short'.toJS,
      CurrencyWidth.narrow => 'Narrow'.toJS,
    });
  }
}
