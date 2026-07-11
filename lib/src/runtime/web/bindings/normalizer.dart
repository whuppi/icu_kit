// Mirrors of the native `ComposingNormalizer` / `DecomposingNormalizer`
// bindings over the Diplomat JS classes of the same names. Diplomat-JS
// returns booleans as JS numbers (0/1) — read them as JSNumber, never
// JSBoolean (the bool cast throws on dart2js).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web mirror of the FFI `ComposingNormalizer` (NFC / NFKC).
extension type ComposingNormalizer._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory ComposingNormalizer.fromDispatch(JSObject o) = ComposingNormalizer._;

  /// [s] in this normalizer's normalization form.
  String normalize(String s) =>
      _self.callMethod<JSString>('normalize'.toJS, s.toJS).toDart;

  /// True if [s] is already in this normalization form.
  bool isNormalized(String s) =>
      _self.callMethod<JSNumber>('isNormalized'.toJS, s.toJS).toDartInt != 0;

  /// UTF-16 index up to which [s] is normalized; equals `s.length`
  /// when fully normalized.
  int isNormalizedUpTo(String s) =>
      _self.callMethod<JSNumber>('isNormalizedUpTo'.toJS, s.toJS).toDartInt;
}

/// Web mirror of the FFI `DecomposingNormalizer` (NFD / NFKD).
extension type DecomposingNormalizer._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory DecomposingNormalizer.fromDispatch(JSObject o) =
      DecomposingNormalizer._;

  /// [s] in this normalizer's normalization form.
  String normalize(String s) =>
      _self.callMethod<JSString>('normalize'.toJS, s.toJS).toDart;

  /// True if [s] is already in this normalization form.
  bool isNormalized(String s) =>
      _self.callMethod<JSNumber>('isNormalized'.toJS, s.toJS).toDartInt != 0;

  /// UTF-16 index up to which [s] is normalized; equals `s.length`
  /// when fully normalized.
  int isNormalizedUpTo(String s) =>
      _self.callMethod<JSNumber>('isNormalizedUpTo'.toJS, s.toJS).toDartInt;
}
