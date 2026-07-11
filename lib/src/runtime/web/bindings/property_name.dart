// Mirror of the native `PropertyValueNameToEnumMapper` binding plus the
// ten property-value-enum classes it resolves codes against (Script,
// BidiClass, NumericType, EastAsianWidth, LineBreak,
// GraphemeClusterBreak, WordBreak, SentenceBreak, HangulSyllableType,
// CanonicalCombiningClass). Each value class shares the same shape:
// `static X? fromIntegerValue(int)` + instance `shortName()`/`longName()`.
// JS names match the Dart names exactly (verified via the pre-merge web
// facade's `_classNameForKind` + `fromIntegerValue`/`shortName`/`longName`
// dispatch).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `PropertyValueNameToEnumMapper`.
extension type PropertyValueNameToEnumMapper._(JSObject _self)
    implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory PropertyValueNameToEnumMapper.fromDispatch(JSObject o) =
      PropertyValueNameToEnumMapper._;

  /// Property value for an exact-match [name]; -1 when unknown.
  int getStrict(String name) =>
      _self.callMethod<JSNumber>('getStrict'.toJS, name.toJS).toDartInt;

  /// Property value for [name] matched loosely (case, hyphens,
  /// underscores ignored); -1 when unknown.
  int getLoose(String name) =>
      _self.callMethod<JSNumber>('getLoose'.toJS, name.toJS).toDartInt;
}

/// Web mirror of the FFI `Script`.
extension type Script._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static Script? fromIntegerValue(int code) =>
      _fromIntegerValue('Script', code, Script._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `BidiClass`.
extension type BidiClass._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static BidiClass? fromIntegerValue(int code) =>
      _fromIntegerValue('BidiClass', code, BidiClass._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `NumericType`.
extension type NumericType._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static NumericType? fromIntegerValue(int code) =>
      _fromIntegerValue('NumericType', code, NumericType._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `EastAsianWidth`.
extension type EastAsianWidth._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static EastAsianWidth? fromIntegerValue(int code) =>
      _fromIntegerValue('EastAsianWidth', code, EastAsianWidth._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `LineBreak`.
extension type LineBreak._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static LineBreak? fromIntegerValue(int code) =>
      _fromIntegerValue('LineBreak', code, LineBreak._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `GraphemeClusterBreak`.
extension type GraphemeClusterBreak._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static GraphemeClusterBreak? fromIntegerValue(int code) =>
      _fromIntegerValue('GraphemeClusterBreak', code, GraphemeClusterBreak._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `WordBreak`.
extension type WordBreak._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static WordBreak? fromIntegerValue(int code) =>
      _fromIntegerValue('WordBreak', code, WordBreak._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `SentenceBreak`.
extension type SentenceBreak._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static SentenceBreak? fromIntegerValue(int code) =>
      _fromIntegerValue('SentenceBreak', code, SentenceBreak._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `HangulSyllableType`.
extension type HangulSyllableType._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static HangulSyllableType? fromIntegerValue(int code) =>
      _fromIntegerValue('HangulSyllableType', code, HangulSyllableType._);

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

/// Web mirror of the FFI `CanonicalCombiningClass`.
extension type CanonicalCombiningClass._(JSObject _self) implements JSObject {
  /// Wrap property value [code]; null when out of range.
  static CanonicalCombiningClass? fromIntegerValue(int code) =>
      _fromIntegerValue(
        'CanonicalCombiningClass',
        code,
        CanonicalCombiningClass._,
      );

  /// UCD short alias for this value; null when the value has none.
  String? shortName() => _shortName(_self);

  /// UCD long alias for this value; null when the value has none.
  String? longName() => _longName(_self);
}

T? _fromIntegerValue<T>(
  String jsClassName,
  int code,
  T Function(JSObject) wrap,
) {
  final cls = IcuKit.module.getProperty<JSObject>(jsClassName.toJS);
  final result = cls.callMethod<JSObject?>('fromIntegerValue'.toJS, code.toJS);
  return result == null ? null : wrap(result);
}

String? _shortName(JSObject self) =>
    self.callMethod<JSString?>('shortName'.toJS)?.toDart;

String? _longName(JSObject self) =>
    self.callMethod<JSString?>('longName'.toJS)?.toDart;
