// Mirrors of the native segmenter bindings — four segmenter classes and
// their four break-iterator classes — over the Diplomat JS classes. Each
// iterator exposes `int next()` (returns -1 at end); each segmenter's
// `segment(input)` returns its matching iterator. No-locale factories map
// to the JS `createAuto` static / bare constructor.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `GraphemeClusterSegmenter`.
extension type GraphemeClusterSegmenter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory GraphemeClusterSegmenter.fromDispatch(JSObject o) =
      GraphemeClusterSegmenter._;

  /// Break iterator over [input]'s grapheme-cluster boundaries.
  GraphemeClusterBreakIteratorUtf16 segment(String input) =>
      GraphemeClusterBreakIteratorUtf16._(
        _self.callMethod<JSObject>('segment'.toJS, input.toJS),
      );
}

/// Web mirror of the FFI `GraphemeClusterBreakIteratorUtf16`.
extension type GraphemeClusterBreakIteratorUtf16._(JSObject _self)
    implements JSObject {
  /// Next boundary as a UTF-16 index; -1 at end.
  int next() => _self.callMethod<JSNumber>('next'.toJS).toDartInt;
}

/// Web mirror of the FFI `WordSegmenter`.
extension type WordSegmenter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory WordSegmenter.fromDispatch(JSObject o) = WordSegmenter._;

  /// No-locale word segmenter — JS static `createAuto`.
  factory WordSegmenter.auto() {
    final cls = IcuKit.module.getProperty<JSObject>('WordSegmenter'.toJS);
    return WordSegmenter._(cls.callMethod<JSObject>('createAuto'.toJS));
  }

  /// Break iterator over [input]'s word boundaries.
  WordBreakIteratorUtf16 segment(String input) => WordBreakIteratorUtf16._(
    _self.callMethod<JSObject>('segment'.toJS, input.toJS),
  );
}

/// Web mirror of the FFI `WordBreakIteratorUtf16`.
extension type WordBreakIteratorUtf16._(JSObject _self) implements JSObject {
  /// Next boundary as a UTF-16 index; -1 at end.
  int next() => _self.callMethod<JSNumber>('next'.toJS).toDartInt;
}

/// Web mirror of the FFI `SentenceSegmenter`.
extension type SentenceSegmenter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory SentenceSegmenter.fromDispatch(JSObject o) = SentenceSegmenter._;

  /// No-locale sentence segmenter — JS bare constructor.
  factory SentenceSegmenter() {
    final cls = IcuKit.module.getProperty<JSFunction>('SentenceSegmenter'.toJS);
    return SentenceSegmenter._(cls.callAsConstructor<JSObject>());
  }

  /// Break iterator over [input]'s sentence boundaries.
  SentenceBreakIteratorUtf16 segment(String input) =>
      SentenceBreakIteratorUtf16._(
        _self.callMethod<JSObject>('segment'.toJS, input.toJS),
      );
}

/// Web mirror of the FFI `SentenceBreakIteratorUtf16`.
extension type SentenceBreakIteratorUtf16._(JSObject _self)
    implements JSObject {
  /// Next boundary as a UTF-16 index; -1 at end.
  int next() => _self.callMethod<JSNumber>('next'.toJS).toDartInt;
}

/// Web mirror of the FFI `LineSegmenter`.
extension type LineSegmenter._(JSObject _self) implements JSObject {
  /// Auto line segmenter — JS static `createAuto`.
  factory LineSegmenter.auto() {
    final cls = IcuKit.module.getProperty<JSObject>('LineSegmenter'.toJS);
    return LineSegmenter._(cls.callMethod<JSObject>('createAuto'.toJS));
  }

  /// Break iterator over [input]'s line-break opportunities.
  LineBreakIteratorUtf16 segment(String input) => LineBreakIteratorUtf16._(
    _self.callMethod<JSObject>('segment'.toJS, input.toJS),
  );
}

/// Web mirror of the FFI `LineBreakIteratorUtf16`.
extension type LineBreakIteratorUtf16._(JSObject _self) implements JSObject {
  /// Next boundary as a UTF-16 index; -1 at end.
  int next() => _self.callMethod<JSNumber>('next'.toJS).toDartInt;
}
