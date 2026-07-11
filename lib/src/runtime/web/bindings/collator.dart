// Mirror of the native `Collator` binding plus the `CollatorOptions` struct
// and its four enums, over the Diplomat JS `Collator` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `Collator`.
extension type Collator._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory Collator.fromDispatch(JSObject o) = Collator._;

  /// UCA comparison: negative when [left] < [right], zero when equal,
  /// positive when [left] > [right].
  int compare(String left, String right) => _self
      .callMethod<JSNumber>('compare'.toJS, left.toJS, right.toJS)
      .toDartInt;
}

/// Web mirror of the FFI `CollatorOptions` struct.
extension type CollatorOptions._(JSObject _self) implements JSObject {
  /// Build the JS options object; omitted fields keep locale defaults.
  factory CollatorOptions({
    CollatorStrength? strength,
    CollatorAlternateHandling? alternateHandling,
    CollatorMaxVariable? maxVariable,
    CollatorCaseLevel? caseLevel,
  }) {
    final o = JSObject();
    if (strength != null) o.setProperty('strength'.toJS, strength._toJs());
    if (alternateHandling != null) {
      o.setProperty('alternateHandling'.toJS, alternateHandling._toJs());
    }
    if (maxVariable != null) {
      o.setProperty('maxVariable'.toJS, maxVariable._toJs());
    }
    if (caseLevel != null) {
      o.setProperty('caseLevel'.toJS, caseLevel._toJs());
    }
    return CollatorOptions._(o);
  }
}

/// Web mirror of the FFI `CollatorStrength` enum.
enum CollatorStrength {
  /// Base letters only ("a" == "A" == "á").
  primary,

  /// Adds accent differences ("a" != "á", still "a" == "A").
  secondary,

  /// Adds case differences ("a" != "A") — the default.
  tertiary,

  /// Adds punctuation when alternate handling is shifted.
  quaternary,

  /// Falls back to code-point order for otherwise-equal strings.
  identical;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('CollatorStrength'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      CollatorStrength.primary => 'Primary'.toJS,
      CollatorStrength.secondary => 'Secondary'.toJS,
      CollatorStrength.tertiary => 'Tertiary'.toJS,
      CollatorStrength.quaternary => 'Quaternary'.toJS,
      CollatorStrength.identical => 'Identical'.toJS,
    });
  }
}

/// Web mirror of the FFI `CollatorAlternateHandling` enum.
enum CollatorAlternateHandling {
  /// Spaces and punctuation count as base characters.
  nonIgnorable,

  /// Spaces and punctuation are ignored up to quaternary strength.
  shifted;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>(
      'CollatorAlternateHandling'.toJS,
    );
    return cls.getProperty<JSObject>(switch (this) {
      CollatorAlternateHandling.nonIgnorable => 'NonIgnorable'.toJS,
      CollatorAlternateHandling.shifted => 'Shifted'.toJS,
    });
  }
}

/// Web mirror of the FFI `CollatorMaxVariable` enum.
enum CollatorMaxVariable {
  /// Only spaces are variable (affected by shifted handling).
  space,

  /// Spaces and punctuation are variable.
  punctuation,

  /// Spaces, punctuation, and symbols are variable.
  symbol,

  /// Spaces, punctuation, symbols, and currency signs are variable.
  currency;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('CollatorMaxVariable'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      CollatorMaxVariable.space => 'Space'.toJS,
      CollatorMaxVariable.punctuation => 'Punctuation'.toJS,
      CollatorMaxVariable.symbol => 'Symbol'.toJS,
      CollatorMaxVariable.currency => 'Currency'.toJS,
    });
  }
}

/// Web mirror of the FFI `CollatorCaseLevel` enum.
enum CollatorCaseLevel {
  /// No dedicated case comparison level — the default.
  off,

  /// Insert a case level between secondary and tertiary.
  on;

  JSObject _toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('CollatorCaseLevel'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      CollatorCaseLevel.off => 'Off'.toJS,
      CollatorCaseLevel.on => 'On'.toJS,
    });
  }
}
