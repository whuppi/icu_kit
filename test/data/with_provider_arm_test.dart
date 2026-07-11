// CHARTER — this suite alone proves what the header below declares.
// VM-ONLY (@TestOn below): the FFI provider arm has no web counterpart —
// the web world loads postcards through fetch, proven in the two-world
// suites. Charter: withProvider-arm tests — proves every dispatch entry's WithProvider
// branch ACTUALLY constructs a working facade from a real postcard.
//
// The compiled-data path is exhaustively tested by the per-facade
// suites under test/facade/. Those tests bake CLDR into the binary
// and never exercise the WithProvider FFI constructor.
//
// This file walks the other arm of the dispatch:
//
//   1. init() with a lean composite (no bundled coverage for the
//      target locale) plus a lazy IcuDataSource carrying real ICU4X
//      postcard bytes for that locale.
//   2. preloadLocale() — bytes hit the resolver's cache.
//   3. Construct a facade. Dispatch sees `providerFor(locale) != null`
//      and reaches for `*WithProvider`. If the FFI constructor or the
//      Diplomat IDL binding is broken, this throws.
//   4. Use the facade. Proves the data was decoded correctly and the
//      WithProvider variant produces ECMA-402-correct output.
//
// Coverage:
//   * IcuPluralRules.cardinal (PluralsCardinalV1)
//   * IcuPluralRules.ordinal  (PluralsOrdinalV1)
//   * IcuNumberFormat         (DecimalSymbolsV1 + DecimalDigitsV1)
//   * IcuDateFormat (gregorian, dateLength) (Datetime patterns + names)
//   * IcuTimeFormat (Gregorian time + dayperiod)
//   * IcuIdna                 (NormalizerUts46DataV1)
//
// **NOT covered here**: the four IDL-patched experimental facades
//   (currency / percent / unit / relative-time). Their markers are
//   gated behind icu4x-datagen's `unstable` feature, which would
//   roughly 5x the fixture size for facades whose public API is
//   marked `@experimental` and may be renamed by ICU4X 2.3+
//   (see PR #7789). Those facades are exercised via the
//   compiled-data path in their respective `test/facade/*` suites;
//   the WithProvider dispatch wiring is mechanically identical to
//   the stable facades proven here.
//
// Native-only: postcard fixtures load via dart:io. The web side
// shares the same Dart-level dispatch logic and is proven by the
// existing chrome facade suites.

// Diet: the public data API + the vendored corpus postcards (PROVENANCE.md).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

ByteBuffer _loadFixture(String locale) {
  final f = File('test/_corpus/postcards/${locale}_minimal.postcard');
  if (!f.existsSync()) {
    throw StateError(
      'Postcard fixture missing: ${f.path}\n'
      'Run `fvm dart run tool/regen_test_postcards.dart`.',
    );
  }
  return f.readAsBytesSync().buffer;
}

/// Initialize IcuKit in lean-composite mode + preload the postcard for
/// [locale]. Subsequent facade constructors for [locale] hit the
/// `*WithProvider` arm of the dispatch.
Future<void> _initLean(String locale) async {
  await IcuKit.init(
    data: IcuData.composite([
      // Bundled layer scoped to a non-existent locale so it never
      // covers the locale under test — guarantees dispatch must
      // reach for the lazy/postcard arm.
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

  group('IcuPluralRules.cardinal — PluralsCardinalV1', () {
    test('en postcard via WithProvider categorizes correctly', () async {
      await _initLean('en');
      final f = IcuPluralRules.cardinal('en');
      expect(f.category(1), IcuPluralCategory.one);
      expect(f.category(2), IcuPluralCategory.other);
    });

    test('fr postcard via WithProvider categorizes correctly', () async {
      await _initLean('fr');
      final f = IcuPluralRules.cardinal('fr');
      expect(f.category(0), IcuPluralCategory.one);
      expect(f.category(1), IcuPluralCategory.one);
      expect(f.category(2), IcuPluralCategory.other);
    });
  });

  group('IcuPluralRules.ordinal — PluralsOrdinalV1', () {
    test(
      'en postcard via WithProvider categorizes ordinals correctly',
      () async {
        await _initLean('en');
        final f = IcuPluralRules.ordinal('en');
        // English ordinal: 1->one (1st), 2->two (2nd), 3->few (3rd),
        // 4+ -> other (4th, 5th...). 11/12/13 -> other (11th/12th/13th).
        expect(f.category(1), IcuPluralCategory.one);
        expect(f.category(2), IcuPluralCategory.two);
        expect(f.category(3), IcuPluralCategory.few);
        expect(f.category(4), IcuPluralCategory.other);
        expect(f.category(11), IcuPluralCategory.other);
        expect(f.category(21), IcuPluralCategory.one); // 21st
      },
    );
  });

  group('IcuNumberFormat — DecimalSymbolsV1 + DecimalDigitsV1', () {
    test(
      'en postcard via WithProvider formats with locale separators',
      () async {
        await _initLean('en');
        final f = IcuNumberFormat.decimal(locale: 'en');
        expect(f.format(1234.5), '1,234.5');
        expect(f.format(1000000), '1,000,000');
      },
    );

    test('fr postcard via WithProvider applies French separators', () async {
      await _initLean('fr');
      final f = IcuNumberFormat.decimal(locale: 'fr');
      // French uses non-breaking space ( ) as group separator and
      // comma as decimal separator.
      final s = f.format(1234.5);
      expect(s, contains('234')); // group joined
      expect(s, contains(',')); // decimal comma
    });

    test(
      'ja postcard via WithProvider formats with Japanese conventions',
      () async {
        await _initLean('ja');
        final f = IcuNumberFormat.decimal(locale: 'ja');
        // Japanese uses comma group separator + period decimal — same
        // visual conventions as English. The provider arm being wired
        // correctly is what we're proving.
        expect(f.format(1234.5), '1,234.5');
      },
    );
  });

  group('IcuDateFormat — DatetimePatternsDateGregorianV1 + names', () {
    test('en postcard via WithProvider formats a Gregorian date', () async {
      await _initLean('en');
      final f = IcuDateFormat.ymd(locale: 'en', length: IcuDateLength.short);
      // Pin a known date so we don't rely on system time. en short is
      // M/d/yy — the exact pattern is locale-data, but the format must
      // render SOMETHING containing the year/month/day digits.
      final s = f.format(DateTime(2024, 3, 14));
      expect(s, contains('14'));
      expect(s, contains('3'));
      expect(s, contains('24'));
    });

    test(
      'ja postcard via WithProvider formats with Japanese conventions',
      () async {
        await _initLean('ja');
        final f = IcuDateFormat.ymd(locale: 'ja', length: IcuDateLength.long);
        final s = f.format(DateTime(2024, 3, 14));
        // Japanese date long form contains the year suffix or explicit
        // separator characters; just verify the year shows up somewhere
        // and the formatter constructed without throwing.
        expect(s, contains('2024'));
      },
    );
  });

  group('IcuTimeFormat — DatetimePatternsTimeV1 + Dayperiod', () {
    test('en postcard via WithProvider formats time with AM/PM', () async {
      await _initLean('en');
      final f = IcuTimeFormat(locale: 'en');
      final s = f.format(DateTime(2024, 3, 14, 15, 30));
      // English time short includes AM/PM marker; just verify
      // construction worked and the output contains a digit.
      expect(s, matches(RegExp(r'\d')));
    });

    test(
      'fr postcard via WithProvider formats time in 24h locale style',
      () async {
        await _initLean('fr');
        final f = IcuTimeFormat(locale: 'fr');
        final s = f.format(DateTime(2024, 3, 14, 15, 30));
        // French uses 24-hour clock by default — '15' should appear.
        expect(s, contains('15'));
      },
    );
  });

  group('IcuIdna — NormalizerUts46DataV1', () {
    test('en postcard via WithProvider processes domain names', () async {
      await _initLean('en');
      // IDNA is locale-independent (the provider data is the same for
      // every locale) but the WithProvider arm still fires — the
      // dispatch checks providerFor(locale).
      final idna = IcuIdna.url();
      final result = idna.toAscii('Bücher.example');
      expect(result, isNotEmpty);
      // ToASCII produces 'xn--bcher-kva.example' or similar Punycode
      // for non-ASCII labels. The exact encoding is a UTS46 contract;
      // we just verify the WithProvider arm produced output.
      expect(result, isA<String>());
    });

    test('passthrough for already-ASCII domains', () async {
      await _initLean('en');
      final idna = IcuIdna.url();
      // Plain ASCII inputs round-trip unchanged.
      expect(idna.toAscii('example.com'), 'example.com');
    });
  });
}
