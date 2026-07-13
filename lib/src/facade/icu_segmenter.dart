import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// One segment yielded by an [IcuSegmenter].
///
/// [start] and [end] are UTF-16 code unit indices into the input string —
/// the same units Dart's `String` uses for `substring(start, end)` and
/// `String.length`. [text] is the segment content.
final class IcuSegment {
  /// Create a segment spanning [start]..[end] with content [text].
  const IcuSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  /// UTF-16 index where the segment starts (inclusive).
  final int start;

  /// UTF-16 index where the segment ends (exclusive).
  final int end;

  /// The segment content.
  final String text;

  @override
  String toString() => 'IcuSegment($start..$end: $text)';
}

/// Locale-aware text segmentation — STABLE.
///
/// Equivalent to ECMA-402's `Intl.Segmenter`. Three constructors:
///
///   * `.grapheme()` — user-perceived characters (combining marks, ZWJ
///     emoji like 👨‍👩‍👧, regional-indicator pairs like 🇯🇵)
///   * `.word(locale: ...)` — word boundaries; locale matters for CJK
///     where dictionaries / LSTM models drive segmentation
///   * `.sentence(locale: ...)` — sentence boundaries
///
/// For line-breaking (CSS `line-break`-style), see [IcuLineSegmenter].
final class IcuSegmenter {
  IcuSegmenter._grapheme(this._grapheme)
    : _kind = _SegmenterKind.grapheme,
      _word = null,
      _sentence = null;

  IcuSegmenter._word(this._word)
    : _kind = _SegmenterKind.word,
      _grapheme = null,
      _sentence = null;

  IcuSegmenter._sentence(this._sentence)
    : _kind = _SegmenterKind.sentence,
      _grapheme = null,
      _word = null;

  /// Grapheme-cluster segmenter. Locale-independent.
  factory IcuSegmenter.grapheme() {
    try {
      return IcuSegmenter._grapheme(dispatch.graphemeClusterSegmenterDefault());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Grapheme segmenter unavailable: $e',
        marker: 'GraphemeClusterSegmenter',
      );
    }
  }

  /// Word-break segmenter. Pass [locale] for content that needs locale-
  /// specific dictionary / LSTM segmentation (CJK, Thai, Khmer, Lao).
  factory IcuSegmenter.word({String? locale}) {
    // Parse before the try — a bad tag is a parse error, not missing data.
    final loc = locale == null ? null : IcuLocale.parse(locale);
    try {
      return IcuSegmenter._word(
        loc == null
            ? icu.WordSegmenter.auto()
            : dispatch.wordSegmenterAutoWithContentLocale(locale!, loc.ffi),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Word segmenter unavailable for ${locale ?? "default"}: $e',
        locale: locale,
        marker: 'WordSegmenter',
      );
    }
  }

  /// Sentence-break segmenter. Pass [locale] for content that needs
  /// locale-specific sentence segmentation.
  factory IcuSegmenter.sentence({String? locale}) {
    // Parse before the try — a bad tag is a parse error, not missing data.
    final loc = locale == null ? null : IcuLocale.parse(locale);
    try {
      return IcuSegmenter._sentence(
        loc == null
            ? icu.SentenceSegmenter()
            : dispatch.sentenceSegmenterWithContentLocale(locale!, loc.ffi),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Sentence segmenter unavailable for ${locale ?? "default"}: $e',
        locale: locale,
        marker: 'SentenceSegmenter',
      );
    }
  }
  final _SegmenterKind _kind;
  final icu.GraphemeClusterSegmenter? _grapheme;
  final icu.WordSegmenter? _word;
  final icu.SentenceSegmenter? _sentence;

  /// Iterate segments of [input].
  ///
  /// Yields each segment with its UTF-16 [IcuSegment.start] / [IcuSegment.end]
  /// indices and the segment's text. The returned iterable is single-pass —
  /// iterating it more than once will yield no segments after the first
  /// pass (the underlying ICU4X iterator is consumed).
  Iterable<IcuSegment> segments(String input) sync* {
    if (input.isEmpty) return;
    final iter = _segmentImpl(input);
    var prev = iter.next();
    if (prev < 0) return;
    var next = iter.next();
    while (next >= 0) {
      yield IcuSegment(
        start: prev,
        end: next,
        text: input.substring(prev, next),
      );
      prev = next;
      next = iter.next();
    }
  }

  /// Just the boundary indices, if you don't need substrings.
  List<int> boundaries(String input) {
    if (input.isEmpty) return const [];
    final iter = _segmentImpl(input);
    final result = <int>[];
    var b = iter.next();
    while (b >= 0) {
      result.add(b);
      b = iter.next();
    }
    return result;
  }

  /// Concrete iterator dispatch. Each underlying ICU4X iterator type has
  /// the same shape (`int next()` returning -1 at end), but they're
  /// different generated classes — wrap them in a common shape.
  _IterAdapter _segmentImpl(String input) => switch (_kind) {
    _SegmenterKind.grapheme => _GraphemeIterAdapter(_grapheme!.segment(input)),
    _SegmenterKind.word => _WordIterAdapter(_word!.segment(input)),
    _SegmenterKind.sentence => _SentenceIterAdapter(_sentence!.segment(input)),
  };
}

/// Line-break segmenter — UAX #14 line-break opportunities.
///
/// Use cases: CSS-style line-wrapping in a custom text widget, soft-hyphen
/// insertion, fitting text to a column width.
///
/// Locale matters because line-break rules differ across scripts (e.g.
/// strict CJK breaks vs. permissive line-breaking).
final class IcuLineSegmenter {
  IcuLineSegmenter._(this._ffi);

  /// Auto-select the best implementation for the system (LSTM if available,
  /// dictionary otherwise, simple rules for non-complex scripts).
  factory IcuLineSegmenter.auto() {
    try {
      return IcuLineSegmenter._(icu.LineSegmenter.auto());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Line segmenter unavailable: $e',
        marker: 'LineSegmenter.auto',
      );
    }
  }
  final icu.LineSegmenter _ffi;

  /// Iterate line-break opportunities. Yields the index AFTER each
  /// breakable position; the start of the input (0) is NOT yielded.
  Iterable<int> breakOpportunities(String input) sync* {
    if (input.isEmpty) return;
    final iter = _ffi.segment(input);
    // Skip the leading 0 — ICU4X always yields start-of-string first.
    var b = iter.next();
    if (b == 0) b = iter.next();
    while (b >= 0) {
      yield b;
      b = iter.next();
    }
  }
}

// ---- private dispatch types -------------------------------------------

enum _SegmenterKind { grapheme, word, sentence }

abstract class _IterAdapter {
  int next();
}

class _GraphemeIterAdapter extends _IterAdapter {
  _GraphemeIterAdapter(this._inner);
  final icu.GraphemeClusterBreakIteratorUtf16 _inner;
  @override
  int next() => _inner.next();
}

class _WordIterAdapter extends _IterAdapter {
  _WordIterAdapter(this._inner);
  final icu.WordBreakIteratorUtf16 _inner;
  @override
  int next() => _inner.next();
}

class _SentenceIterAdapter extends _IterAdapter {
  _SentenceIterAdapter(this._inner);
  final icu.SentenceBreakIteratorUtf16 _inner;
  @override
  int next() => _inner.next();
}
