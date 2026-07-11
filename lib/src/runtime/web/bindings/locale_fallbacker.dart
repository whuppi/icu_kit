import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'locale.dart';

/// Priority mode — same variant names as the FFI `LocaleFallbackPriority`.
enum LocaleFallbackPriority {
  /// Strip region first, keep the language (e.g. en-US → en).
  language,

  /// Keep the region, fall back through languages (e.g. es-419 chains
  /// by region).
  region;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'LocaleFallbackPriority'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      language => 'Language'.toJS,
      region => 'Region'.toJS,
    });
  }
}

/// Web mirror of the FFI `LocaleFallbackConfig` struct.
extension type LocaleFallbackConfig._(JSObject _self) implements JSObject {
  /// Build the JS config struct with [priority].
  factory LocaleFallbackConfig({required LocaleFallbackPriority priority}) {
    final fields = JSObject();
    fields.setProperty('priority'.toJS, priority._toJs());
    final cls = IcuKit.module.getProperty<JSFunction>(
      'LocaleFallbackConfig'.toJS,
    );
    return LocaleFallbackConfig._(cls.callAsConstructor<JSObject>(fields));
  }
}

/// Web mirror of the FFI `LocaleFallbacker`.
extension type LocaleFallbacker._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LocaleFallbacker.fromDispatch(JSObject o) = LocaleFallbacker._;

  /// This fallbacker specialized to [config]'s priority mode.
  LocaleFallbackerWithConfig forConfig(LocaleFallbackConfig config) =>
      LocaleFallbackerWithConfig._(
        _self.callMethod<JSObject>('forConfig'.toJS, config),
      );
}

/// Web mirror of the FFI `LocaleFallbackerWithConfig`.
extension type LocaleFallbackerWithConfig._(JSObject _self)
    implements JSObject {
  /// Fallback chain for a [locale] handle, from most to least
  /// specific. Takes a raw JSObject: the Locale mirror's handle is a
  /// JSObject on web.
  LocaleFallbackIterator fallbackForLocale(JSObject locale) =>
      LocaleFallbackIterator._(
        _self.callMethod<JSObject>('fallbackForLocale'.toJS, locale),
      );
}

/// Web mirror of the FFI `LocaleFallbackIterator` — a Dart `Iterator<Locale>`
/// hiding the JS `{value, done}` protocol behind moveNext/current, so the
/// shared facade's native-style loop works unchanged.
final class LocaleFallbackIterator implements Iterator<Locale> {
  LocaleFallbackIterator._(this._js);
  final JSObject _js;
  Locale? _current;

  @override
  Locale get current => _current!;

  @override
  bool moveNext() {
    final step = _js.callMethod<JSObject>('next'.toJS);
    final done = step.getProperty<JSBoolean>('done'.toJS).toDart;
    if (done) return false;
    final value = step.getProperty<JSObject?>('value'.toJS);
    if (value == null) return false;
    _current = Locale.fromDispatch(value);
    return true;
  }
}
