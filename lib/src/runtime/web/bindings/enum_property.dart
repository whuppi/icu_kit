// Mirrors of the native `CodePointMapData8` / `CodePointMapData16`
// bindings (both just an `operator[]` lookup) over the Diplomat JS
// classes' `get` method.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web mirror of the FFI `CodePointMapData8`.
extension type CodePointMapData8._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CodePointMapData8.fromDispatch(JSObject o) = CodePointMapData8._;

  /// Property value for code point [cp].
  int operator [](int cp) =>
      _self.callMethod<JSNumber>('get'.toJS, cp.toJS).toDartInt;
}

/// Web mirror of the FFI `CodePointMapData16`.
extension type CodePointMapData16._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CodePointMapData16.fromDispatch(JSObject o) = CodePointMapData16._;

  /// Property value for code point [cp].
  int operator [](int cp) =>
      _self.callMethod<JSNumber>('get'.toJS, cp.toJS).toDartInt;
}
