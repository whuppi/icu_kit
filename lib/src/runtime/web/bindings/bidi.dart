// Mirrors of the native `Bidi` / `BidiInfo` / `BidiParagraph` /
// `ReorderedIndexMap` bindings + the `BidiDirection` enum, over the
// Diplomat JS classes. Diplomat-JS returns booleans as numbers on some
// paths — the shared `readJsBool` accepts both.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../../errors/icu_error.dart';
import '../init.dart';
import 'js_bool.dart';

/// Web mirror of the FFI `Bidi`.
extension type Bidi._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory Bidi.fromDispatch(JSObject o) = Bidi._;

  /// Run the UAX #9 algorithm over [text]. An invalid [defaultLevel]
  /// falls back to LTR.
  BidiInfo forText(String text, [int? defaultLevel]) => BidiInfo._(
    _self.callMethodVarArgs<JSObject>('forText'.toJS, [
      text.toJS,
      if (defaultLevel != null) defaultLevel.toJS else null,
    ]),
  );

  /// Logical-to-visual index map for a line's embedding [levels].
  /// Levels above 125 are treated as LTR.
  ReorderedIndexMap reorderVisual(List<int> levels) => ReorderedIndexMap._(
    _self.callMethod<JSObject>(
      'reorderVisual'.toJS,
      levels.map((l) => l.toJS).toList().toJS,
    ),
  );

  /// True if embedding [level] is right-to-left (odd).
  static bool levelIsRtl(int level) =>
      readJsBool(_cls().callMethod<JSAny?>('levelIsRtl'.toJS, level.toJS));

  /// True if embedding [level] is left-to-right (even).
  static bool levelIsLtr(int level) =>
      readJsBool(_cls().callMethod<JSAny?>('levelIsLtr'.toJS, level.toJS));

  /// The base RTL embedding level (1).
  static int levelRtl() =>
      _cls().callMethod<JSNumber>('levelRtl'.toJS).toDartInt;

  /// The base LTR embedding level (0).
  static int levelLtr() =>
      _cls().callMethod<JSNumber>('levelLtr'.toJS).toDartInt;

  static JSObject _cls() => IcuKit.module.getProperty<JSObject>('Bidi'.toJS);
}

/// Web mirror of the FFI `ReorderedIndexMap` — `length` + `operator[]`.
extension type ReorderedIndexMap._(JSObject _self) implements JSObject {
  /// Number of entries in the map.
  int get length => _self.getProperty<JSNumber>('length'.toJS).toDartInt;

  /// Visual position of logical [index].
  int operator [](int index) =>
      _self.callMethod<JSNumber>('get'.toJS, index.toJS).toDartInt;
}

/// Web mirror of the FFI `BidiInfo`.
extension type BidiInfo._(JSObject _self) implements JSObject {
  /// Number of paragraphs in the analyzed text.
  int get paragraphCount =>
      _self.getProperty<JSNumber>('paragraphCount'.toJS).toDartInt;

  /// Length of the analyzed text in UTF-8 bytes.
  int get size => _self.getProperty<JSNumber>('size'.toJS).toDartInt;

  /// Embedding level at UTF-8 byte position [pos]; 0 when out of range.
  int levelAt(int pos) =>
      _self.callMethod<JSNumber>('levelAt'.toJS, pos.toJS).toDartInt;

  /// Paragraph [n], or null when out of range.
  BidiParagraph? paragraphAt(int n) {
    final p = _self.callMethod<JSObject?>('paragraphAt'.toJS, n.toJS);
    if (p == null) return null;
    return BidiParagraph._(p);
  }
}

/// Web mirror of the FFI `BidiParagraph`.
extension type BidiParagraph._(JSObject _self) implements JSObject {
  /// Overall direction of this paragraph.
  BidiDirection get direction {
    final dir = _self.getProperty<JSObject>('direction'.toJS);
    final value = dir.getProperty<JSString>('value'.toJS).toDart;
    return switch (value) {
      'Ltr' => BidiDirection.ltr,
      'Rtl' => BidiDirection.rtl,
      'Mixed' => BidiDirection.mixed,
      _ => throw IcuLoadError(
        'web',
        StateError('Unknown BidiDirection value: $value'),
      ),
    };
  }

  /// Base embedding level of this paragraph.
  int get level => _self.getProperty<JSNumber>('level'.toJS).toDartInt;

  /// Embedding level at byte position [pos] after line reordering.
  int reorderedLevelAt(int pos) =>
      _self.callMethod<JSNumber>('reorderedLevelAt'.toJS, pos.toJS).toDartInt;

  /// Length of this paragraph in UTF-8 bytes.
  int get size => _self.getProperty<JSNumber>('size'.toJS).toDartInt;

  /// Start index of this paragraph within the source text.
  int get rangeStart =>
      _self.getProperty<JSNumber>('rangeStart'.toJS).toDartInt;

  /// End index (exclusive) of this paragraph within the source text.
  int get rangeEnd => _self.getProperty<JSNumber>('rangeEnd'.toJS).toDartInt;

  /// Embedding level at byte position [pos] within this paragraph's
  /// range.
  int levelAt(int pos) =>
      _self.callMethod<JSNumber>('levelAt'.toJS, pos.toJS).toDartInt;

  /// The line [rangeStart]..[rangeEnd] reordered for display, or null
  /// when the range is not within this paragraph.
  String? reorderLine(int rangeStart, int rangeEnd) => _self
      .callMethod<JSString?>('reorderLine'.toJS, rangeStart.toJS, rangeEnd.toJS)
      ?.toDart;
}

/// Web mirror of the FFI `BidiDirection` enum.
enum BidiDirection {
  /// Entirely left-to-right.
  ltr,

  /// Entirely right-to-left.
  rtl,

  /// Contains both directions.
  mixed,
}
