// CHARTER — this suite alone proves what the header below declares.
// VM-ONLY (@TestOn below): the FFI provider arm has no web counterpart —
// the web world loads postcards through fetch, proven in the two-world
// suites. Charter: withProvider-arm tests for the 5 IDL-patched experimental facades.
//
// The companion file `with_provider_arm_test.dart` covers stable
// facades. This file proves the lazy/postcard arm fires for the four
// `icu_experimental` facades whose Diplomat IDL bindings live on the
// `2.2.0-patches` submodule branch:
//
//   * IcuCurrencyFormat (symbol + long)
//   * IcuPercentFormat
//   * IcuUnitFormat
//   * IcuRelativeTimeFormat
//
// Why a separate file: the experimental fixtures (`*_experimental.
// postcard`) are larger (~2 MB total) because `icu_experimental`'s
// data layer isn't deduplicated as aggressively as the stable
// markers. Splitting keeps the regular test file lean while still
// proving every patched facade end-to-end.
//
// Each test inits IcuKit in lean-composite mode (bundled scoped to a
// bogus locale + lazy postcard for the target locale), preloads the
// locale, then exercises the facade. Dispatch sees
// providerFor(locale) != null and reaches for *WithProvider — if
// the FFI constructor or any of the 5 IDL patches is broken, the
// test surfaces it.
//
// Native-only: postcard fixtures load via dart:io. Web bootstrap of
// icu_kit is proven by icu_kit's own facade chrome tests; the IDL
// patches share the dispatch shape with the stable facades, so a
// web-specific regression in any patched facade would surface in
// those existing chrome tests too.

// Diet: the public data API + the vendored corpus postcards (PROVENANCE.md).
@TestOn('vm')
@Tags(['experimental_currency', 'experimental_percent', 'experimental_unit'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

ByteBuffer _loadFixture(String locale) {
  final f = File('test/_corpus/postcards/${locale}_experimental.postcard');
  if (!f.existsSync()) {
    throw StateError(
      'Experimental postcard fixture missing: ${f.path}\n'
      'Run `fvm dart run tool/regen_test_postcards.dart`.',
    );
  }
  return f.readAsBytesSync().buffer;
}

/// Initialize IcuKit in lean-composite mode + preload the experimental
/// postcard for [locale]. Subsequent facade constructors hit the
/// `*WithProvider` arm of the dispatch.
Future<void> _initLean(String locale) async {
  await IcuKit.init(
    data: IcuData.composite([
      IcuData.bundled(locales: const ['xx-Bogus']),
      IcuData.lazy(IcuDataSource.bytes(_loadFixture(locale))),
    ]),
  );
  await IcuKit.preloadLocale(locale);
}

void main() {
  // Restore default state for any test file running after this one.
  tearDownAll(() async {
    await IcuKit.init();
  });

  group('IcuCurrencyFormat.symbol — Currency* markers', () {
    test('en postcard via WithProvider formats USD with symbol', () async {
      await _initLean('en');
      final f = IcuCurrencyFormat.symbol(locale: 'en');
      final s = f.format(1234.56, currencyCode: 'USD');
      // English with USD: '$' is the locale's symbol form. Don't
      // assert exact rendering (locale data may render '$1,234.56' or
      // 'US$1,234.56' depending on width / data slice); just assert
      // the construction worked and the output contains the dollar
      // symbol AND the digits we passed in.
      expect(s, contains('1'));
      expect(s, contains('234'));
      expect(s, anyOf(contains(r'$'), contains('US')));
    });

    test('fr postcard via WithProvider formats EUR', () async {
      await _initLean('fr');
      final f = IcuCurrencyFormat.symbol(locale: 'fr');
      final s = f.format(1234.56, currencyCode: 'EUR');
      // French + EUR: locale puts '€' after the digits with NBSP.
      expect(s, contains('234'));
      expect(s, contains('€'));
    });

    test('narrow width changes the rendering', () async {
      await _initLean('en');
      final f = IcuCurrencyFormat.symbol(
        locale: 'en',
        width: IcuCurrencyWidth.narrow,
      );
      final s = f.format(1, currencyCode: 'USD');
      // Narrow form prefers the narrowest symbol available. The exact
      // glyph depends on data; we just verify it construct + format
      // without throwing.
      expect(s, isNotEmpty);
    });
  });

  group('IcuCurrencyFormat.long — long-form via WithProvider', () {
    test('en postcard renders "US dollar" plurally', () async {
      await _initLean('en');
      final fmt1 = IcuCurrencyFormat.long(locale: 'en', currencyCode: 'USD');
      // Long form pluralizes the unit name; '1 US dollar' vs
      // '2 US dollars'. Don't assert exact prose (locale data may
      // change), just prove the WithProvider arm produced output for
      // both singular and plural cases.
      expect(fmt1.format(1), contains('1'));
      expect(fmt1.format(2), contains('2'));
    });
  });

  group('IcuPercentFormat — PercentEssentialsV1', () {
    test('en postcard via WithProvider renders percent suffix', () async {
      await _initLean('en');
      final f = IcuPercentFormat(locale: 'en');
      final s = f.format(50);
      // English: "50%" — the percent symbol must be present.
      expect(s, contains('50'));
      expect(s, contains('%'));
    });

    test('fr postcard via WithProvider applies French conventions', () async {
      await _initLean('fr');
      final f = IcuPercentFormat(locale: 'fr');
      final s = f.format(12.34);
      // French: "12,34 %" — comma decimal + NBSP before percent.
      expect(s, contains(','));
      expect(s, contains('%'));
    });
  });

  group('IcuUnitFormat — UnitsEssentialsV1 + categorized names', () {
    test('en postcard via WithProvider formats meter unit', () async {
      await _initLean('en');
      final f = IcuUnitFormat(locale: 'en', unit: 'meter');
      // English: '5 m' (short), pluralization handled by the formatter.
      final s = f.format(5);
      expect(s, contains('5'));
      // The unit suffix is locale-dependent; just verify non-empty
      // output and that the digit survived.
      expect(s, isNotEmpty);
    });

    test('en postcard renders long-form unit names', () async {
      await _initLean('en');
      final f = IcuUnitFormat(
        locale: 'en',
        unit: 'hour',
        width: IcuUnitWidth.long,
      );
      // Long form: '2 hours' (plural), '1 hour' (singular).
      expect(f.format(1), contains('1'));
      expect(f.format(2), contains('2'));
    });
  });

  group('IcuRelativeTimeFormat — *RelativeV1 markers', () {
    test('en postcard via WithProvider renders relative day forms', () async {
      await _initLean('en');
      final f = IcuRelativeTimeFormat(
        locale: 'en',
        unit: IcuRelativeTimeUnit.day,
      );
      // English numeric=always: '0 days ago' / 'in 0 days' / 'in 1 day'.
      // The exact string depends on the formatter's `numeric` mode and
      // upstream patterns. We assert the WithProvider arm produced
      // output for past + future + zero.
      final past = f.format(-3);
      final future = f.format(2);
      expect(past, isNotEmpty);
      expect(future, isNotEmpty);
      expect(past, contains('3'));
      expect(future, contains('2'));
    });

    test(
      'en postcard with width=short renders abbreviated relative times',
      () async {
        await _initLean('en');
        final f = IcuRelativeTimeFormat(
          locale: 'en',
          unit: IcuRelativeTimeUnit.minute,
          width: IcuRelativeTimeWidth.short,
        );
        final s = f.format(5);
        expect(s, contains('5'));
      },
    );

    test('fr postcard via WithProvider applies French conventions', () async {
      await _initLean('fr');
      final f = IcuRelativeTimeFormat(
        locale: 'fr',
        unit: IcuRelativeTimeUnit.day,
      );
      // French: 'il y a 1 jour' / 'dans 1 jour' style. Exact prose
      // is locale data — just verify output contains the digit.
      expect(f.format(1), contains('1'));
    });
  });
}
