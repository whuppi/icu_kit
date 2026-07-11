// Mirrors of the native `RegionDisplayNames` / `LocaleDisplayNamesFormatter`
// bindings plus the `DisplayNamesOptions` struct and its three enums, over
// the Diplomat JS classes. The locale param on `LocaleDisplayNamesFormatter
// .of` takes a raw JSObject: the Locale mirror's handle is a JSObject on
// web.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `RegionDisplayNames`.
extension type RegionDisplayNames._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory RegionDisplayNames.fromDispatch(JSObject o) = RegionDisplayNames._;

  /// Display name of a [region] code (e.g. "DE" → "Germany" in en-US).
  String of(String region) =>
      _self.callMethod<JSString>('of'.toJS, region.toJS).toDart;
}

/// Web mirror of the FFI `LocaleDisplayNamesFormatter`.
extension type LocaleDisplayNamesFormatter._(JSObject _self)
    implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory LocaleDisplayNamesFormatter.fromDispatch(JSObject o) =
      LocaleDisplayNamesFormatter._;

  /// Display name of a [locale] handle (e.g. de-CH → "Swiss High
  /// German" in en-US).
  String of(JSObject locale) =>
      _self.callMethod<JSString>('of'.toJS, locale).toDart;
}

/// Web mirror of the FFI `DisplayNamesOptions` struct.
extension type DisplayNamesOptions._(JSObject _self) implements JSObject {
  /// Build the JS options object; omitted fields keep locale defaults.
  factory DisplayNamesOptions({
    DisplayNamesStyle? style,
    DisplayNamesFallback? fallback,
    LanguageDisplay? languageDisplay,
  }) {
    final o = JSObject();
    if (style != null) o.setProperty('style'.toJS, style._toJs());
    if (fallback != null) o.setProperty('fallback'.toJS, fallback._toJs());
    if (languageDisplay != null) {
      o.setProperty('languageDisplay'.toJS, languageDisplay._toJs());
    }
    return DisplayNamesOptions._(o);
  }
}

/// Web mirror of the FFI `DisplayNamesStyle` enum.
enum DisplayNamesStyle {
  /// Narrowest form; may be ambiguous.
  narrow,

  /// Short form (e.g. "US" style abbreviations where available).
  short,

  /// Long form (e.g. "United States") — the default.
  long,

  /// Form suited to menu listings.
  menu;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('DisplayNamesStyle'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      DisplayNamesStyle.narrow => 'Narrow'.toJS,
      DisplayNamesStyle.short => 'Short'.toJS,
      DisplayNamesStyle.long => 'Long'.toJS,
      DisplayNamesStyle.menu => 'Menu'.toJS,
    });
  }
}

/// Web mirror of the FFI `DisplayNamesFallback` enum.
enum DisplayNamesFallback {
  /// Return the requested code itself when no name exists.
  code,

  /// Return nothing when no name exists.
  none;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'DisplayNamesFallback'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      DisplayNamesFallback.code => 'Code'.toJS,
      DisplayNamesFallback.none => 'None'.toJS,
    });
  }
}

/// Web mirror of the FFI `LanguageDisplay` enum.
enum LanguageDisplay {
  /// Dialect names (e.g. "American English" for en-US).
  dialect,

  /// Standard names (e.g. "English (United States)" for en-US).
  standard;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('LanguageDisplay'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      LanguageDisplay.dialect => 'Dialect'.toJS,
      LanguageDisplay.standard => 'Standard'.toJS,
    });
  }
}
