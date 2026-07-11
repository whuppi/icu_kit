// Mirrors of the native PluralRules / PluralOperands / PluralCategory /
// PluralCategories bindings over their Diplomat JS classes. Used surface
// only — construction of PluralRules goes through dispatch, so the mirror
// carries no cardinal/ordinal factories.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// CLDR plural rules handle — web mirror of the FFI `PluralRules`.
extension type PluralRules._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory PluralRules.fromDispatch(JSObject o) = PluralRules._;

  /// The CLDR plural category the operands [op] select.
  PluralCategory categoryFor(PluralOperands op) => PluralCategory._fromJs(
    _self.callMethod<JSObject>('categoryFor'.toJS, op),
  );

  /// Which categories this locale's rule set actually uses.
  PluralCategories get categories =>
      PluralCategories._(_self.getProperty<JSObject>('categories'.toJS));
}

/// Plural operands — web mirror of the FFI `PluralOperands`.
extension type PluralOperands._(JSObject _self) implements JSObject {
  /// Parse a numeric string (e.g. "1.50") preserving trailing zeros,
  /// which affect plural selection in some locales.
  factory PluralOperands.fromString(String s) {
    final cls = IcuKit.module.getProperty<JSObject>('PluralOperands'.toJS);
    return PluralOperands._(
      cls.callMethod<JSObject>('fromString'.toJS, s.toJS),
    );
  }
}

/// CLDR plural category — same variant names as the native binding enum,
/// so facade `switch`es stay exhaustive on both platforms.
enum PluralCategory {
  /// CLDR `zero` (e.g. 0 in Latvian).
  zero,

  /// CLDR `one` — singular (e.g. 1 in en-US).
  one,

  /// CLDR `two` — dual (e.g. 2 in Arabic).
  two,

  /// CLDR `few` — paucal (e.g. 2-4 in Czech).
  few,

  /// CLDR `many` (e.g. 5+ in Arabic, fractions in Czech).
  many,

  /// CLDR `other` — the catch-all every locale has.
  other;

  /// Diplomat's JS enum objects expose the PascalCase variant name on a
  /// `value` getter.
  static PluralCategory _fromJs(JSObject js) {
    final raw = js.getProperty<JSString>('value'.toJS).toDart;
    return switch (raw) {
      'Zero' => zero,
      'One' => one,
      'Two' => two,
      'Few' => few,
      'Many' => many,
      'Other' => other,
      _ => throw StateError('Unknown PluralCategory value from JS: $raw'),
    };
  }
}

/// Bag of "which categories exist for this rule set" flags — web mirror of
/// the FFI `PluralCategories` struct.
extension type PluralCategories._(JSObject _self) implements JSObject {
  /// True if this rule set uses `zero`.
  bool get zero => _self.getProperty<JSBoolean>('zero'.toJS).toDart;

  /// True if this rule set uses `one`.
  bool get one => _self.getProperty<JSBoolean>('one'.toJS).toDart;

  /// True if this rule set uses `two`.
  bool get two => _self.getProperty<JSBoolean>('two'.toJS).toDart;

  /// True if this rule set uses `few`.
  bool get few => _self.getProperty<JSBoolean>('few'.toJS).toDart;

  /// True if this rule set uses `many`.
  bool get many => _self.getProperty<JSBoolean>('many'.toJS).toDart;

  /// True if this rule set uses `other`.
  bool get other => _self.getProperty<JSBoolean>('other'.toJS).toDart;
}
