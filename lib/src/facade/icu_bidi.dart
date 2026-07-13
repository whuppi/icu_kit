import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Unicode bidirectional algorithm — STABLE (UAX #9).
///
/// Computes paragraph direction + per-character embedding levels +
/// reorders text for visual rendering.
///
/// Example:
///
/// ```dart
/// final bidi = IcuBidi();
/// final analysis = bidi.analyze('Hello مرحبا world');
/// final paragraph = analysis.paragraph(0)!;
/// print(paragraph.direction);    // IcuBidiDirection.mixed
/// print(paragraph.reorderLine(0, paragraph.size));
/// ```
final class IcuBidi {
  IcuBidi._(this._ffi);

  /// Create a bidi analyzer.
  ///
  /// Throws [IcuDataError] when bidi data is unavailable.
  factory IcuBidi() {
    try {
      return IcuBidi._(dispatch.bidiDefault());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError('Bidi unavailable: $e', marker: 'Bidi');
    }
  }
  final icu.Bidi _ffi;

  /// Analyze [text] for bidi properties.
  ///
  /// [defaultLevel] is the embedding level for paragraphs whose direction
  /// can't be determined (no strong characters). Pass `0` for LTR-default,
  /// `1` for RTL-default, or omit for the algorithm's auto detection.
  IcuBidiAnalysis analyze(String text, {int? defaultLevel}) {
    final info = _ffi.forText(text, defaultLevel);
    return IcuBidiAnalysis._(info, text);
  }

  /// Reorder a sequence of embedding levels into a visual-order index map.
  ///
  /// Returns a list `map` where `map[visualIndex] = logicalIndex`. Used
  /// for UAX #9 conformance verification (the `reorder_visual` step
  /// matches the IdnaTestV2 / BidiCharacterTest visual-order column).
  ///
  /// Levels must be in the range 0..125 (UAX #9 max explicit depth).
  /// Higher values produce undefined results.
  List<int> reorderVisual(List<int> levels) {
    final map = _ffi.reorderVisual(levels);
    return List<int>.generate(map.length, (i) => map[i]);
  }

  /// True if [level] is an RTL embedding level (odd levels are RTL).
  static bool levelIsRtl(int level) => icu.Bidi.levelIsRtl(level);

  /// True if [level] is an LTR embedding level (even levels are LTR).
  static bool levelIsLtr(int level) => icu.Bidi.levelIsLtr(level);

  /// The default RTL embedding level (1).
  static int get rtlLevel => icu.Bidi.levelRtl();

  /// The default LTR embedding level (0).
  static int get ltrLevel => icu.Bidi.levelLtr();
}

/// One bidi analysis of a multi-paragraph text. Owns the per-character
/// embedding levels and the paragraph index.
final class IcuBidiAnalysis {
  IcuBidiAnalysis._(this._ffi, this.text);
  final icu.BidiInfo _ffi;

  /// The analyzed text.
  final String text;

  /// Number of paragraphs in the analyzed text.
  int get paragraphCount => _ffi.paragraphCount;

  /// Total UTF-16 size of the analyzed text.
  int get size => _ffi.size;

  /// Embedding level at character position [pos] (UTF-16 code unit index).
  int levelAt(int pos) => _ffi.levelAt(pos);

  /// Get the [n]-th paragraph (0-based). Returns null if [n] >= paragraphCount.
  IcuBidiParagraph? paragraph(int n) {
    final p = _ffi.paragraphAt(n);
    if (p == null) return null;
    return IcuBidiParagraph._(p);
  }
}

/// One paragraph in a bidi analysis.
final class IcuBidiParagraph {
  IcuBidiParagraph._(this._ffi);
  final icu.BidiParagraph _ffi;

  /// LTR / RTL / mixed direction of this paragraph.
  IcuBidiDirection get direction => switch (_ffi.direction) {
    icu.BidiDirection.ltr => IcuBidiDirection.ltr,
    icu.BidiDirection.rtl => IcuBidiDirection.rtl,
    icu.BidiDirection.mixed => IcuBidiDirection.mixed,
  };

  /// Resolved paragraph embedding level per UAX #9 BD4. Returns 0 for
  /// an LTR-base paragraph, 1 for RTL-base. Matches UCD
  /// BidiCharacterTest.txt column 2.
  int get level => _ffi.level;

  /// Per-character reordered level at byte position [pos], computed
  /// across the full paragraph (UAX #9 rules through L2 inclusive).
  /// Differs from [levelAt] which returns the BD2-X10 level (before L2).
  /// Matches UCD BidiCharacterTest.txt column 3.
  int reorderedLevelAt(int pos) => _ffi.reorderedLevelAt(pos);

  /// UTF-16 size of this paragraph.
  int get size => _ffi.size;

  /// UTF-16 start index of this paragraph in the parent text.
  int get rangeStart => _ffi.rangeStart;

  /// UTF-16 end index of this paragraph in the parent text.
  int get rangeEnd => _ffi.rangeEnd;

  /// Embedding level at character position [pos] (UTF-16 code unit index,
  /// relative to the parent text).
  int levelAt(int pos) => _ffi.levelAt(pos);

  /// Reorder a line of this paragraph from logical order to visual order.
  ///
  /// [start] and [end] are UTF-16 indices into the parent text, identifying
  /// a line within this paragraph. Returns null if the range is invalid.
  String? reorderLine(int start, int end) => _ffi.reorderLine(start, end);
}

/// Direction of a bidi paragraph.
enum IcuBidiDirection {
  /// Entirely left-to-right.
  ltr,

  /// Entirely right-to-left.
  rtl,

  /// Contains both directions.
  mixed,
}
