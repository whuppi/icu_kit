// Mirror of the native `ExemplarCharacters` binding over the Diplomat JS
// class of the same name.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'js_bool.dart';

/// Web mirror of the FFI `ExemplarCharacters`.
extension type ExemplarCharacters._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory ExemplarCharacters.fromDispatch(JSObject o) = ExemplarCharacters._;

  /// True if code point [cp] is in this exemplar set.
  bool contains(int cp) =>
      readJsBool(_self.callMethod<JSAny?>('contains'.toJS, cp.toJS));

  /// True if the whole string [s] is in this exemplar set (multi-
  /// character exemplars like "ch" count as one entry).
  bool containsStr(String s) =>
      readJsBool(_self.callMethod<JSAny?>('containsStr'.toJS, s.toJS));
}
