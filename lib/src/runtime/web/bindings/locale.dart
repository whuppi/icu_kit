// Mirror of the native `Locale` binding (the generated Locale.g.dart) over
// the Diplomat JS class of the same name. Used surface only.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../../errors/icu_error.dart';
import '../init.dart';

/// A BCP-47 locale handle — web mirror of the FFI `Locale`.
///
/// `implements JSObject` so raw-JSObject call sites in dispatch accept
/// it directly.
extension type Locale._(JSObject _self) implements JSObject {
  /// Parse a BCP-47 tag. Throws (a JS `Error`, catchable with plain
  /// `catch`) when the tag doesn't parse — same observable contract as the
  /// native binding's failed result.
  factory Locale.fromString(String name) {
    final cls = IcuKit.module.getProperty<JSObject>('Locale'.toJS);
    if (cls.isUndefinedOrNull) {
      throw IcuLoadError(
        'web',
        StateError('Locale class not exported by icu_kit JS module'),
      );
    }
    return Locale._(cls.callMethod<JSObject>('fromString'.toJS, name.toJS));
  }

  /// Wrap a raw JS Locale handle (e.g. one yielded by a fallback iterator).
  factory Locale.fromDispatch(JSObject o) = Locale._;

  /// The normalized BCP-47 tag. Named to match the native `asBcp47`
  /// extension (an extension type can't override Object.toString), so the
  /// shared facade reads `.asBcp47` on either platform.
  String get asBcp47 => _self.callMethod<JSString>('toString'.toJS).toDart;
}
