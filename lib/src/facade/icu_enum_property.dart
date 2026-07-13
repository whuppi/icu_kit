import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Unicode General Category for one code point.
///
/// Mirrors ICU4X's `GeneralCategory` (30 variants — Letter / Mark /
/// Number / Punctuation / Symbol / Separator / Other). This is what
/// regex `\p{L}`, `\p{N}`, etc. resolve against.
enum IcuGeneralCategory {
  /// `Cn` — unassigned or noncharacter code point.
  unassigned,

  /// `Lu` — uppercase letter.
  uppercaseLetter,

  /// `Ll` — lowercase letter.
  lowercaseLetter,

  /// `Lt` — titlecase letter (e.g. `ǅ`).
  titlecaseLetter,

  /// `Lm` — modifier letter (spacing letter-like modifiers).
  modifierLetter,

  /// `Lo` — letter with no case (CJK, Arabic, Devanagari, ...).
  otherLetter,

  /// `Mn` — nonspacing combining mark (accents).
  nonspacingMark,

  /// `Mc` — spacing combining mark (takes horizontal space).
  spacingMark,

  /// `Me` — enclosing mark (circles, squares around a base).
  enclosingMark,

  /// `Nd` — decimal digit usable in a positional system.
  decimalNumber,

  /// `Nl` — letter-like numeral (Roman numerals).
  letterNumber,

  /// `No` — other numeral (fractions, superscripts).
  otherNumber,

  /// `Zs` — space separator (space, NBSP, em space).
  spaceSeparator,

  /// `Zl` — line separator (U+2028).
  lineSeparator,

  /// `Zp` — paragraph separator (U+2029).
  paragraphSeparator,

  /// `Cc` — C0/C1 control code.
  control,

  /// `Cf` — invisible format character (ZWJ, soft hyphen, bidi marks).
  format,

  /// `Co` — private-use code point.
  privateUse,

  /// `Cs` — UTF-16 surrogate code unit.
  surrogate,

  /// `Pd` — dash punctuation.
  dashPunctuation,

  /// `Ps` — opening punctuation (`(`, `[`, `{`).
  openPunctuation,

  /// `Pe` — closing punctuation (`)`, `]`, `}`).
  closePunctuation,

  /// `Pc` — connector punctuation (`_`).
  connectorPunctuation,

  /// `Pi` — initial quote punctuation (`«`, `‘`).
  initialPunctuation,

  /// `Pf` — final quote punctuation (`»`, `’`).
  finalPunctuation,

  /// `Po` — other punctuation (`!`, `"`, `#`, `%`, ...).
  otherPunctuation,

  /// `Sm` — mathematical symbol (`+`, `=`, `∑`).
  mathSymbol,

  /// `Sc` — currency symbol (`\$`, `€`, `¥`).
  currencySymbol,

  /// `Sk` — modifier symbol (spacing accents, `^`).
  modifierSymbol,

  /// `So` — other symbol (arrows, dingbats, emoji-as-symbols).
  otherSymbol;

  /// Convenience: is this category a Letter (any of L*)?
  bool get isLetter =>
      index >= IcuGeneralCategory.uppercaseLetter.index &&
      index <= IcuGeneralCategory.otherLetter.index;

  /// Convenience: is this category a Mark (any of M*)?
  bool get isMark =>
      index >= IcuGeneralCategory.nonspacingMark.index &&
      index <= IcuGeneralCategory.enclosingMark.index;

  /// Convenience: is this category a Number (any of N*)?
  bool get isNumber =>
      index >= IcuGeneralCategory.decimalNumber.index &&
      index <= IcuGeneralCategory.otherNumber.index;

  /// Convenience: is this category Punctuation (any of P*)?
  bool get isPunctuation =>
      index >= IcuGeneralCategory.dashPunctuation.index &&
      index <= IcuGeneralCategory.otherPunctuation.index;

  /// Convenience: is this category a Symbol (any of S*)?
  bool get isSymbol =>
      index >= IcuGeneralCategory.mathSymbol.index &&
      index <= IcuGeneralCategory.otherSymbol.index;

  /// Convenience: is this category a Separator (any of Z*)?
  bool get isSeparator =>
      index >= IcuGeneralCategory.spaceSeparator.index &&
      index <= IcuGeneralCategory.paragraphSeparator.index;
}

/// General Category lookup map — STABLE.
final class IcuGeneralCategoryMap {
  IcuGeneralCategoryMap._(this._ffi);

  /// Build the General Category lookup map.
  factory IcuGeneralCategoryMap() {
    try {
      return IcuGeneralCategoryMap._(
        dispatch.codePointMapData8GeneralCategory(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'GeneralCategory map unavailable: $e',
        marker: 'CodePointMapData8.generalCategory',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// General category for [codePoint]. Returns `unassigned` for code
  /// points outside any defined Unicode block.
  IcuGeneralCategory get(int codePoint) =>
      _decodeGeneralCategory(_ffi[codePoint]);
}

/// Decode the raw integer ICU4X reports for a GeneralCategory codepoint.
///
/// ICU4X's numeric values match its Rust enum (`vendor/icu4x/components/
/// properties/src/props.rs::GeneralCategory`), which are NOT contiguous
/// 0..29: enclosingMark=7, spacingMark=8 (mark values are swapped relative
/// to the order Marks appear in UCD), and the punctuation/symbol values
/// interleave (otherPunctuation=23, mathSymbol=24, currencySymbol=25,
/// modifierSymbol=26, otherSymbol=27, initialPunctuation=28,
/// finalPunctuation=29).
IcuGeneralCategory _decodeGeneralCategory(int value) => switch (value) {
  0 => IcuGeneralCategory.unassigned,
  1 => IcuGeneralCategory.uppercaseLetter,
  2 => IcuGeneralCategory.lowercaseLetter,
  3 => IcuGeneralCategory.titlecaseLetter,
  4 => IcuGeneralCategory.modifierLetter,
  5 => IcuGeneralCategory.otherLetter,
  6 => IcuGeneralCategory.nonspacingMark,
  7 => IcuGeneralCategory.enclosingMark,
  8 => IcuGeneralCategory.spacingMark,
  9 => IcuGeneralCategory.decimalNumber,
  10 => IcuGeneralCategory.letterNumber,
  11 => IcuGeneralCategory.otherNumber,
  12 => IcuGeneralCategory.spaceSeparator,
  13 => IcuGeneralCategory.lineSeparator,
  14 => IcuGeneralCategory.paragraphSeparator,
  15 => IcuGeneralCategory.control,
  16 => IcuGeneralCategory.format,
  17 => IcuGeneralCategory.privateUse,
  18 => IcuGeneralCategory.surrogate,
  19 => IcuGeneralCategory.dashPunctuation,
  20 => IcuGeneralCategory.openPunctuation,
  21 => IcuGeneralCategory.closePunctuation,
  22 => IcuGeneralCategory.connectorPunctuation,
  23 => IcuGeneralCategory.otherPunctuation,
  24 => IcuGeneralCategory.mathSymbol,
  25 => IcuGeneralCategory.currencySymbol,
  26 => IcuGeneralCategory.modifierSymbol,
  27 => IcuGeneralCategory.otherSymbol,
  28 => IcuGeneralCategory.initialPunctuation,
  29 => IcuGeneralCategory.finalPunctuation,
  _ => IcuGeneralCategory.unassigned,
};

/// Script lookup map — STABLE.
///
/// Resolves a code point to its Unicode script (Latin, Cyrillic, Han,
/// Arabic, ...). The script is returned as a numeric code (ICU4X uses
/// these compactly internally); use `IcuPropertyName.script()` —
/// `codeFor` / `nameOf` — to convert codes ↔ names.
final class IcuScriptMap {
  IcuScriptMap._(this._ffi);

  /// Build the Script lookup map.
  factory IcuScriptMap() {
    try {
      return IcuScriptMap._(dispatch.codePointMapData16Script());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Script map unavailable: $e',
        marker: 'CodePointMapData16.script',
      );
    }
  }
  final icu.CodePointMapData16 _ffi;

  /// Numeric script code for [codePoint]. Match against constants in
  /// `Script` (e.g. `Script.latin`, `Script.cyrillic`).
  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Bidi class lookup map — STABLE.
final class IcuBidiClassMap {
  IcuBidiClassMap._(this._ffi);

  /// Build the Bidi Class lookup map.
  factory IcuBidiClassMap() {
    try {
      return IcuBidiClassMap._(dispatch.codePointMapData8BidiClass());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'BidiClass map unavailable: $e',
        marker: 'CodePointMapData8.bidiClass',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Line-break property lookup map — STABLE.
final class IcuLineBreakMap {
  IcuLineBreakMap._(this._ffi);

  /// Build the Line Break property lookup map.
  factory IcuLineBreakMap() {
    try {
      return IcuLineBreakMap._(dispatch.codePointMapData8LineBreak());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'LineBreak map unavailable: $e',
        marker: 'CodePointMapData8.lineBreak',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Word-break property lookup map — STABLE.
final class IcuWordBreakMap {
  IcuWordBreakMap._(this._ffi);

  /// Build the Word Break property lookup map.
  factory IcuWordBreakMap() {
    try {
      return IcuWordBreakMap._(dispatch.codePointMapData8WordBreak());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'WordBreak map unavailable: $e',
        marker: 'CodePointMapData8.wordBreak',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Sentence-break property lookup map — STABLE.
final class IcuSentenceBreakMap {
  IcuSentenceBreakMap._(this._ffi);

  /// Build the Sentence Break property lookup map.
  factory IcuSentenceBreakMap() {
    try {
      return IcuSentenceBreakMap._(dispatch.codePointMapData8SentenceBreak());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'SentenceBreak map unavailable: $e',
        marker: 'CodePointMapData8.sentenceBreak',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Grapheme cluster break property lookup map — STABLE.
final class IcuGraphemeClusterBreakMap {
  IcuGraphemeClusterBreakMap._(this._ffi);

  /// Build the Grapheme Cluster Break property lookup map.
  factory IcuGraphemeClusterBreakMap() {
    try {
      return IcuGraphemeClusterBreakMap._(
        dispatch.codePointMapData8GraphemeClusterBreak(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'GraphemeClusterBreak map unavailable: $e',
        marker: 'CodePointMapData8.graphemeClusterBreak',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// East Asian Width property lookup map — STABLE.
///
/// Useful for layout: characters classified as F (fullwidth) or W (wide)
/// take 2 columns in monospace; H (halfwidth) / Na (narrow) / N (neutral)
/// take 1.
final class IcuEastAsianWidthMap {
  IcuEastAsianWidthMap._(this._ffi);

  /// Build the East Asian Width property lookup map.
  factory IcuEastAsianWidthMap() {
    try {
      return IcuEastAsianWidthMap._(dispatch.codePointMapData8EastAsianWidth());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'EastAsianWidth map unavailable: $e',
        marker: 'CodePointMapData8.eastAsianWidth',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Hangul Syllable Type property lookup map — STABLE.
final class IcuHangulSyllableTypeMap {
  IcuHangulSyllableTypeMap._(this._ffi);

  /// Build the Hangul Syllable Type property lookup map.
  factory IcuHangulSyllableTypeMap() {
    try {
      return IcuHangulSyllableTypeMap._(
        dispatch.codePointMapData8HangulSyllableType(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'HangulSyllableType map unavailable: $e',
        marker: 'CodePointMapData8.hangulSyllableType',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Joining Type property lookup map (Arabic shaping) — STABLE.
final class IcuJoiningTypeMap {
  IcuJoiningTypeMap._(this._ffi);

  /// Build the Joining Type property lookup map.
  factory IcuJoiningTypeMap() {
    try {
      return IcuJoiningTypeMap._(dispatch.codePointMapData8JoiningType());
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'JoiningType map unavailable: $e',
        marker: 'CodePointMapData8.joiningType',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}

/// Canonical Combining Class property lookup map — STABLE.
///
/// Used by Unicode normalization to determine the canonical order of
/// combining marks.
final class IcuCanonicalCombiningClassMap {
  IcuCanonicalCombiningClassMap._(this._ffi);

  /// Build the Canonical Combining Class lookup map.
  factory IcuCanonicalCombiningClassMap() {
    try {
      return IcuCanonicalCombiningClassMap._(
        dispatch.codePointMapData8CanonicalCombiningClass(),
      );
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'CanonicalCombiningClass map unavailable: $e',
        marker: 'CodePointMapData8.canonicalCombiningClass',
      );
    }
  }
  final icu.CodePointMapData8 _ffi;

  /// Numeric property value for [codePoint]. Convert codes ↔ names via
  /// `IcuPropertyName`.
  int get(int codePoint) => _ffi[codePoint];
}
