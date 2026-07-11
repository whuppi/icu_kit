import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'locale.dart';

/// Web mirror of the FFI `LocaleCanonicalizer`.
extension type LocaleCanonicalizer._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LocaleCanonicalizer.fromDispatch(JSObject o) = LocaleCanonicalizer._;

  /// Canonicalizes [locale] in place (native returns a TransformResult the
  /// facade discards; the mirror discards it too).
  void canonicalize(Locale locale) {
    _self.callMethod<JSAny?>('canonicalize'.toJS, locale);
  }
}
