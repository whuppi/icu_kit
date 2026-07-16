// AUTO-GENERATED — DO NOT EDIT
//
// Run `fvm dart run tool/regen_dispatch.dart` to regenerate.
//
// One method per `Class.fooWithProvider` constructor exposed by the
// Diplomat-generated FFI bindings. Each method dispatches between the
// compiled-data form and the `*WithProvider` form based on the active
// `IcuData` (see `IcuKit.init`).
//
// Facades call these dispatch methods instead of branching themselves.

import 'bindings.dart' as icu;
import 'init.dart';

icu.Bidi bidiDefault() {
  final p = IcuKit.providerFor('und');
  return p == null ? icu.Bidi() : icu.Bidi.withProvider(p);
}

icu.Calendar calendarDefault(icu.CalendarKind kind) {
  final p = IcuKit.providerFor('und');
  return p == null ? icu.Calendar(kind) : icu.Calendar.newWithProvider(p, kind);
}

icu.CaseMapper caseMapperDefault() {
  final p = IcuKit.providerFor('und');
  return p == null ? icu.CaseMapper() : icu.CaseMapper.withProvider(p);
}

icu.CodePointMapData16 codePointMapData16Script() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData16.script()
      : icu.CodePointMapData16.scriptWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8BidiClass() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.bidiClass()
      : icu.CodePointMapData8.bidiClassWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8CanonicalCombiningClass() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.canonicalCombiningClass()
      : icu.CodePointMapData8.canonicalCombiningClassWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8EastAsianWidth() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.eastAsianWidth()
      : icu.CodePointMapData8.eastAsianWidthWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8GeneralCategory() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.generalCategory()
      : icu.CodePointMapData8.generalCategoryWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8GraphemeClusterBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.graphemeClusterBreak()
      : icu.CodePointMapData8.graphemeClusterBreakWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8HangulSyllableType() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.hangulSyllableType()
      : icu.CodePointMapData8.hangulSyllableTypeWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8JoiningType() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.joiningType()
      : icu.CodePointMapData8.joiningTypeWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8LineBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.lineBreak()
      : icu.CodePointMapData8.lineBreakWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8SentenceBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.sentenceBreak()
      : icu.CodePointMapData8.sentenceBreakWithProvider(p);
}

icu.CodePointMapData8 codePointMapData8WordBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointMapData8.wordBreak()
      : icu.CodePointMapData8.wordBreakWithProvider(p);
}

icu.CodePointSetData codePointSetDataAlnum() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.alnum()
      : icu.CodePointSetData.alnumWithProvider(p);
}

icu.CodePointSetData codePointSetDataAlphabetic() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.alphabetic()
      : icu.CodePointSetData.alphabeticWithProvider(p);
}

icu.CodePointSetData codePointSetDataAsciiHexDigit() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.asciiHexDigit()
      : icu.CodePointSetData.asciiHexDigitWithProvider(p);
}

icu.CodePointSetData codePointSetDataBidiControl() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.bidiControl()
      : icu.CodePointSetData.bidiControlWithProvider(p);
}

icu.CodePointSetData codePointSetDataBidiMirrored() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.bidiMirrored()
      : icu.CodePointSetData.bidiMirroredWithProvider(p);
}

icu.CodePointSetData codePointSetDataBlank() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.blank()
      : icu.CodePointSetData.blankWithProvider(p);
}

icu.CodePointSetData codePointSetDataCaseIgnorable() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.caseIgnorable()
      : icu.CodePointSetData.caseIgnorableWithProvider(p);
}

icu.CodePointSetData codePointSetDataCased() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.cased()
      : icu.CodePointSetData.casedWithProvider(p);
}

icu.CodePointSetData codePointSetDataDash() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.dash()
      : icu.CodePointSetData.dashWithProvider(p);
}

icu.CodePointSetData codePointSetDataDefaultIgnorableCodePoint() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.defaultIgnorableCodePoint()
      : icu.CodePointSetData.defaultIgnorableCodePointWithProvider(p);
}

icu.CodePointSetData codePointSetDataDeprecated() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.deprecated()
      : icu.CodePointSetData.deprecatedWithProvider(p);
}

icu.CodePointSetData codePointSetDataDiacritic() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.diacritic()
      : icu.CodePointSetData.diacriticWithProvider(p);
}

icu.CodePointSetData codePointSetDataEmoji() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.emoji()
      : icu.CodePointSetData.emojiWithProvider(p);
}

icu.CodePointSetData codePointSetDataEmojiComponent() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.emojiComponent()
      : icu.CodePointSetData.emojiComponentWithProvider(p);
}

icu.CodePointSetData codePointSetDataEmojiModifier() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.emojiModifier()
      : icu.CodePointSetData.emojiModifierWithProvider(p);
}

icu.CodePointSetData codePointSetDataEmojiModifierBase() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.emojiModifierBase()
      : icu.CodePointSetData.emojiModifierBaseWithProvider(p);
}

icu.CodePointSetData codePointSetDataEmojiPresentation() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.emojiPresentation()
      : icu.CodePointSetData.emojiPresentationWithProvider(p);
}

icu.CodePointSetData codePointSetDataExtendedPictographic() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.extendedPictographic()
      : icu.CodePointSetData.extendedPictographicWithProvider(p);
}

icu.CodePointSetData codePointSetDataExtender() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.extender()
      : icu.CodePointSetData.extenderWithProvider(p);
}

icu.CodePointSetData codePointSetDataGraph() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.graph()
      : icu.CodePointSetData.graphWithProvider(p);
}

icu.CodePointSetData codePointSetDataGraphemeBase() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.graphemeBase()
      : icu.CodePointSetData.graphemeBaseWithProvider(p);
}

icu.CodePointSetData codePointSetDataGraphemeExtend() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.graphemeExtend()
      : icu.CodePointSetData.graphemeExtendWithProvider(p);
}

icu.CodePointSetData codePointSetDataHexDigit() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.hexDigit()
      : icu.CodePointSetData.hexDigitWithProvider(p);
}

icu.CodePointSetData codePointSetDataIdContinue() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.idContinue()
      : icu.CodePointSetData.idContinueWithProvider(p);
}

icu.CodePointSetData codePointSetDataIdStart() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.idStart()
      : icu.CodePointSetData.idStartWithProvider(p);
}

icu.CodePointSetData codePointSetDataIdeographic() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.ideographic()
      : icu.CodePointSetData.ideographicWithProvider(p);
}

icu.CodePointSetData codePointSetDataJoinControl() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.joinControl()
      : icu.CodePointSetData.joinControlWithProvider(p);
}

icu.CodePointSetData codePointSetDataLowercase() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.lowercase()
      : icu.CodePointSetData.lowercaseWithProvider(p);
}

icu.CodePointSetData codePointSetDataMath() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.math()
      : icu.CodePointSetData.mathWithProvider(p);
}

icu.CodePointSetData codePointSetDataNoncharacterCodePoint() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.noncharacterCodePoint()
      : icu.CodePointSetData.noncharacterCodePointWithProvider(p);
}

icu.CodePointSetData codePointSetDataPatternSyntax() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.patternSyntax()
      : icu.CodePointSetData.patternSyntaxWithProvider(p);
}

icu.CodePointSetData codePointSetDataPatternWhiteSpace() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.patternWhiteSpace()
      : icu.CodePointSetData.patternWhiteSpaceWithProvider(p);
}

icu.CodePointSetData codePointSetDataPrint() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.print()
      : icu.CodePointSetData.printWithProvider(p);
}

icu.CodePointSetData codePointSetDataQuotationMark() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.quotationMark()
      : icu.CodePointSetData.quotationMarkWithProvider(p);
}

icu.CodePointSetData codePointSetDataRadical() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.radical()
      : icu.CodePointSetData.radicalWithProvider(p);
}

icu.CodePointSetData codePointSetDataRegionalIndicator() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.regionalIndicator()
      : icu.CodePointSetData.regionalIndicatorWithProvider(p);
}

icu.CodePointSetData codePointSetDataSentenceTerminal() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.sentenceTerminal()
      : icu.CodePointSetData.sentenceTerminalWithProvider(p);
}

icu.CodePointSetData codePointSetDataSoftDotted() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.softDotted()
      : icu.CodePointSetData.softDottedWithProvider(p);
}

icu.CodePointSetData codePointSetDataTerminalPunctuation() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.terminalPunctuation()
      : icu.CodePointSetData.terminalPunctuationWithProvider(p);
}

icu.CodePointSetData codePointSetDataUnifiedIdeograph() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.unifiedIdeograph()
      : icu.CodePointSetData.unifiedIdeographWithProvider(p);
}

icu.CodePointSetData codePointSetDataUppercase() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.uppercase()
      : icu.CodePointSetData.uppercaseWithProvider(p);
}

icu.CodePointSetData codePointSetDataVariationSelector() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.variationSelector()
      : icu.CodePointSetData.variationSelectorWithProvider(p);
}

icu.CodePointSetData codePointSetDataWhiteSpace() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.whiteSpace()
      : icu.CodePointSetData.whiteSpaceWithProvider(p);
}

icu.CodePointSetData codePointSetDataXidContinue() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.xidContinue()
      : icu.CodePointSetData.xidContinueWithProvider(p);
}

icu.CodePointSetData codePointSetDataXidStart() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.CodePointSetData.xidStart()
      : icu.CodePointSetData.xidStartWithProvider(p);
}

icu.Collator collatorDefault(
  String localeStr,
  icu.Locale locale,
  icu.CollatorOptions options,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.Collator(locale, options)
      : icu.Collator.createWithProvider(p, locale, options);
}

icu.ComposingNormalizer composingNormalizerNfc() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.ComposingNormalizer.nfc()
      : icu.ComposingNormalizer.nfcWithProvider(p);
}

icu.ComposingNormalizer composingNormalizerNfkc() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.ComposingNormalizer.nfkc()
      : icu.ComposingNormalizer.nfkcWithProvider(p);
}

icu.CurrencyFormatter currencyFormatterWithWidth(
  String localeStr,
  icu.Locale locale, {
  icu.CurrencyWidth? width,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.CurrencyFormatter.withWidth(
          locale,
          width: width,
          groupingStrategy: groupingStrategy,
        )
      : icu.CurrencyFormatter.withWidthWithProvider(
          p,
          locale,
          width: width,
          groupingStrategy: groupingStrategy,
        );
}

icu.DateFormatter dateFormatterD(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.d(locale, length: length, alignment: alignment)
      : icu.DateFormatter.dWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
        );
}

icu.DateFormatter dateFormatterDe(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.de(locale, length: length, alignment: alignment)
      : icu.DateFormatter.deWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
        );
}

icu.DateFormatter dateFormatterE(
  String localeStr,
  icu.Locale locale, [
  icu.DateTimeLength? length,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.e(locale, length)
      : icu.DateFormatter.eWithProvider(p, locale, length);
}

icu.DateFormatter dateFormatterM(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.m(locale, length: length, alignment: alignment)
      : icu.DateFormatter.mWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
        );
}

icu.DateFormatter dateFormatterMd(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.md(locale, length: length, alignment: alignment)
      : icu.DateFormatter.mdWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
        );
}

icu.DateFormatter dateFormatterMde(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.mde(locale, length: length, alignment: alignment)
      : icu.DateFormatter.mdeWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
        );
}

icu.DateFormatter dateFormatterY(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.y(
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateFormatter.yWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        );
}

icu.DateFormatter dateFormatterYm(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.ym(
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateFormatter.ymWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        );
}

icu.DateFormatter dateFormatterYmd(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.ymd(
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateFormatter.ymdWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        );
}

icu.DateFormatter dateFormatterYmde(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.DateTimeAlignment? alignment,
  icu.YearStyle? yearStyle,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateFormatter.ymde(
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateFormatter.ymdeWithProvider(
          p,
          locale,
          length: length,
          alignment: alignment,
          yearStyle: yearStyle,
        );
}

icu.DateTimeFormatter dateTimeFormatterDet(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.det(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.DateTimeFormatter.detWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        );
}

icu.DateTimeFormatter dateTimeFormatterDt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.dt(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.DateTimeFormatter.dtWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        );
}

icu.DateTimeFormatter dateTimeFormatterEt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.et(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.DateTimeFormatter.etWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        );
}

icu.DateTimeFormatter dateTimeFormatterMdet(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.mdet(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.DateTimeFormatter.mdetWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        );
}

icu.DateTimeFormatter dateTimeFormatterMdt(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.mdt(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.DateTimeFormatter.mdtWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
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
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.ymdet(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateTimeFormatter.ymdetWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
          yearStyle: yearStyle,
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
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DateTimeFormatter.ymdt(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
          yearStyle: yearStyle,
        )
      : icu.DateTimeFormatter.ymdtWithProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
          yearStyle: yearStyle,
        );
}

icu.DecimalFormatter decimalFormatterWithGroupingStrategy(
  String localeStr,
  icu.Locale locale, [
  icu.DecimalGroupingStrategy? groupingStrategy,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.DecimalFormatter.withGroupingStrategy(locale, groupingStrategy)
      : icu.DecimalFormatter.withGroupingStrategyAndProvider(
          p,
          locale,
          groupingStrategy,
        );
}

icu.DecomposingNormalizer decomposingNormalizerNfd() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.DecomposingNormalizer.nfd()
      : icu.DecomposingNormalizer.nfdWithProvider(p);
}

icu.DecomposingNormalizer decomposingNormalizerNfkd() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.DecomposingNormalizer.nfkd()
      : icu.DecomposingNormalizer.nfkdWithProvider(p);
}

icu.ExemplarCharacters exemplarCharactersAuxiliary(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ExemplarCharacters.auxiliary(locale)
      : icu.ExemplarCharacters.auxiliaryWithProvider(p, locale);
}

icu.ExemplarCharacters exemplarCharactersIndex(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ExemplarCharacters.index(locale)
      : icu.ExemplarCharacters.indexWithProvider(p, locale);
}

icu.ExemplarCharacters exemplarCharactersMain(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ExemplarCharacters.main(locale)
      : icu.ExemplarCharacters.mainWithProvider(p, locale);
}

icu.ExemplarCharacters exemplarCharactersNumbers(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ExemplarCharacters.numbers(locale)
      : icu.ExemplarCharacters.numbersWithProvider(p, locale);
}

icu.ExemplarCharacters exemplarCharactersPunctuation(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ExemplarCharacters.punctuation(locale)
      : icu.ExemplarCharacters.punctuationWithProvider(p, locale);
}

icu.GraphemeClusterSegmenter graphemeClusterSegmenterDefault() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.GraphemeClusterSegmenter()
      : icu.GraphemeClusterSegmenter.withProvider(p);
}

icu.ListFormatter listFormatterAndWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ListFormatter.andWithLength(locale, length)
      : icu.ListFormatter.andWithLengthAndProvider(p, locale, length);
}

icu.ListFormatter listFormatterOrWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ListFormatter.orWithLength(locale, length)
      : icu.ListFormatter.orWithLengthAndProvider(p, locale, length);
}

icu.ListFormatter listFormatterUnitWithLength(
  String localeStr,
  icu.Locale locale,
  icu.ListLength length,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ListFormatter.unitWithLength(locale, length)
      : icu.ListFormatter.unitWithLengthAndProvider(p, locale, length);
}

icu.LocaleCanonicalizer localeCanonicalizerDefault() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleCanonicalizer()
      : icu.LocaleCanonicalizer.withProvider(p);
}

icu.LocaleCanonicalizer localeCanonicalizerExtended() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleCanonicalizer.extended()
      : icu.LocaleCanonicalizer.extendedWithProvider(p);
}

icu.LocaleDirectionality localeDirectionalityDefault() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleDirectionality()
      : icu.LocaleDirectionality.withProvider(p);
}

icu.LocaleDirectionality localeDirectionalityExtended() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleDirectionality.extended()
      : icu.LocaleDirectionality.extendedWithProvider(p);
}

icu.LocaleDisplayNamesFormatter localeDisplayNamesFormatterDefault(
  String localeStr,
  icu.Locale locale,
  icu.DisplayNamesOptions options,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.LocaleDisplayNamesFormatter(locale, options)
      : icu.LocaleDisplayNamesFormatter.createWithProvider(p, locale, options);
}

icu.LocaleExpander localeExpanderDefault() {
  final p = IcuKit.providerFor('und');
  return p == null ? icu.LocaleExpander() : icu.LocaleExpander.withProvider(p);
}

icu.LocaleExpander localeExpanderExtended() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleExpander.extended()
      : icu.LocaleExpander.extendedWithProvider(p);
}

icu.LocaleFallbacker localeFallbackerDefault() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.LocaleFallbacker()
      : icu.LocaleFallbacker.withProvider(p);
}

icu.LongCurrencyFormatter longCurrencyFormatterForCurrency(
  String localeStr,
  icu.Locale locale,
  String currencyCode, [
  icu.DecimalGroupingStrategy? groupingStrategy,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.LongCurrencyFormatter.forCurrency(
          locale,
          currencyCode,
          groupingStrategy,
        )
      : icu.LongCurrencyFormatter.forCurrencyWithProvider(
          p,
          locale,
          currencyCode,
          groupingStrategy,
        );
}

icu.PercentFormatter percentFormatterWithDisplay(
  String localeStr,
  icu.Locale locale, {
  icu.PercentDisplay? display,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.PercentFormatter.withDisplay(
          locale,
          display: display,
          groupingStrategy: groupingStrategy,
        )
      : icu.PercentFormatter.withDisplayWithProvider(
          p,
          locale,
          display: display,
          groupingStrategy: groupingStrategy,
        );
}

icu.PluralRules pluralRulesCardinal(String localeStr, icu.Locale locale) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.PluralRules.cardinal(locale)
      : icu.PluralRules.cardinalWithProvider(p, locale);
}

icu.PluralRules pluralRulesOrdinal(String localeStr, icu.Locale locale) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.PluralRules.ordinal(locale)
      : icu.PluralRules.ordinalWithProvider(p, locale);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperBidiClass() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.bidiClass()
      : icu.PropertyValueNameToEnumMapper.bidiClassWithProvider(p);
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperCanonicalCombiningClass() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.canonicalCombiningClass()
      : icu.PropertyValueNameToEnumMapper.canonicalCombiningClassWithProvider(
          p,
        );
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperEastAsianWidth() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.eastAsianWidth()
      : icu.PropertyValueNameToEnumMapper.eastAsianWidthWithProvider(p);
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperGraphemeClusterBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.graphemeClusterBreak()
      : icu.PropertyValueNameToEnumMapper.graphemeClusterBreakWithProvider(p);
}

icu.PropertyValueNameToEnumMapper
propertyValueNameToEnumMapperHangulSyllableType() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.hangulSyllableType()
      : icu.PropertyValueNameToEnumMapper.hangulSyllableTypeWithProvider(p);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperLineBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.lineBreak()
      : icu.PropertyValueNameToEnumMapper.lineBreakWithProvider(p);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperNumericType() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.numericType()
      : icu.PropertyValueNameToEnumMapper.numericTypeWithProvider(p);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperScript() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.script()
      : icu.PropertyValueNameToEnumMapper.scriptWithProvider(p);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperSentenceBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.sentenceBreak()
      : icu.PropertyValueNameToEnumMapper.sentenceBreakWithProvider(p);
}

icu.PropertyValueNameToEnumMapper propertyValueNameToEnumMapperWordBreak() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.PropertyValueNameToEnumMapper.wordBreak()
      : icu.PropertyValueNameToEnumMapper.wordBreakWithProvider(p);
}

icu.RegionDisplayNames regionDisplayNamesDefault(
  String localeStr,
  icu.Locale locale,
  icu.DisplayNamesOptions options,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RegionDisplayNames(locale, options)
      : icu.RegionDisplayNames.createWithProvider(p, locale, options);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longDay(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longDayWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longHour(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longHourWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longMinute(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longMinuteWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longMonth(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longMonthWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longQuarter(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longQuarterWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longSecond(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longSecondWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longWeek(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longWeekWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiLongYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.longYear(locale, numeric)
      : icu.RelativeTimeFormatterFfi.longYearWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowDay(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowDayWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowHour(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowHourWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowMinute(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowMinuteWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowMonth(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowMonthWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowQuarter(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowQuarterWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowSecond(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowSecondWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowWeek(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowWeekWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiNarrowYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.narrowYear(locale, numeric)
      : icu.RelativeTimeFormatterFfi.narrowYearWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortDay(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortDay(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortDayWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortHour(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortHour(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortHourWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortMinute(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortMinute(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortMinuteWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortMonth(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortMonth(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortMonthWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortQuarter(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortQuarter(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortQuarterWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortSecond(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortSecond(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortSecondWithProvider(
          p,
          locale,
          numeric,
        );
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortWeek(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortWeek(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortWeekWithProvider(p, locale, numeric);
}

icu.RelativeTimeFormatterFfi relativeTimeFormatterFfiShortYear(
  String localeStr,
  icu.Locale locale, [
  icu.RelativeTimeNumeric? numeric,
]) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.RelativeTimeFormatterFfi.shortYear(locale, numeric)
      : icu.RelativeTimeFormatterFfi.shortYearWithProvider(p, locale, numeric);
}

icu.SentenceSegmenter sentenceSegmenterWithContentLocale(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.SentenceSegmenter.withContentLocale(locale)
      : icu.SentenceSegmenter.withContentLocaleAndProvider(p, locale);
}

icu.TimeFormatter timeFormatterDefault(
  String localeStr,
  icu.Locale locale, {
  icu.DateTimeLength? length,
  icu.TimePrecision? timePrecision,
  icu.DateTimeAlignment? alignment,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeFormatter(
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        )
      : icu.TimeFormatter.withProvider(
          p,
          locale,
          length: length,
          timePrecision: timePrecision,
          alignment: alignment,
        );
}

icu.TimeZoneFormatter timeZoneFormatterExemplarCity(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.exemplarCity(locale)
      : icu.TimeZoneFormatter.exemplarCityWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterGenericLong(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.genericLong(locale)
      : icu.TimeZoneFormatter.genericLongWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterGenericShort(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.genericShort(locale)
      : icu.TimeZoneFormatter.genericShortWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterLocalizedOffsetLong(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.localizedOffsetLong(locale)
      : icu.TimeZoneFormatter.localizedOffsetLongWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterLocalizedOffsetShort(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.localizedOffsetShort(locale)
      : icu.TimeZoneFormatter.localizedOffsetShortWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterLocation(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.location(locale)
      : icu.TimeZoneFormatter.locationWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterSpecificLong(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.specificLong(locale)
      : icu.TimeZoneFormatter.specificLongWithProvider(p, locale);
}

icu.TimeZoneFormatter timeZoneFormatterSpecificShort(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.TimeZoneFormatter.specificShort(locale)
      : icu.TimeZoneFormatter.specificShortWithProvider(p, locale);
}

icu.TitlecaseMapper titlecaseMapperDefault() {
  final p = IcuKit.providerFor('und');
  return p == null
      ? icu.TitlecaseMapper()
      : icu.TitlecaseMapper.withProvider(p);
}

icu.UnitsFormatter unitsFormatterForUnit(
  String localeStr,
  icu.Locale locale,
  String unitIdentifier, {
  icu.UnitsWidth? width,
  icu.DecimalGroupingStrategy? groupingStrategy,
}) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.UnitsFormatter.forUnit(
          locale,
          unitIdentifier,
          width: width,
          groupingStrategy: groupingStrategy,
        )
      : icu.UnitsFormatter.forUnitWithProvider(
          p,
          locale,
          unitIdentifier,
          width: width,
          groupingStrategy: groupingStrategy,
        );
}

icu.WordSegmenter wordSegmenterAutoWithContentLocale(
  String localeStr,
  icu.Locale locale,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.WordSegmenter.autoWithContentLocale(locale)
      : icu.WordSegmenter.autoWithContentLocaleAndProvider(p, locale);
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterExemplarCity(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.exemplarCity(locale, formatter)
      : icu.ZonedDateTimeFormatter.exemplarCityWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterGenericLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.genericLong(locale, formatter)
      : icu.ZonedDateTimeFormatter.genericLongWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterGenericShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.genericShort(locale, formatter)
      : icu.ZonedDateTimeFormatter.genericShortWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocalizedOffsetLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.localizedOffsetLong(locale, formatter)
      : icu.ZonedDateTimeFormatter.localizedOffsetLongWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocalizedOffsetShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.localizedOffsetShort(locale, formatter)
      : icu.ZonedDateTimeFormatter.localizedOffsetShortWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterLocation(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.location(locale, formatter)
      : icu.ZonedDateTimeFormatter.locationWithProvider(p, locale, formatter);
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterSpecificLong(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.specificLong(locale, formatter)
      : icu.ZonedDateTimeFormatter.specificLongWithProvider(
          p,
          locale,
          formatter,
        );
}

icu.ZonedDateTimeFormatter zonedDateTimeFormatterSpecificShort(
  String localeStr,
  icu.Locale locale,
  icu.DateTimeFormatter formatter,
) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.ZonedDateTimeFormatter.specificShort(locale, formatter)
      : icu.ZonedDateTimeFormatter.specificShortWithProvider(
          p,
          locale,
          formatter,
        );
}
