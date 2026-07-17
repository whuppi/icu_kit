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

  /// Create a decimal from a double rounded to [digits] significant digits.
  /// Mirrors ICU4X `Decimal::try_from_f64` with `SignificantDigits`.
  factory Decimal.fromDoubleWithSignificantDigits(double f, int digits) =>
      Decimal._(
        _cls.callMethod<JSObject>(
          'fromNumberWithSignificantDigits'.toJS,
          f.toJS,
          digits.toJS,
        ),
      );

  /// The power-of-ten position of the most significant digit (e.g. 3 for
  /// 1234, -2 for 0.05). This is ICU4X `magnitude_range`'s `end` — the range
  /// is a Rust RangeInclusive, so the HIGH magnitude is `end`.
  int get magnitudeEnd =>
      _self.getProperty<JSNumber>('magnitudeEnd'.toJS).toDartInt;

  /// Zero-pad on the left up to (10^[position]) so the integer part shows
  /// at least `position + 1` digits. Mirrors ICU4X `Decimal::pad_start`.
  void padStart(int position) =>
      _self.callMethod<JSAny?>('padStart'.toJS, position.toJS);

  /// Zero-pad on the right down to (10^[position]) so the fraction shows at
  /// least `-position` digits. Mirrors ICU4X `Decimal::pad_end`.
  void padEnd(int position) =>
      _self.callMethod<JSAny?>('padEnd'.toJS, position.toJS);

  /// Round at (10^[position]) with [mode]. Mirrors ICU4X
  /// `Decimal::round_with_mode`.
  void roundWithMode(int position, DecimalSignedRoundingMode mode) => _self
      .callMethod<JSAny?>('roundWithMode'.toJS, position.toJS, mode.toJs());

  /// Round at (10^[position]) with [mode] to a multiple of [increment].
  /// Mirrors ICU4X `Decimal::round_with_mode_and_increment`.
  void roundWithModeAndIncrement(
    int position,
    DecimalSignedRoundingMode mode,
    DecimalRoundingIncrement increment,
  ) => _self.callMethod<JSAny?>(
    'roundWithModeAndIncrement'.toJS,
    position.toJS,
    mode.toJs(),
    increment.toJs(),
  );

  /// Apply an ECMA-402 sign display to the (already rounded) value.
  /// Mirrors ICU4X `Decimal::apply_sign_display`.
  void applySignDisplay(DecimalSignDisplay signDisplay) =>
      _self.callMethod<JSAny?>('applySignDisplay'.toJS, signDisplay.toJs());

  /// Drop trailing fraction zeros when the value is integer-valued
  /// (ECMA-402 `trailingZeroDisplay: stripIfInteger`). Mirrors ICU4X
  /// `Decimal::trim_end_if_integer`.
  void trimEndIfInteger() => _self.callMethod<JSAny?>('trimEndIfInteger'.toJS);

  static JSObject get _cls =>
      IcuKit.module.getProperty<JSObject>('Decimal'.toJS);
}

/// Web mirror of the FFI `DecimalSignedRoundingMode` — the nine ECMA-402
/// rounding modes. `toJs()` is public so the shaping code can pass it
/// across.
enum DecimalSignedRoundingMode {
  /// Round away from zero.
  expand,

  /// Round toward zero.
  trunc,

  /// Round half away from zero (ECMA-402's default `roundingMode`).
  halfExpand,

  /// Round half toward zero.
  halfTrunc,

  /// Round half to the even neighbor.
  halfEven,

  /// Round toward positive infinity.
  ceil,

  /// Round toward negative infinity.
  floor,

  /// Round half toward positive infinity.
  halfCeil,

  /// Round half toward negative infinity.
  halfFloor;

  /// The JS enum value for this mode.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'DecimalSignedRoundingMode'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      expand => 'Expand'.toJS,
      trunc => 'Trunc'.toJS,
      halfExpand => 'HalfExpand'.toJS,
      halfTrunc => 'HalfTrunc'.toJS,
      halfEven => 'HalfEven'.toJS,
      ceil => 'Ceil'.toJS,
      floor => 'Floor'.toJS,
      halfCeil => 'HalfCeil'.toJS,
      halfFloor => 'HalfFloor'.toJS,
    });
  }
}

/// Web mirror of the FFI `DecimalSignDisplay` — ECMA-402 `signDisplay`.
enum DecimalSignDisplay {
  /// Sign on negative values only (the default).
  auto,

  /// Never show a sign.
  never,

  /// Sign on every value, including zero.
  always,

  /// Sign on every non-zero value.
  exceptZero,

  /// Minus on negative values, never a plus.
  negative;

  /// The JS enum value for this display.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('DecimalSignDisplay'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      auto => 'Auto'.toJS,
      never => 'Never'.toJS,
      always => 'Always'.toJS,
      exceptZero => 'ExceptZero'.toJS,
      negative => 'Negative'.toJS,
    });
  }
}

/// Web mirror of the FFI `DecimalRoundingIncrement` — the multiple a
/// rounding operation snaps to at its position.
enum DecimalRoundingIncrement {
  /// Plain positional rounding.
  multiplesOf1,

  /// Multiples of 2 at the rounding position.
  multiplesOf2,

  /// Multiples of 5 at the rounding position.
  multiplesOf5,

  /// Multiples of 25 at the rounding position.
  multiplesOf25;

  /// The JS enum value for this increment.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'DecimalRoundingIncrement'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      multiplesOf1 => 'MultiplesOf1'.toJS,
      multiplesOf2 => 'MultiplesOf2'.toJS,
      multiplesOf5 => 'MultiplesOf5'.toJS,
      multiplesOf25 => 'MultiplesOf25'.toJS,
    });
  }
}

/// Web mirror of the FFI `FormattedNumberParts`.
extension type FormattedNumberParts._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by a formatter's `formatToParts`.
  factory FormattedNumberParts.fromDispatch(JSObject o) =
      FormattedNumberParts._;

  /// The number of parts.
  int get partCount => _self.getProperty<JSNumber>('partCount'.toJS).toDartInt;

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
