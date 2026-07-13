import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `Decimal`. Dart names match the native binding;
/// the JS names (`fromNumber`, `fromNumberWithRoundTripPrecision`) live
/// inside.
extension type Decimal._(JSObject _self) implements JSObject {
  /// Create a decimal from an integer.
  factory Decimal.fromInt(int v) =>
      Decimal._(_cls.callMethod<JSObject>('fromNumber'.toJS, v.toJS));

  /// Create a decimal from a double, keeping exactly the digits needed
  /// to round-trip it.
  factory Decimal.fromDoubleWithRoundTripPrecision(double f) => Decimal._(
    _cls.callMethod<JSObject>('fromNumberWithRoundTripPrecision'.toJS, f.toJS),
  );

  static JSObject get _cls =>
      IcuKit.module.getProperty<JSObject>('Decimal'.toJS);
}

/// Web mirror of the FFI `FormattedNumberParts`.
extension type FormattedNumberParts._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by a formatter's `formatToParts`.
  factory FormattedNumberParts.fromDispatch(JSObject o) =
      FormattedNumberParts._;

  /// The number of parts.
  int get partCount =>
      _self.getProperty<JSNumber>('partCount'.toJS).toDartInt;

  /// The ECMA-402 type name of the part at [index], or null out of bounds.
  String? partTypeAt(int index) =>
      _self.callMethod<JSString?>('partTypeAt'.toJS, index.toJS)?.toDart;

  /// The substring of the part at [index], or null out of bounds.
  String? partValueAt(int index) =>
      _self.callMethod<JSString?>('partValueAt'.toJS, index.toJS)?.toDart;
}

/// Web mirror of the FFI `DecimalFormatter`.
extension type DecimalFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory DecimalFormatter.fromDispatch(JSObject o) = DecimalFormatter._;

  /// Format [value] with locale digits and separators.
  String format(Decimal value) =>
      _self.callMethod<JSString>('format'.toJS, value).toDart;

  /// Format [value] into typed parts.
  FormattedNumberParts formatToParts(Decimal value) =>
      FormattedNumberParts.fromDispatch(
        _self.callMethod<JSObject>('formatToParts'.toJS, value),
      );
}

/// Web mirror of the FFI `DecimalGroupingStrategy` enum. `toJs()` is public
/// so dispatch can pass it to the JS side.
enum DecimalGroupingStrategy {
  /// Locale-default grouping.
  auto,

  /// No grouping separators.
  never,

  /// Group even when the locale wouldn't (e.g. 4-digit numbers).
  always,

  /// Group only when at least two digits precede the separator
  /// (e.g. "1000" but "10,000").
  min2;

  /// The JS enum value for this strategy.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'DecimalGroupingStrategy'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      auto => 'Auto'.toJS,
      never => 'Never'.toJS,
      always => 'Always'.toJS,
      min2 => 'Min2'.toJS,
    });
  }
}
