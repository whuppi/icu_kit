import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'locale.dart';

/// Web mirror of the FFI `LocaleExpander`. Each mutator edits `locale` in
/// place (native's discarded TransformResult).
extension type LocaleExpander._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LocaleExpander.fromDispatch(JSObject o) = LocaleExpander._;

  /// Add likely subtags to [locale] in place (en → en-Latn-US).
  void maximize(Locale locale) {
    _self.callMethod<JSAny?>('maximize'.toJS, locale);
  }

  /// Remove likely subtags from [locale] in place (en-Latn-US → en).
  void minimize(Locale locale) {
    _self.callMethod<JSAny?>('minimize'.toJS, locale);
  }

  /// Minimize [locale] in place, preferring to keep the script over
  /// the region.
  void minimizeFavorScript(Locale locale) {
    _self.callMethod<JSAny?>('minimizeFavorScript'.toJS, locale);
  }
}
