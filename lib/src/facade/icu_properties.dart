import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Common Unicode binary properties.
///
/// Mirrors the most-used `icu::properties` binary properties. The full
/// surface includes ~50 properties; this enum covers the ones most apps
/// use (Latin letter classification, emoji classification, IDStart for
/// programming-language identifier rules, whitespace, etc.).
///
/// For properties NOT in this enum, fall back to `IcuPropertySet` (which
/// uses a string-keyed lookup) or use the codepoint property directly via
/// the underlying ICU4X API.
enum IcuBinaryProperty {
  /// Letters and letter-like marks (UCD `Alphabetic`).
  alphabetic,

  /// Alphabetic plus decimal digits (POSIX-style `alnum`).
  alnum,

  /// ASCII hex digits only: `0-9`, `A-F`, `a-f`.
  asciiHexDigit,

  /// Bidi control characters (LRM, RLM, embedding/override marks).
  bidiControl,

  /// Mirrored in right-to-left text (e.g. parentheses, brackets).
  bidiMirrored,

  /// Horizontal whitespace: space and tab (POSIX-style `blank`).
  blank,

  /// Has a case — uppercase, lowercase, or titlecase letters.
  cased,

  /// Ignored when determining casing context (e.g. apostrophes, combining marks).
  caseIgnorable,

  /// Dash punctuation (hyphen, en/em dash, minus, ...).
  dash,

  /// Should render invisibly when unsupported (ZWJ, variation selectors, ...).
  defaultIgnorableCodePoint,

  /// Deprecated by the Unicode standard; use is discouraged.
  deprecated,

  /// Modifies the meaning of another character (accents, tone marks).
  diacritic,

  /// Emoji character (UTS #51 `Emoji`).
  emoji,

  /// Component of emoji sequences (skin tones, regional indicators, keycap parts).
  emojiComponent,

  /// Emoji skin-tone modifier (U+1F3FB..U+1F3FF).
  emojiModifier,

  /// Emoji that can take a skin-tone modifier.
  emojiModifierBase,

  /// Rendered emoji-style (color) by default rather than as text.
  emojiPresentation,

  /// Pictographic symbol, including all current and future emoji (drives ZWJ segmentation).
  extendedPictographic,

  /// Extends or repeats the preceding character (length marks, iteration marks).
  extender,

  /// Visible character — anything but whitespace and controls (POSIX-style `graph`).
  graph,

  /// Can serve as the base of a grapheme cluster.
  graphemeBase,

  /// Extends a grapheme cluster (combining marks and their kin).
  graphemeExtend,

  /// Hex digits, including their fullwidth forms.
  hexDigit,

  /// Valid after the first character of a programming-language identifier (UAX #31).
  idContinue,

  /// Valid as the first character of a programming-language identifier (UAX #31).
  idStart,

  /// CJK-style ideograph.
  ideographic,

  /// Join controls: ZWJ (U+200D) and ZWNJ (U+200C).
  joinControl,

  /// Lowercase letters (UCD `Lowercase`).
  lowercase,

  /// Mathematical symbols and operators.
  math,

  /// Permanently unassigned noncharacter (U+FDD0..U+FDEF, U+xFFFE/U+xFFFF).
  noncharacterCodePoint,

  /// Reserved for pattern syntax (UAX #31), e.g. ASCII punctuation.
  patternSyntax,

  /// Whitespace as understood by pattern languages (UAX #31).
  patternWhiteSpace,

  /// Printable — [graph] plus space characters (POSIX-style `print`).
  print,

  /// Quotation marks, in all their locale-specific shapes.
  quotationMark,

  /// CJK radical (component of ideographs).
  radical,

  /// Regional-indicator letters U+1F1E6..U+1F1FF (flag emoji pairs).
  regionalIndicator,

  /// Terminates a sentence (`.`, `!`, `?`, and equivalents).
  sentenceTerminal,

  /// The dot disappears under a diacritic (`i`, `j`, and kin).
  softDotted,

  /// Terminates a clause or sentence (includes commas, colons).
  terminalPunctuation,

  /// CJK unified ideograph.
  unifiedIdeograph,

  /// Uppercase letters (UCD `Uppercase`).
  uppercase,

  /// Variation selector (picks a glyph variant of the preceding character).
  variationSelector,

  /// Whitespace (UCD `White_Space`) — spaces, tabs, newlines.
  whiteSpace,

  /// Identifier-continue closed under NFKC normalization (UAX #31 `XID_Continue`).
  xidContinue,

  /// Identifier-start closed under NFKC normalization (UAX #31 `XID_Start`).
  xidStart,
}

/// Static helpers for one-shot Unicode property lookups.
///
/// For repeated lookups of the same property, use [IcuPropertySet] —
/// it caches the property data and is faster.
final class IcuProperties {
  IcuProperties._();

  /// True if [codePoint] has the binary [property].
  static bool has(int codePoint, IcuBinaryProperty property) =>
      _checkChar(codePoint, property);

  // ---- common convenience accessors -----------------------------------

  /// True if [cp] is a letter or letter-like mark (`Alphabetic`).
  static bool isAlphabetic(int cp) =>
      icu.CodePointSetData.alphabeticForChar(cp);

  /// True if [cp] is a lowercase letter.
  static bool isLowercase(int cp) => icu.CodePointSetData.lowercaseForChar(cp);

  /// True if [cp] is an uppercase letter.
  static bool isUppercase(int cp) => icu.CodePointSetData.uppercaseForChar(cp);

  /// True if [cp] is whitespace (`White_Space`).
  static bool isWhitespace(int cp) =>
      icu.CodePointSetData.whiteSpaceForChar(cp);

  /// True if [cp] is alphanumeric (`alnum` — letters plus decimal digits).
  static bool isDigit(int cp) => icu.CodePointSetData.alnumForChar(cp);

  /// True if [cp] is a hex digit (including fullwidth forms).
  static bool isHexDigit(int cp) => icu.CodePointSetData.hexDigitForChar(cp);

  /// True if [cp] is an emoji character (UTS #51).
  static bool isEmoji(int cp) => icu.CodePointSetData.emojiForChar(cp);

  /// True if [cp] renders emoji-style (color) by default.
  static bool isEmojiPresentation(int cp) =>
      icu.CodePointSetData.emojiPresentationForChar(cp);

  /// True if [cp] can start a programming-language identifier (UAX #31).
  static bool isIdStart(int cp) => icu.CodePointSetData.idStartForChar(cp);

  /// True if [cp] can continue a programming-language identifier (UAX #31).
  static bool isIdContinue(int cp) =>
      icu.CodePointSetData.idContinueForChar(cp);

  /// True if [cp] can start an identifier under NFKC-closure (`XID_Start`).
  static bool isXidStart(int cp) => icu.CodePointSetData.xidStartForChar(cp);

  /// True if [cp] can continue an identifier under NFKC-closure (`XID_Continue`).
  static bool isXidContinue(int cp) =>
      icu.CodePointSetData.xidContinueForChar(cp);
}

/// Reusable Unicode-property set. Build once, query many times.
final class IcuPropertySet {
  IcuPropertySet._(this._ffi);

  /// Build the queryable set for the binary [property].
  factory IcuPropertySet.forBinary(IcuBinaryProperty property) {
    try {
      return IcuPropertySet._(_buildSet(property));
    } catch (e) {
      throw IcuDataError(
        'Property set unavailable for ${property.name}: $e',
        marker: 'CodePointSetData.${property.name}',
      );
    }
  }
  final icu.CodePointSetData _ffi;

  /// True if [codePoint] is in this set.
  bool contains(int codePoint) => _ffi.contains(codePoint);
}

bool _checkChar(int cp, IcuBinaryProperty property) => switch (property) {
  IcuBinaryProperty.alphabetic => icu.CodePointSetData.alphabeticForChar(cp),
  IcuBinaryProperty.alnum => icu.CodePointSetData.alnumForChar(cp),
  IcuBinaryProperty.asciiHexDigit => icu.CodePointSetData.asciiHexDigitForChar(
    cp,
  ),
  IcuBinaryProperty.bidiControl => icu.CodePointSetData.bidiControlForChar(cp),
  IcuBinaryProperty.bidiMirrored => icu.CodePointSetData.bidiMirroredForChar(
    cp,
  ),
  IcuBinaryProperty.blank => icu.CodePointSetData.blankForChar(cp),
  IcuBinaryProperty.cased => icu.CodePointSetData.casedForChar(cp),
  IcuBinaryProperty.caseIgnorable => icu.CodePointSetData.caseIgnorableForChar(
    cp,
  ),
  IcuBinaryProperty.dash => icu.CodePointSetData.dashForChar(cp),
  IcuBinaryProperty.defaultIgnorableCodePoint =>
    icu.CodePointSetData.defaultIgnorableCodePointForChar(cp),
  IcuBinaryProperty.deprecated => icu.CodePointSetData.deprecatedForChar(cp),
  IcuBinaryProperty.diacritic => icu.CodePointSetData.diacriticForChar(cp),
  IcuBinaryProperty.emoji => icu.CodePointSetData.emojiForChar(cp),
  IcuBinaryProperty.emojiComponent =>
    icu.CodePointSetData.emojiComponentForChar(cp),
  IcuBinaryProperty.emojiModifier => icu.CodePointSetData.emojiModifierForChar(
    cp,
  ),
  IcuBinaryProperty.emojiModifierBase =>
    icu.CodePointSetData.emojiModifierBaseForChar(cp),
  IcuBinaryProperty.emojiPresentation =>
    icu.CodePointSetData.emojiPresentationForChar(cp),
  IcuBinaryProperty.extendedPictographic =>
    icu.CodePointSetData.extendedPictographicForChar(cp),
  IcuBinaryProperty.extender => icu.CodePointSetData.extenderForChar(cp),
  IcuBinaryProperty.graph => icu.CodePointSetData.graphForChar(cp),
  IcuBinaryProperty.graphemeBase => icu.CodePointSetData.graphemeBaseForChar(
    cp,
  ),
  IcuBinaryProperty.graphemeExtend =>
    icu.CodePointSetData.graphemeExtendForChar(cp),
  IcuBinaryProperty.hexDigit => icu.CodePointSetData.hexDigitForChar(cp),
  IcuBinaryProperty.idContinue => icu.CodePointSetData.idContinueForChar(cp),
  IcuBinaryProperty.idStart => icu.CodePointSetData.idStartForChar(cp),
  IcuBinaryProperty.ideographic => icu.CodePointSetData.ideographicForChar(cp),
  IcuBinaryProperty.joinControl => icu.CodePointSetData.joinControlForChar(cp),
  IcuBinaryProperty.lowercase => icu.CodePointSetData.lowercaseForChar(cp),
  IcuBinaryProperty.math => icu.CodePointSetData.mathForChar(cp),
  IcuBinaryProperty.noncharacterCodePoint =>
    icu.CodePointSetData.noncharacterCodePointForChar(cp),
  IcuBinaryProperty.patternSyntax => icu.CodePointSetData.patternSyntaxForChar(
    cp,
  ),
  IcuBinaryProperty.patternWhiteSpace =>
    icu.CodePointSetData.patternWhiteSpaceForChar(cp),
  IcuBinaryProperty.print => icu.CodePointSetData.printForChar(cp),
  IcuBinaryProperty.quotationMark => icu.CodePointSetData.quotationMarkForChar(
    cp,
  ),
  IcuBinaryProperty.radical => icu.CodePointSetData.radicalForChar(cp),
  IcuBinaryProperty.regionalIndicator =>
    icu.CodePointSetData.regionalIndicatorForChar(cp),
  IcuBinaryProperty.sentenceTerminal =>
    icu.CodePointSetData.sentenceTerminalForChar(cp),
  IcuBinaryProperty.softDotted => icu.CodePointSetData.softDottedForChar(cp),
  IcuBinaryProperty.terminalPunctuation =>
    icu.CodePointSetData.terminalPunctuationForChar(cp),
  IcuBinaryProperty.unifiedIdeograph =>
    icu.CodePointSetData.unifiedIdeographForChar(cp),
  IcuBinaryProperty.uppercase => icu.CodePointSetData.uppercaseForChar(cp),
  IcuBinaryProperty.variationSelector =>
    icu.CodePointSetData.variationSelectorForChar(cp),
  IcuBinaryProperty.whiteSpace => icu.CodePointSetData.whiteSpaceForChar(cp),
  IcuBinaryProperty.xidContinue => icu.CodePointSetData.xidContinueForChar(cp),
  IcuBinaryProperty.xidStart => icu.CodePointSetData.xidStartForChar(cp),
};

icu.CodePointSetData _buildSet(
  IcuBinaryProperty property,
) => switch (property) {
  IcuBinaryProperty.alphabetic => dispatch.codePointSetDataAlphabetic(),
  IcuBinaryProperty.alnum => dispatch.codePointSetDataAlnum(),
  IcuBinaryProperty.asciiHexDigit => dispatch.codePointSetDataAsciiHexDigit(),
  IcuBinaryProperty.bidiControl => dispatch.codePointSetDataBidiControl(),
  IcuBinaryProperty.bidiMirrored => dispatch.codePointSetDataBidiMirrored(),
  IcuBinaryProperty.blank => dispatch.codePointSetDataBlank(),
  IcuBinaryProperty.cased => dispatch.codePointSetDataCased(),
  IcuBinaryProperty.caseIgnorable => dispatch.codePointSetDataCaseIgnorable(),
  IcuBinaryProperty.dash => dispatch.codePointSetDataDash(),
  IcuBinaryProperty.defaultIgnorableCodePoint =>
    dispatch.codePointSetDataDefaultIgnorableCodePoint(),
  IcuBinaryProperty.deprecated => dispatch.codePointSetDataDeprecated(),
  IcuBinaryProperty.diacritic => dispatch.codePointSetDataDiacritic(),
  IcuBinaryProperty.emoji => dispatch.codePointSetDataEmoji(),
  IcuBinaryProperty.emojiComponent => dispatch.codePointSetDataEmojiComponent(),
  IcuBinaryProperty.emojiModifier => dispatch.codePointSetDataEmojiModifier(),
  IcuBinaryProperty.emojiModifierBase =>
    dispatch.codePointSetDataEmojiModifierBase(),
  IcuBinaryProperty.emojiPresentation =>
    dispatch.codePointSetDataEmojiPresentation(),
  IcuBinaryProperty.extendedPictographic =>
    dispatch.codePointSetDataExtendedPictographic(),
  IcuBinaryProperty.extender => dispatch.codePointSetDataExtender(),
  IcuBinaryProperty.graph => dispatch.codePointSetDataGraph(),
  IcuBinaryProperty.graphemeBase => dispatch.codePointSetDataGraphemeBase(),
  IcuBinaryProperty.graphemeExtend => dispatch.codePointSetDataGraphemeExtend(),
  IcuBinaryProperty.hexDigit => dispatch.codePointSetDataHexDigit(),
  IcuBinaryProperty.idContinue => dispatch.codePointSetDataIdContinue(),
  IcuBinaryProperty.idStart => dispatch.codePointSetDataIdStart(),
  IcuBinaryProperty.ideographic => dispatch.codePointSetDataIdeographic(),
  IcuBinaryProperty.joinControl => dispatch.codePointSetDataJoinControl(),
  IcuBinaryProperty.lowercase => dispatch.codePointSetDataLowercase(),
  IcuBinaryProperty.math => dispatch.codePointSetDataMath(),
  IcuBinaryProperty.noncharacterCodePoint =>
    dispatch.codePointSetDataNoncharacterCodePoint(),
  IcuBinaryProperty.patternSyntax => dispatch.codePointSetDataPatternSyntax(),
  IcuBinaryProperty.patternWhiteSpace =>
    dispatch.codePointSetDataPatternWhiteSpace(),
  IcuBinaryProperty.print => dispatch.codePointSetDataPrint(),
  IcuBinaryProperty.quotationMark => dispatch.codePointSetDataQuotationMark(),
  IcuBinaryProperty.radical => dispatch.codePointSetDataRadical(),
  IcuBinaryProperty.regionalIndicator =>
    dispatch.codePointSetDataRegionalIndicator(),
  IcuBinaryProperty.sentenceTerminal =>
    dispatch.codePointSetDataSentenceTerminal(),
  IcuBinaryProperty.softDotted => dispatch.codePointSetDataSoftDotted(),
  IcuBinaryProperty.terminalPunctuation =>
    dispatch.codePointSetDataTerminalPunctuation(),
  IcuBinaryProperty.unifiedIdeograph =>
    dispatch.codePointSetDataUnifiedIdeograph(),
  IcuBinaryProperty.uppercase => dispatch.codePointSetDataUppercase(),
  IcuBinaryProperty.variationSelector =>
    dispatch.codePointSetDataVariationSelector(),
  IcuBinaryProperty.whiteSpace => dispatch.codePointSetDataWhiteSpace(),
  IcuBinaryProperty.xidContinue => dispatch.codePointSetDataXidContinue(),
  IcuBinaryProperty.xidStart => dispatch.codePointSetDataXidStart(),
};
