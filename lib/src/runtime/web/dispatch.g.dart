// AUTO-GENERATED — DO NOT EDIT
//
// Run `fvm dart run tool/regen_dispatch.dart` to regenerate.
//
// Web twin of `../native/dispatch.g.dart` — SAME Dart signatures, typed
// against the js_interop mirrors, so facades compile against either
// resolution of `../dispatch.dart` unchanged. Each method calls the
// corresponding JS Diplomat binding; JS method names are extracted from
// `web_assets/lib/<Class>.mjs` at generation time, so naming exceptions
// (e.g. a `create` prefix on some statics and not others) are handled
// automatically.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'bindings.dart' as icu;
import 'init.dart';

icu.Bidi bidiDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('Bidi'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('Bidi'.toJS);
    return icu.Bidi.fromDispatch(fn.callAsConstructor<JSObject>());
  }
  return icu.Bidi.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p),
  );
}

icu.Calendar calendarDefault(icu.CalendarKind kind) {
  final cls = IcuKit.module.getProperty<JSObject>('Calendar'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('Calendar'.toJS);
    return icu.Calendar.fromDispatch(
      fn.callAsConstructor<JSObject>(kind.toJs()),
    );
  }
  return icu.Calendar.fromDispatch(
    cls.callMethod<JSObject>('newWithProvider'.toJS, p, kind.toJs()),
  );
}

icu.CaseMapper caseMapperDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('CaseMapper'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('CaseMapper'.toJS);
    return icu.CaseMapper.fromDispatch(fn.callAsConstructor<JSObject>());
  }
  return icu.CaseMapper.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p),
  );
}

icu.CodePointMapData16 codePointMapData16Script() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData16'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData16.fromDispatch(
      cls.callMethod<JSObject>('createScript'.toJS),
    );
  }
  return icu.CodePointMapData16.fromDispatch(
    cls.callMethod<JSObject>('createScriptWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8BidiClass() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createBidiClass'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createBidiClassWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8CanonicalCombiningClass() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createCanonicalCombiningClass'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>(
      'createCanonicalCombiningClassWithProvider'.toJS,
      p,
    ),
  );
}

icu.CodePointMapData8 codePointMapData8EastAsianWidth() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createEastAsianWidth'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createEastAsianWidthWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8GeneralCategory() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createGeneralCategory'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createGeneralCategoryWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8GraphemeClusterBreak() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createGraphemeClusterBreak'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createGraphemeClusterBreakWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8HangulSyllableType() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createHangulSyllableType'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createHangulSyllableTypeWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8JoiningType() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createJoiningType'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createJoiningTypeWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8LineBreak() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createLineBreak'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createLineBreakWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8SentenceBreak() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createSentenceBreak'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createSentenceBreakWithProvider'.toJS, p),
  );
}

icu.CodePointMapData8 codePointMapData8WordBreak() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointMapData8'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointMapData8.fromDispatch(
      cls.callMethod<JSObject>('createWordBreak'.toJS),
    );
  }
  return icu.CodePointMapData8.fromDispatch(
    cls.callMethod<JSObject>('createWordBreakWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataAlnum() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createAlnum'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createAlnumWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataAlphabetic() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createAlphabetic'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createAlphabeticWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataAsciiHexDigit() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createAsciiHexDigit'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createAsciiHexDigitWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataBidiControl() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createBidiControl'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createBidiControlWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataBidiMirrored() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createBidiMirrored'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createBidiMirroredWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataBlank() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createBlank'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createBlankWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataCaseIgnorable() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createCaseIgnorable'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createCaseIgnorableWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataCased() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createCased'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createCasedWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataDash() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createDash'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createDashWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataDefaultIgnorableCodePoint() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createDefaultIgnorableCodePoint'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>(
      'createDefaultIgnorableCodePointWithProvider'.toJS,
      p,
    ),
  );
}

icu.CodePointSetData codePointSetDataDeprecated() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createDeprecated'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createDeprecatedWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataDiacritic() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createDiacritic'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createDiacriticWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataEmoji() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createEmoji'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createEmojiWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataEmojiComponent() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createEmojiComponent'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createEmojiComponentWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataEmojiModifier() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createEmojiModifier'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createEmojiModifierWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataEmojiModifierBase() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createEmojiModifierBase'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createEmojiModifierBaseWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataEmojiPresentation() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createEmojiPresentation'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createEmojiPresentationWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataExtendedPictographic() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createExtendedPictographic'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createExtendedPictographicWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataExtender() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createExtender'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createExtenderWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataGraph() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createGraph'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createGraphWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataGraphemeBase() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createGraphemeBase'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createGraphemeBaseWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataGraphemeExtend() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createGraphemeExtend'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createGraphemeExtendWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataHexDigit() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createHexDigit'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createHexDigitWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataIdContinue() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createIdContinue'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createIdContinueWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataIdStart() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createIdStart'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createIdStartWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataIdeographic() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createIdeographic'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createIdeographicWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataJoinControl() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createJoinControl'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createJoinControlWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataLowercase() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createLowercase'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createLowercaseWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataMath() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createMath'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createMathWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataNoncharacterCodePoint() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createNoncharacterCodePoint'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createNoncharacterCodePointWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataPatternSyntax() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createPatternSyntax'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createPatternSyntaxWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataPatternWhiteSpace() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createPatternWhiteSpace'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createPatternWhiteSpaceWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataPrint() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createPrint'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createPrintWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataQuotationMark() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createQuotationMark'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createQuotationMarkWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataRadical() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createRadical'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createRadicalWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataRegionalIndicator() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createRegionalIndicator'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createRegionalIndicatorWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataSentenceTerminal() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createSentenceTerminal'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createSentenceTerminalWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataSoftDotted() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createSoftDotted'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createSoftDottedWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataTerminalPunctuation() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createTerminalPunctuation'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createTerminalPunctuationWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataUnifiedIdeograph() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createUnifiedIdeograph'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createUnifiedIdeographWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataUppercase() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createUppercase'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createUppercaseWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataVariationSelector() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createVariationSelector'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createVariationSelectorWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataWhiteSpace() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createWhiteSpace'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createWhiteSpaceWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataXidContinue() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createXidContinue'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createXidContinueWithProvider'.toJS, p),
  );
}

icu.CodePointSetData codePointSetDataXidStart() {
  final cls = IcuKit.module.getProperty<JSObject>('CodePointSetData'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.CodePointSetData.fromDispatch(
      cls.callMethod<JSObject>('createXidStart'.toJS),
    );
  }
  return icu.CodePointSetData.fromDispatch(
    cls.callMethod<JSObject>('createXidStartWithProvider'.toJS, p),
  );
}

icu.Collator collatorDefault(
  String localeStr,
  icu.Locale locale,
  icu.CollatorOptions options,
) {
  final cls = IcuKit.module.getProperty<JSObject>('Collator'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('Collator'.toJS);
    return icu.Collator.fromDispatch(
      fn.callAsConstructor<JSObject>(locale, options),
    );
  }
  return icu.Collator.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p, locale, options),
  );
}

icu.ComposingNormalizer composingNormalizerNfc() {
  final cls = IcuKit.module.getProperty<JSObject>('ComposingNormalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.ComposingNormalizer.fromDispatch(
      cls.callMethod<JSObject>('createNfc'.toJS),
    );
  }
  return icu.ComposingNormalizer.fromDispatch(
    cls.callMethod<JSObject>('createNfcWithProvider'.toJS, p),
  );
}

icu.ComposingNormalizer composingNormalizerNfkc() {
  final cls = IcuKit.module.getProperty<JSObject>('ComposingNormalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.ComposingNormalizer.fromDispatch(
      cls.callMethod<JSObject>('createNfkc'.toJS),
    );
  }
  return icu.ComposingNormalizer.fromDispatch(
    cls.callMethod<JSObject>('createNfkcWithProvider'.toJS, p),
  );
}

icu.CurrencyFormatter currencyFormatterWithWidth(
  String localeStr,
  icu.Locale locale, {
  icu.CurrencyWidth? width,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('CurrencyFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.CurrencyFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createWithWidth'.toJS,
        locale,
        width?.toJs(),
        groupingStrategy?.toJs(),
      ),
    );
  }
  return icu.CurrencyFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createWithWidthWithProvider'.toJS,
      p,
      locale,
      width?.toJs(),
      groupingStrategy?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterD(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createD'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createDWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterDe(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createDe'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createDeWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterE(
  String localeStr,
  icu.Locale locale, [
  icu.DateTimeLength? length,
]) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>('createE'.toJS, locale, length?.toJs()),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createEWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterM(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createM'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createMWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterMd(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createMd'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createMdWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterMde(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createMde'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createMdeWithProvider'.toJS,
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
    ),
  );
}

icu.DateFormatter dateFormatterY(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createY'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DateFormatter dateFormatterYm(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createYm'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYmWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DateFormatter dateFormatterYmd(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createYmd'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYmdWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DateFormatter dateFormatterYmde(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createYmde'.toJS,
        locale,
        length?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ),
    );
  }
  return icu.DateFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYmdeWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterDet(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createDet'.toJS,
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createDetWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterDt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createDt'.toJS,
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createDtWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterEt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createEt'.toJS,
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createEtWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterMdet(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createMdet'.toJS,
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createMdetWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterMdt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createMdt'.toJS,
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createMdtWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterYmdet(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethodVarArgs<JSObject>('createYmdet'.toJS, [
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ]),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYmdetWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DateTimeFormatter dateTimeFormatterYmdt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('DateTimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DateTimeFormatter.fromDispatch(
      cls.callMethodVarArgs<JSObject>('createYmdt'.toJS, [
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
        yearStyle?.toJs(),
      ]),
    );
  }
  return icu.DateTimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createYmdtWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
      yearStyle?.toJs(),
    ]),
  );
}

icu.DecimalFormatter decimalFormatterWithGroupingStrategy(
  String localeStr,
  icu.Locale locale, [
  icu.DecimalGroupingStrategy? groupingStrategy,
]) {
  final cls = IcuKit.module.getProperty<JSObject>('DecimalFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.DecimalFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createWithGroupingStrategy'.toJS,
        locale,
        groupingStrategy?.toJs(),
      ),
    );
  }
  return icu.DecimalFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createWithGroupingStrategyAndProvider'.toJS,
      p,
      locale,
      groupingStrategy?.toJs(),
    ),
  );
}

icu.DecomposingNormalizer decomposingNormalizerNfd() {
  final cls = IcuKit.module.getProperty<JSObject>('DecomposingNormalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.DecomposingNormalizer.fromDispatch(
      cls.callMethod<JSObject>('createNfd'.toJS),
    );
  }
  return icu.DecomposingNormalizer.fromDispatch(
    cls.callMethod<JSObject>('createNfdWithProvider'.toJS, p),
  );
}

icu.DecomposingNormalizer decomposingNormalizerNfkd() {
  final cls = IcuKit.module.getProperty<JSObject>('DecomposingNormalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.DecomposingNormalizer.fromDispatch(
      cls.callMethod<JSObject>('createNfkd'.toJS),
    );
  }
  return icu.DecomposingNormalizer.fromDispatch(
    cls.callMethod<JSObject>('createNfkdWithProvider'.toJS, p),
  );
}

icu.ExemplarCharacters exemplarCharactersAuxiliary(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ExemplarCharacters'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ExemplarCharacters.fromDispatch(
      cls.callMethod<JSObject>('createAuxiliary'.toJS, locale),
    );
  }
  return icu.ExemplarCharacters.fromDispatch(
    cls.callMethod<JSObject>('createAuxiliaryWithProvider'.toJS, p, locale),
  );
}

icu.ExemplarCharacters exemplarCharactersIndex(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ExemplarCharacters'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ExemplarCharacters.fromDispatch(
      cls.callMethod<JSObject>('createIndex'.toJS, locale),
    );
  }
  return icu.ExemplarCharacters.fromDispatch(
    cls.callMethod<JSObject>('createIndexWithProvider'.toJS, p, locale),
  );
}

icu.ExemplarCharacters exemplarCharactersMain(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ExemplarCharacters'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ExemplarCharacters.fromDispatch(
      cls.callMethod<JSObject>('createMain'.toJS, locale),
    );
  }
  return icu.ExemplarCharacters.fromDispatch(
    cls.callMethod<JSObject>('createMainWithProvider'.toJS, p, locale),
  );
}

icu.ExemplarCharacters exemplarCharactersNumbers(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ExemplarCharacters'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ExemplarCharacters.fromDispatch(
      cls.callMethod<JSObject>('createNumbers'.toJS, locale),
    );
  }
  return icu.ExemplarCharacters.fromDispatch(
    cls.callMethod<JSObject>('createNumbersWithProvider'.toJS, p, locale),
  );
}

icu.ExemplarCharacters exemplarCharactersPunctuation(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ExemplarCharacters'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ExemplarCharacters.fromDispatch(
      cls.callMethod<JSObject>('createPunctuation'.toJS, locale),
    );
  }
  return icu.ExemplarCharacters.fromDispatch(
    cls.callMethod<JSObject>('createPunctuationWithProvider'.toJS, p, locale),
  );
}

icu.GraphemeClusterSegmenter graphemeClusterSegmenterDefault() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'GraphemeClusterSegmenter'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>(
      'GraphemeClusterSegmenter'.toJS,
    );
    return icu.GraphemeClusterSegmenter.fromDispatch(
      fn.callAsConstructor<JSObject>(),
    );
  }
  return icu.GraphemeClusterSegmenter.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p),
  );
}

icu.ListFormatter listFormatterAndWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ListFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ListFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createAndWithLength'.toJS,
        locale,
        length.toJs(),
      ),
    );
  }
  return icu.ListFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createAndWithLengthAndProvider'.toJS,
      p,
      locale,
      length.toJs(),
    ),
  );
}

icu.ListFormatter listFormatterOrWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ListFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ListFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createOrWithLength'.toJS,
        locale,
        length.toJs(),
      ),
    );
  }
  return icu.ListFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createOrWithLengthAndProvider'.toJS,
      p,
      locale,
      length.toJs(),
    ),
  );
}

icu.ListFormatter listFormatterUnitWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final cls = IcuKit.module.getProperty<JSObject>('ListFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ListFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createUnitWithLength'.toJS,
        locale,
        length.toJs(),
      ),
    );
  }
  return icu.ListFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createUnitWithLengthAndProvider'.toJS,
      p,
      locale,
      length.toJs(),
    ),
  );
}

icu.LocaleCanonicalizer localeCanonicalizerDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleCanonicalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>(
      'LocaleCanonicalizer'.toJS,
    );
    return icu.LocaleCanonicalizer.fromDispatch(
      fn.callAsConstructor<JSObject>(),
    );
  }
  return icu.LocaleCanonicalizer.fromDispatch(
    cls.callMethod<JSObject>('withProvider'.toJS, p),
  );
}

icu.LocaleCanonicalizer localeCanonicalizerExtended() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleCanonicalizer'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.LocaleCanonicalizer.fromDispatch(
      cls.callMethod<JSObject>('createExtended'.toJS),
    );
  }
  return icu.LocaleCanonicalizer.fromDispatch(
    cls.callMethod<JSObject>('createExtendedWithProvider'.toJS, p),
  );
}

icu.LocaleDirectionality localeDirectionalityDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleDirectionality'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>(
      'LocaleDirectionality'.toJS,
    );
    return icu.LocaleDirectionality.fromDispatch(
      fn.callAsConstructor<JSObject>(),
    );
  }
  return icu.LocaleDirectionality.fromDispatch(
    cls.callMethod<JSObject>('withProvider'.toJS, p),
  );
}

icu.LocaleDirectionality localeDirectionalityExtended() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleDirectionality'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.LocaleDirectionality.fromDispatch(
      cls.callMethod<JSObject>('createExtended'.toJS),
    );
  }
  return icu.LocaleDirectionality.fromDispatch(
    cls.callMethod<JSObject>('createExtendedWithProvider'.toJS, p),
  );
}

icu.LocaleDisplayNamesFormatter localeDisplayNamesFormatterDefault(
  String localeStr,
  icu.Locale locale,
  icu.DisplayNamesOptions options,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'LocaleDisplayNamesFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>(
      'LocaleDisplayNamesFormatter'.toJS,
    );
    return icu.LocaleDisplayNamesFormatter.fromDispatch(
      fn.callAsConstructor<JSObject>(locale, options),
    );
  }
  return icu.LocaleDisplayNamesFormatter.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p, locale, options),
  );
}

icu.LocaleExpander localeExpanderDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleExpander'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('LocaleExpander'.toJS);
    return icu.LocaleExpander.fromDispatch(fn.callAsConstructor<JSObject>());
  }
  return icu.LocaleExpander.fromDispatch(
    cls.callMethod<JSObject>('withProvider'.toJS, p),
  );
}

icu.LocaleExpander localeExpanderExtended() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleExpander'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.LocaleExpander.fromDispatch(
      cls.callMethod<JSObject>('createExtended'.toJS),
    );
  }
  return icu.LocaleExpander.fromDispatch(
    cls.callMethod<JSObject>('createExtendedWithProvider'.toJS, p),
  );
}

icu.LocaleFallbacker localeFallbackerDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('LocaleFallbacker'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('LocaleFallbacker'.toJS);
    return icu.LocaleFallbacker.fromDispatch(fn.callAsConstructor<JSObject>());
  }
  return icu.LocaleFallbacker.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p),
  );
}

icu.LongCurrencyFormatter longCurrencyFormatterForCurrency(
  String localeStr,
  icu.Locale locale,
  String currencyCode, [
  icu.DecimalGroupingStrategy? groupingStrategy,
]) {
  final cls = IcuKit.module.getProperty<JSObject>('LongCurrencyFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.LongCurrencyFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createForCurrency'.toJS,
        locale,
        currencyCode.toJS,
        groupingStrategy?.toJs(),
      ),
    );
  }
  return icu.LongCurrencyFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createForCurrencyWithProvider'.toJS,
      p,
      locale,
      currencyCode.toJS,
      groupingStrategy?.toJs(),
    ),
  );
}

icu.PercentFormatter percentFormatterWithDisplay(
  String localeStr,
  icu.Locale locale, {
  icu.PercentDisplay? display,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('PercentFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.PercentFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createWithDisplay'.toJS,
        locale,
        display?.toJs(),
        groupingStrategy?.toJs(),
      ),
    );
  }
  return icu.PercentFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createWithDisplayWithProvider'.toJS,
      p,
      locale,
      display?.toJs(),
      groupingStrategy?.toJs(),
    ),
  );
}

icu.PluralRules pluralRulesCardinal(String localeStr, icu.Locale locale) {
  final cls = IcuKit.module.getProperty<JSObject>('PluralRules'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.PluralRules.fromDispatch(
      cls.callMethod<JSObject>('createCardinal'.toJS, locale),
    );
  }
  return icu.PluralRules.fromDispatch(
    cls.callMethod<JSObject>('createCardinalWithProvider'.toJS, p, locale),
  );
}

icu.PluralRules pluralRulesOrdinal(String localeStr, icu.Locale locale) {
  final cls = IcuKit.module.getProperty<JSObject>('PluralRules'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.PluralRules.fromDispatch(
      cls.callMethod<JSObject>('createOrdinal'.toJS, locale),
    );
  }
  return icu.PluralRules.fromDispatch(
    cls.callMethod<JSObject>('createOrdinalWithProvider'.toJS, p, locale),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperBidiClass() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createBidiClass'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createBidiClassWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperCanonicalCombiningClass() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createCanonicalCombiningClass'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>(
      'createCanonicalCombiningClassWithProvider'.toJS,
      p,
    ),
  );
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperEastAsianWidth() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createEastAsianWidth'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createEastAsianWidthWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperGraphemeClusterBreak() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createGraphemeClusterBreak'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createGraphemeClusterBreakWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperHangulSyllableType() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createHangulSyllableType'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createHangulSyllableTypeWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperLineBreak() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createLineBreak'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createLineBreakWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperNumericType() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createNumericType'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createNumericTypeWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperScript() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createScript'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createScriptWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperSentenceBreak() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createSentenceBreak'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createSentenceBreakWithProvider'.toJS, p),
  );
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperWordBreak() {
  final cls = IcuKit.module.getProperty<JSObject>(
    'PropertyValueNameToEnumMapper'.toJS,
  );
  final p = IcuKit.providerFor('und');
  if (p == null) {
    return icu.PropertyValueNameToEnumMapper.fromDispatch(
      cls.callMethod<JSObject>('createWordBreak'.toJS),
    );
  }
  return icu.PropertyValueNameToEnumMapper.fromDispatch(
    cls.callMethod<JSObject>('createWordBreakWithProvider'.toJS, p),
  );
}

icu.RegionDisplayNames regionDisplayNamesDefault(
  String localeStr,
  icu.Locale locale,
  icu.DisplayNamesOptions options,
) {
  final cls = IcuKit.module.getProperty<JSObject>('RegionDisplayNames'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('RegionDisplayNames'.toJS);
    return icu.RegionDisplayNames.fromDispatch(
      fn.callAsConstructor<JSObject>(locale, options),
    );
  }
  return icu.RegionDisplayNames.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p, locale, options),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createLongDay'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongDayWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createLongHour'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongHourWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createLongMinute'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongMinuteWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createLongMonth'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongMonthWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createLongQuarter'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongQuarterWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createLongSecond'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongSecondWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createLongWeek'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongWeekWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createLongYear'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createLongYearWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createNarrowDay'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowDayWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowHour'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowHourWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowMinute'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowMinuteWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowMonth'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowMonthWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowQuarter'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowQuarterWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowSecond'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowSecondWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowWeek'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowWeekWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createNarrowYear'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createNarrowYearWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createShortDay'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortDayWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createShortHour'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortHourWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createShortMinute'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortMinuteWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createShortMonth'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortMonthWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createShortQuarter'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortQuarterWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>(
        'createShortSecond'.toJS,
        locale,
        numeric?.toJs(),
      ),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortSecondWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createShortWeek'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortWeekWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'RelativeTimeFormatterFfi'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.RelativeTimeFormatterFfi.fromDispatch(
      cls.callMethod<JSObject>('createShortYear'.toJS, locale, numeric?.toJs()),
    );
  }
  return icu.RelativeTimeFormatterFfi.fromDispatch(
    cls.callMethod<JSObject>(
      'createShortYearWithProvider'.toJS,
      p,
      locale,
      numeric?.toJs(),
    ),
  );
}

icu.SentenceSegmenter sentenceSegmenterWithContentLocale(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('SentenceSegmenter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.SentenceSegmenter.fromDispatch(
      cls.callMethod<JSObject>('createWithContentLocale'.toJS, locale),
    );
  }
  return icu.SentenceSegmenter.fromDispatch(
    cls.callMethod<JSObject>(
      'createWithContentLocaleAndProvider'.toJS,
      p,
      locale,
    ),
  );
}

icu.TimeFormatter timeFormatterDefault(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('TimeFormatter'.toJS);
    return icu.TimeFormatter.fromDispatch(
      fn.callAsConstructor<JSObject>(
        locale,
        length?.toJs(),
        timePrecision?.toJs(),
        alignment?.toJs(),
      ),
    );
  }
  return icu.TimeFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createWithProvider'.toJS, [
      p,
      locale,
      length?.toJs(),
      timePrecision?.toJs(),
      alignment?.toJs(),
    ]),
  );
}

icu.TimeZoneFormatter timeZoneFormatterExemplarCity(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createExemplarCity'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createExemplarCityWithProvider'.toJS, p, locale),
  );
}

icu.TimeZoneFormatter timeZoneFormatterGenericLong(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createGenericLong'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createGenericLongWithProvider'.toJS, p, locale),
  );
}

icu.TimeZoneFormatter timeZoneFormatterGenericShort(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createGenericShort'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createGenericShortWithProvider'.toJS, p, locale),
  );
}

icu.TimeZoneFormatter timeZoneFormatterLocalizedOffsetLong(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createLocalizedOffsetLong'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createLocalizedOffsetLongWithProvider'.toJS,
      p,
      locale,
    ),
  );
}

icu.TimeZoneFormatter timeZoneFormatterLocalizedOffsetShort(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createLocalizedOffsetShort'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createLocalizedOffsetShortWithProvider'.toJS,
      p,
      locale,
    ),
  );
}

icu.TimeZoneFormatter timeZoneFormatterLocation(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createLocation'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createLocationWithProvider'.toJS, p, locale),
  );
}

icu.TimeZoneFormatter timeZoneFormatterSpecificLong(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createSpecificLong'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createSpecificLongWithProvider'.toJS, p, locale),
  );
}

icu.TimeZoneFormatter timeZoneFormatterSpecificShort(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('TimeZoneFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.TimeZoneFormatter.fromDispatch(
      cls.callMethod<JSObject>('createSpecificShort'.toJS, locale),
    );
  }
  return icu.TimeZoneFormatter.fromDispatch(
    cls.callMethod<JSObject>('createSpecificShortWithProvider'.toJS, p, locale),
  );
}

icu.TitlecaseMapper titlecaseMapperDefault() {
  final cls = IcuKit.module.getProperty<JSObject>('TitlecaseMapper'.toJS);
  final p = IcuKit.providerFor('und');
  if (p == null) {
    final fn = IcuKit.module.getProperty<JSFunction>('TitlecaseMapper'.toJS);
    return icu.TitlecaseMapper.fromDispatch(fn.callAsConstructor<JSObject>());
  }
  return icu.TitlecaseMapper.fromDispatch(
    cls.callMethod<JSObject>('createWithProvider'.toJS, p),
  );
}

icu.UnitsFormatter unitsFormatterForUnit(
  String localeStr,
  icu.Locale locale,
  String unitIdentifier, {
  icu.UnitsWidth? width,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final cls = IcuKit.module.getProperty<JSObject>('UnitsFormatter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.UnitsFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createForUnit'.toJS,
        locale,
        unitIdentifier.toJS,
        width?.toJs(),
        groupingStrategy?.toJs(),
      ),
    );
  }
  return icu.UnitsFormatter.fromDispatch(
    cls.callMethodVarArgs<JSObject>('createForUnitWithProvider'.toJS, [
      p,
      locale,
      unitIdentifier.toJS,
      width?.toJs(),
      groupingStrategy?.toJs(),
    ]),
  );
}

icu.WordSegmenter wordSegmenterAutoWithContentLocale(
  String localeStr,
  icu.Locale locale,
) {
  final cls = IcuKit.module.getProperty<JSObject>('WordSegmenter'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.WordSegmenter.fromDispatch(
      cls.callMethod<JSObject>('createAutoWithContentLocale'.toJS, locale),
    );
  }
  return icu.WordSegmenter.fromDispatch(
    cls.callMethod<JSObject>(
      'createAutoWithContentLocaleAndProvider'.toJS,
      p,
      locale,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterExemplarCity(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createExemplarCity'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createExemplarCityWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterGenericLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createGenericLong'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createGenericLongWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterGenericShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createGenericShort'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createGenericShortWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocalizedOffsetLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createLocalizedOffsetLong'.toJS,
        locale,
        formatter,
      ),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createLocalizedOffsetLongWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocalizedOffsetShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>(
        'createLocalizedOffsetShort'.toJS,
        locale,
        formatter,
      ),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createLocalizedOffsetShortWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocation(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createLocation'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createLocationWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterSpecificLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createSpecificLong'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createSpecificLongWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterSpecificShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final cls = IcuKit.module.getProperty<JSObject>(
    'ZonedDateTimeFormatter'.toJS,
  );
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return icu.ZonedDateTimeFormatter.fromDispatch(
      cls.callMethod<JSObject>('createSpecificShort'.toJS, locale, formatter),
    );
  }
  return icu.ZonedDateTimeFormatter.fromDispatch(
    cls.callMethod<JSObject>(
      'createSpecificShortWithProvider'.toJS,
      p,
      locale,
      formatter,
    ),
  );
}
