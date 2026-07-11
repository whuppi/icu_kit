import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'js_bool.dart';

/// Direction of a locale — same variant names as the FFI `LocaleDirection`.
enum LocaleDirection {
  /// Left-to-right script (e.g. Latin, Cyrillic).
  leftToRight,

  /// Right-to-left script (e.g. Arabic, Hebrew).
  rightToLeft,

  /// Direction could not be determined.
  unknown;

  static LocaleDirection _fromJs(JSObject js) {
    final v = js.getProperty<JSString>('value'.toJS).toDart;
    return switch (v) {
      'LeftToRight' => leftToRight,
      'RightToLeft' => rightToLeft,
      'Unknown' => unknown,
      _ => throw StateError('Unknown LocaleDirection value: $v'),
    };
  }
}

/// Web mirror of the FFI `LocaleDirectionality`.
extension type LocaleDirectionality._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LocaleDirectionality.fromDispatch(JSObject o) =
      LocaleDirectionality._;

  /// Direction of a [locale] handle. The native binding's `operator []`
  /// maps to JS `get`; takes a raw JSObject because the Locale mirror's
  /// handle is a JSObject on web.
  LocaleDirection operator [](JSObject locale) =>
      LocaleDirection._fromJs(_self.callMethod<JSObject>('get'.toJS, locale));

  /// True if the [locale] handle's script is left-to-right.
  bool isLeftToRight(JSObject locale) =>
      readJsBool(_self.callMethod<JSAny?>('isLeftToRight'.toJS, locale));

  /// True if the [locale] handle's script is right-to-left.
  bool isRightToLeft(JSObject locale) =>
      readJsBool(_self.callMethod<JSAny?>('isRightToLeft'.toJS, locale));
}
