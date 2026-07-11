// Mirror of the native `CodePointSetData` binding's static `...ForChar`
// lookups (one per binary property) plus the instance `contains` used by
// `IcuPropertySet`, over the Diplomat JS `CodePointSetData` class. JS
// method names match the Dart static names exactly (verified via the
// pre-merge web facade's computed `'${property}ForChar'` dispatch).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';
import 'js_bool.dart';

/// Web mirror of the FFI `CodePointSetData`.
extension type CodePointSetData._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory CodePointSetData.fromDispatch(JSObject o) = CodePointSetData._;

  /// True if code point [cp] is in this set.
  bool contains(int cp) =>
      readJsBool(_self.callMethod<JSAny?>('contains'.toJS, cp.toJS));

  /// `Alphabetic` for code point [ch].
  static bool alphabeticForChar(int ch) => _forChar('alphabeticForChar', ch);

  /// `Alnum` for code point [ch].
  static bool alnumForChar(int ch) => _forChar('alnumForChar', ch);

  /// `Ascii_Hex_Digit` for code point [ch].
  static bool asciiHexDigitForChar(int ch) =>
      _forChar('asciiHexDigitForChar', ch);

  /// `Bidi_Control` for code point [ch].
  static bool bidiControlForChar(int ch) => _forChar('bidiControlForChar', ch);

  /// `Bidi_Mirrored` for code point [ch].
  static bool bidiMirroredForChar(int ch) =>
      _forChar('bidiMirroredForChar', ch);

  /// `Blank` for code point [ch].
  static bool blankForChar(int ch) => _forChar('blankForChar', ch);

  /// `Cased` for code point [ch].
  static bool casedForChar(int ch) => _forChar('casedForChar', ch);

  /// `Case_Ignorable` for code point [ch].
  static bool caseIgnorableForChar(int ch) =>
      _forChar('caseIgnorableForChar', ch);

  /// `Dash` for code point [ch].
  static bool dashForChar(int ch) => _forChar('dashForChar', ch);

  /// `Default_Ignorable_Code_Point` for code point [ch].
  static bool defaultIgnorableCodePointForChar(int ch) =>
      _forChar('defaultIgnorableCodePointForChar', ch);

  /// `Deprecated` for code point [ch].
  static bool deprecatedForChar(int ch) => _forChar('deprecatedForChar', ch);

  /// `Diacritic` for code point [ch].
  static bool diacriticForChar(int ch) => _forChar('diacriticForChar', ch);

  /// `Emoji` for code point [ch].
  static bool emojiForChar(int ch) => _forChar('emojiForChar', ch);

  /// `Emoji_Component` for code point [ch].
  static bool emojiComponentForChar(int ch) =>
      _forChar('emojiComponentForChar', ch);

  /// `Emoji_Modifier` for code point [ch].
  static bool emojiModifierForChar(int ch) =>
      _forChar('emojiModifierForChar', ch);

  /// `Emoji_Modifier_Base` for code point [ch].
  static bool emojiModifierBaseForChar(int ch) =>
      _forChar('emojiModifierBaseForChar', ch);

  /// `Emoji_Presentation` for code point [ch].
  static bool emojiPresentationForChar(int ch) =>
      _forChar('emojiPresentationForChar', ch);

  /// `Extended_Pictographic` for code point [ch].
  static bool extendedPictographicForChar(int ch) =>
      _forChar('extendedPictographicForChar', ch);

  /// `Extender` for code point [ch].
  static bool extenderForChar(int ch) => _forChar('extenderForChar', ch);

  /// `Graph` for code point [ch].
  static bool graphForChar(int ch) => _forChar('graphForChar', ch);

  /// `Grapheme_Base` for code point [ch].
  static bool graphemeBaseForChar(int ch) =>
      _forChar('graphemeBaseForChar', ch);

  /// `Grapheme_Extend` for code point [ch].
  static bool graphemeExtendForChar(int ch) =>
      _forChar('graphemeExtendForChar', ch);

  /// `Hex_Digit` for code point [ch].
  static bool hexDigitForChar(int ch) => _forChar('hexDigitForChar', ch);

  /// `Id_Continue` for code point [ch].
  static bool idContinueForChar(int ch) => _forChar('idContinueForChar', ch);

  /// `Id_Start` for code point [ch].
  static bool idStartForChar(int ch) => _forChar('idStartForChar', ch);

  /// `Ideographic` for code point [ch].
  static bool ideographicForChar(int ch) => _forChar('ideographicForChar', ch);

  /// `Join_Control` for code point [ch].
  static bool joinControlForChar(int ch) => _forChar('joinControlForChar', ch);

  /// `Lowercase` for code point [ch].
  static bool lowercaseForChar(int ch) => _forChar('lowercaseForChar', ch);

  /// `Math` for code point [ch].
  static bool mathForChar(int ch) => _forChar('mathForChar', ch);

  /// `Noncharacter_Code_Point` for code point [ch].
  static bool noncharacterCodePointForChar(int ch) =>
      _forChar('noncharacterCodePointForChar', ch);

  /// `Pattern_Syntax` for code point [ch].
  static bool patternSyntaxForChar(int ch) =>
      _forChar('patternSyntaxForChar', ch);

  /// `Pattern_White_Space` for code point [ch].
  static bool patternWhiteSpaceForChar(int ch) =>
      _forChar('patternWhiteSpaceForChar', ch);

  /// `Print` for code point [ch].
  static bool printForChar(int ch) => _forChar('printForChar', ch);

  /// `Quotation_Mark` for code point [ch].
  static bool quotationMarkForChar(int ch) =>
      _forChar('quotationMarkForChar', ch);

  /// `Radical` for code point [ch].
  static bool radicalForChar(int ch) => _forChar('radicalForChar', ch);

  /// `Regional_Indicator` for code point [ch].
  static bool regionalIndicatorForChar(int ch) =>
      _forChar('regionalIndicatorForChar', ch);

  /// `Sentence_Terminal` for code point [ch].
  static bool sentenceTerminalForChar(int ch) =>
      _forChar('sentenceTerminalForChar', ch);

  /// `Soft_Dotted` for code point [ch].
  static bool softDottedForChar(int ch) => _forChar('softDottedForChar', ch);

  /// `Terminal_Punctuation` for code point [ch].
  static bool terminalPunctuationForChar(int ch) =>
      _forChar('terminalPunctuationForChar', ch);

  /// `Unified_Ideograph` for code point [ch].
  static bool unifiedIdeographForChar(int ch) =>
      _forChar('unifiedIdeographForChar', ch);

  /// `Uppercase` for code point [ch].
  static bool uppercaseForChar(int ch) => _forChar('uppercaseForChar', ch);

  /// `Variation_Selector` for code point [ch].
  static bool variationSelectorForChar(int ch) =>
      _forChar('variationSelectorForChar', ch);

  /// `White_Space` for code point [ch].
  static bool whiteSpaceForChar(int ch) => _forChar('whiteSpaceForChar', ch);

  /// `Xid_Continue` for code point [ch].
  static bool xidContinueForChar(int ch) => _forChar('xidContinueForChar', ch);

  /// `Xid_Start` for code point [ch].
  static bool xidStartForChar(int ch) => _forChar('xidStartForChar', ch);

  static bool _forChar(String jsMethod, int ch) {
    final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
    return readJsBool(cls.callMethod<JSAny?>(jsMethod.toJS, ch.toJS));
  }
}
