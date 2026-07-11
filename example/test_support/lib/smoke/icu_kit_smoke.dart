// Integration smoke — every facade family exercised against the REAL
// native library on a real target (Android/iOS emulators, desktop, or
// Chrome via flutter drive). What it proves: the build hook produced a
// loadable library for THIS target (including the Android 16 KB
// page-size story), init succeeds, and each facade returns real CLDR
// shapes — the same assertions the package suites make on the host,
// re-run where the bits actually ship.
//
// Programmatic on purpose: the journey tests already drive the UI; this
// suite pins the engine itself so a target-specific build/link/data
// regression can't hide behind widget behavior.

import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit/icu_kit.dart';
import 'package:icu_kit_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initExampleIcu();
    if (!IcuKit.hasCompiledData) {
      // Programmatic suite — no UI preload path, so load every locale
      // the assertions below format with ('en' is not in the strip).
      for (final l in [...exampleLocales, 'en']) {
        await IcuKit.preloadLocale(l);
      }
    }
  });

  testWidgets('numbers — grouping is locale truth', (t) async {
    const n = 1234567.89;
    expect(IcuNumberFormat.decimal(locale: 'en-US').format(n), '1,234,567.89');
    expect(IcuNumberFormat.decimal(locale: 'de').format(n), '1.234.567,89');
    expect(IcuNumberFormat.decimal(locale: 'hi').format(n), '12,34,567.89');
  });

  testWidgets('currency, percent, unit (experimental) render shapes', (
    t,
  ) async {
    final eur = IcuCurrencyFormat.symbol(
      locale: 'de',
    ).format(1999.5, currencyCode: 'EUR');
    expect(eur, contains('€'));
    expect(IcuPercentFormat(locale: 'en').format(73.4), contains('%'));
    expect(
      IcuUnitFormat(locale: 'en', unit: 'meter').format(42),
      contains('42'),
    );
  });

  testWidgets('plural rules pick CLDR categories', (t) async {
    final en = IcuPluralRules.cardinal('en');
    expect(en.category(1), IcuPluralCategory.one);
    expect(en.category(5), IcuPluralCategory.other);
    // Arabic has the full six-category system.
    expect(IcuPluralRules.cardinal('ar').category(0), IcuPluralCategory.zero);
  });

  testWidgets('dates, times, relative time', (t) async {
    final date = DateTime(2026, 7, 10, 14, 30);
    expect(IcuDateFormat.ymd(locale: 'en-US').format(date), 'Jul 10, 2026');
    expect(IcuDateFormat.ymd(locale: 'ja').format(date), '2026/07/10');
    expect(IcuTimeFormat(locale: 'en-US').format(date), contains('2:30'));
    final rel = IcuRelativeTimeFormat(
      locale: 'en',
      unit: IcuRelativeTimeUnit.day,
      numeric: IcuRelativeTimeNumeric.auto,
    );
    expect(rel.format(-1), 'yesterday');
    expect(rel.format(2), 'in 2 days');
  });

  testWidgets('lists join with locale conjunctions', (t) async {
    expect(
      IcuListFormat.and(locale: 'en').format(const ['a', 'b', 'c']),
      'a, b, and c',
    );
    expect(
      IcuListFormat.or(locale: 'fr').format(const ['rouge', 'vert']),
      'rouge ou vert',
    );
  });

  testWidgets('collation — Swedish å/ö sort after z', (t) async {
    final names = ['Östen', 'Anna', 'Åsa'];
    names.sort(IcuCollator(locale: 'sv').compare);
    expect(names, ['Anna', 'Åsa', 'Östen']);
  });

  testWidgets('segmentation — Thai dictionary words', (t) async {
    final words = IcuSegmenter.word(
      locale: 'th',
    ).segments('สวัสดีครับ').map((s) => s.text).toList();
    expect(words, ['สวัส', 'ดี', 'ครับ']);
  });

  testWidgets('case mapping — Turkish İ and German ß', (t) async {
    final cm = IcuCaseMapper();
    expect(cm.uppercase('istanbul', locale: 'tr'), 'İSTANBUL');
    expect(cm.uppercase('straße', locale: 'de'), 'STRASSE');
    expect(cm.lowercase('İSTANBUL', locale: 'tr'), 'istanbul');
  });

  testWidgets('normalization — NFC composes', (t) async {
    final nfc = IcuNormalizer(IcuNormalizationForm.nfc);
    expect(nfc.normalize('e\u{0301}'), 'é');
    expect(nfc.isNormalized('é'), isTrue);
  });

  testWidgets('bidi — mixed-direction analysis', (t) async {
    final analysis = IcuBidi().analyze('Hello مرحبا world');
    expect(analysis.paragraph(0)!.direction, IcuBidiDirection.mixed);
  });

  testWidgets('IDNA round-trips internationalized domains', (t) async {
    final idna = IcuIdna.url();
    expect(idna.toAscii('日本.jp'), 'xn--wgv71a.jp');
    expect(idna.toUnicode('xn--mnchen-3ya.de'), 'münchen.de');
  });

  testWidgets('display names and locale algebra', (t) async {
    expect(IcuRegionDisplayNames(locale: 'fr').of('DE'), 'Allemagne');
    expect(IcuLocale.parse('zh-hant-tw').toString(), 'zh-Hant-TW');
    expect(IcuLocaleExpander().maximize('sr'), 'sr-Cyrl-RS');
    expect(IcuLocaleDirectionality().isRtl('ar'), isTrue);
  });

  // LAST on purpose — re-initializes global engine state twice.
  testWidgets('bundled subset rejects uncovered locales; restore heals', (
    t,
  ) async {
    await IcuKit.init(data: IcuData.bundled(locales: const ['en', 'fr']));
    // French groups with a narrow no-break space; compare loose on the
    // whitespace flavor (CLDR has changed it before), exact on digits.
    final fr = IcuNumberFormat.decimal(locale: 'fr').format(1234.5);
    expect(fr.replaceAll(RegExp(r'\s'), ''), '1234,5');
    expect(
      () => IcuNumberFormat.decimal(locale: 'ja').format(1234.5),
      throwsA(isA<IcuDataError>()),
    );

    await IcuKit.init();
    expect(IcuNumberFormat.decimal(locale: 'ja').format(1234.5), '1,234.5');
  });
}
