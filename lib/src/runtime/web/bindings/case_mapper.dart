// Mirrors of the native `CaseMapper` / `TitlecaseMapper` bindings plus the
// `TitlecaseOptions` struct and its two enums, over the Diplomat JS classes.
// The locale params take a raw JSObject: the Locale mirror's handle is a
// JSObject on web, so a shared facade feeds JSObject here.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `CaseMapper`.
extension type CaseMapper._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CaseMapper.fromDispatch(JSObject o) = CaseMapper._;

  /// Full Unicode lowercase of [s] with [locale]-specific tailoring.
  String lowercase(String s, JSObject locale) =>
      _self.callMethod<JSString>('lowercase'.toJS, s.toJS, locale).toDart;

  /// Full Unicode uppercase of [s] with [locale]-specific tailoring.
  String uppercase(String s, JSObject locale) =>
      _self.callMethod<JSString>('uppercase'.toJS, s.toJS, locale).toDart;

  /// Case-fold [s] for caseless comparison (locale-independent).
  String fold(String s) =>
      _self.callMethod<JSString>('fold'.toJS, s.toJS).toDart;

  /// Case-fold [s] with Turkic mappings (dotted/dotless I).
  String foldTurkic(String s) =>
      _self.callMethod<JSString>('foldTurkic'.toJS, s.toJS).toDart;
}

/// Web mirror of the FFI `TitlecaseMapper`.
extension type TitlecaseMapper._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory TitlecaseMapper.fromDispatch(JSObject o) = TitlecaseMapper._;

  /// Titlecase one segment [s] (e.g. one word) with [locale]-specific
  /// tailoring per [options].
  String titlecaseSegment(
    String s,
    JSObject locale,
    TitlecaseOptions options,
  ) => _self.callMethodVarArgs<JSString>('titlecaseSegment'.toJS, [
    s.toJS,
    locale,
    options,
  ]).toDart;
}

/// Web mirror of the FFI `TitlecaseOptions` struct — built from the two
/// enum values into the plain JS options object the JS method expects.
/// Params optional-nullable to match the native struct's constructor;
/// omitted fields fall back to the JS side's defaults.
extension type TitlecaseOptions._(JSObject _self) implements JSObject {
  /// Build the JS options object; omitted fields keep the defaults.
  factory TitlecaseOptions({
    LeadingAdjustment? leadingAdjustment,
    TrailingCase? trailingCase,
  }) {
    final o = JSObject();
    if (leadingAdjustment != null) {
      o.setProperty('leadingAdjustment'.toJS, leadingAdjustment._toJs());
    }
    if (trailingCase != null) {
      o.setProperty('trailingCase'.toJS, trailingCase._toJs());
    }
    return TitlecaseOptions._(o);
  }
}

/// Web mirror of the FFI `LeadingAdjustment` enum.
enum LeadingAdjustment {
  /// Adjust past leading characters the way the locale expects (e.g.
  /// skip Dutch "ij" as a unit) — the default.
  auto,

  /// Titlecase the very first character, no adjustment.
  none,

  /// Skip to the first cased character before titlecasing.
  toCased;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('LeadingAdjustment'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      LeadingAdjustment.auto => 'Auto'.toJS,
      LeadingAdjustment.none => 'None'.toJS,
      LeadingAdjustment.toCased => 'ToCased'.toJS,
    });
  }
}

/// Web mirror of the FFI `TrailingCase` enum.
enum TrailingCase {
  /// Lowercase the rest of the segment — the default.
  lower,

  /// Leave the rest of the segment as-is.
  unchanged;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('TrailingCase'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      TrailingCase.lower => 'Lower'.toJS,
      TrailingCase.unchanged => 'Unchanged'.toJS,
    });
  }
}
