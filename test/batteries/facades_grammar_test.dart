// CHARTER — this file alone proves, through ONE shared spec, that every
// public entry point accepting a BCP-47 tag speaks the locale-error law
// (see locale_grammar_battery.dart): an unparseable tag throws
// IcuLocaleParseError. It is also the fleet-visible table of who takes
// locales at all:
//
//   constructor-shaped                    method-shaped
//   IcuLocale.parse¹                      IcuLocaleCanonicalizer.canonicalize
//   IcuCollator                           IcuLocaleExpander.maximize /
//   IcuNumberFormat.decimal                 .minimize / .minimizeFavorScript
//   IcuCurrencyFormat.symbol / .long²     IcuLocaleDirectionality.directionOf
//   IcuPercentFormat²                     IcuLocaleFallbacker.chain³
//   IcuUnitFormat²                        IcuCaseMapper.uppercase⁴
//   IcuDateFormat.ymd⁵
//   IcuTimeFormat
//   IcuDateTimeFormat.ymdt⁵
//   IcuZonedDateTimeFormat.ymdt⁵
//   IcuTimeZoneFormat
//   IcuListFormat.and⁵
//   IcuPluralRules.cardinal⁵
//   IcuRelativeTimeFormat
//   IcuRegionDisplayNames
//   IcuLocaleDisplayNames
//   IcuExemplarCharacters
//   IcuSegmenter.word / .sentence
//
//   No locale, out of scope: IcuCalendar (kind-keyed), IcuNormalizer,
//   IcuBidi, IcuProperties, the IcuEnumProperty family, IcuPropertyName,
//   IcuIdna, IcuSegmenter.grapheme, IcuLineSegmenter.
//
// ¹ the payload contract (error carries the offending tag) stays in
//   facade/locale_test.dart; this battery proves the type only.
// ² experimental facades — tagged for release-pipeline exclusion.
// ³ lazy iterable — the law fires on first iteration (.first).
// ⁴ one representative method; lowercase/titlecase share the parse site.
// ⁵ one representative constructor; its siblings share the parse site.

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'locale_grammar_battery.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  registerLocaleGrammarBattery([
    LocaleLawCase('IcuLocale.parse', (l) => IcuLocale.parse(l)),
    LocaleLawCase('IcuCollator', (l) => IcuCollator(locale: l)),
    LocaleLawCase(
      'IcuNumberFormat.decimal',
      (l) => IcuNumberFormat.decimal(locale: l),
    ),
    LocaleLawCase(
      'IcuCurrencyFormat.symbol',
      (l) => IcuCurrencyFormat.symbol(locale: l),
      tags: ['experimental_currency'],
    ),
    LocaleLawCase(
      'IcuCurrencyFormat.long',
      (l) => IcuCurrencyFormat.long(locale: l, currencyCode: 'USD'),
      tags: ['experimental_currency'],
    ),
    LocaleLawCase(
      'IcuPercentFormat',
      (l) => IcuPercentFormat(locale: l),
      tags: ['experimental_percent'],
    ),
    LocaleLawCase(
      'IcuUnitFormat',
      (l) => IcuUnitFormat(locale: l, unit: 'hour'),
      tags: ['experimental_unit'],
    ),
    LocaleLawCase('IcuDateFormat.ymd', (l) => IcuDateFormat.ymd(locale: l)),
    LocaleLawCase('IcuTimeFormat', (l) => IcuTimeFormat(locale: l)),
    LocaleLawCase(
      'IcuDateTimeFormat.ymdt',
      (l) => IcuDateTimeFormat.ymdt(locale: l),
    ),
    LocaleLawCase(
      'IcuZonedDateTimeFormat.ymdt',
      (l) => IcuZonedDateTimeFormat.ymdt(locale: l),
    ),
    LocaleLawCase('IcuTimeZoneFormat', (l) => IcuTimeZoneFormat(locale: l)),
    LocaleLawCase('IcuListFormat.and', (l) => IcuListFormat.and(locale: l)),
    LocaleLawCase('IcuPluralRules.cardinal', (l) => IcuPluralRules.cardinal(l)),
    LocaleLawCase(
      'IcuRelativeTimeFormat',
      (l) => IcuRelativeTimeFormat(locale: l, unit: IcuRelativeTimeUnit.day),
    ),
    LocaleLawCase(
      'IcuRegionDisplayNames',
      (l) => IcuRegionDisplayNames(locale: l),
    ),
    LocaleLawCase(
      'IcuLocaleDisplayNames',
      (l) => IcuLocaleDisplayNames(locale: l),
    ),
    LocaleLawCase(
      'IcuExemplarCharacters',
      (l) => IcuExemplarCharacters(locale: l, set: IcuExemplarSet.main),
    ),
    LocaleLawCase('IcuSegmenter.word', (l) => IcuSegmenter.word(locale: l)),
    LocaleLawCase(
      'IcuSegmenter.sentence',
      (l) => IcuSegmenter.sentence(locale: l),
    ),
    LocaleLawCase(
      'IcuLocaleCanonicalizer.canonicalize',
      (l) => IcuLocaleCanonicalizer().canonicalize(l),
    ),
    LocaleLawCase(
      'IcuLocaleExpander.maximize',
      (l) => IcuLocaleExpander().maximize(l),
    ),
    LocaleLawCase(
      'IcuLocaleExpander.minimize',
      (l) => IcuLocaleExpander().minimize(l),
    ),
    LocaleLawCase(
      'IcuLocaleExpander.minimizeFavorScript',
      (l) => IcuLocaleExpander().minimizeFavorScript(l),
    ),
    LocaleLawCase(
      'IcuLocaleDirectionality.directionOf',
      (l) => IcuLocaleDirectionality().directionOf(l),
    ),
    LocaleLawCase(
      'IcuLocaleFallbacker.chain',
      (l) => IcuLocaleFallbacker().chain(l).first,
    ),
    LocaleLawCase(
      'IcuCaseMapper.uppercase',
      (l) => IcuCaseMapper().uppercase('x', locale: l),
    ),
  ]);
}
