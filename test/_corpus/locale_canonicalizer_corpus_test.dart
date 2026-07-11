// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives ICU4X's locale/canonicalize.json + locale_core/canonicalize.json
// fixtures through IcuLocaleCanonicalizer + IcuLocale.toString().
//
// String-form rows from both corpora drive IcuLocaleCanonicalizer.canonicalize.
// Pure-syntactic locale_core canonicalization (just IcuLocale.parse + toString)
// covers the locale_core string entries.
//
// Source: vendor/icu4x/components/{locale,locale_core}/tests/fixtures/canonicalize.json

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleCanonicalizer — full locale/canonicalize.json corpus', () {
    late final List<dynamic> rows;
    late final IcuLocaleCanonicalizer canonicalizer;
    setUpAll(() async {
      rows = await loadJsonFixture('locale', 'canonicalize') as List<dynamic>;
      // Upstream's tests/locale_canonicalizer.rs uses new_extended(); the
      // fixture rows reflect the extended alias data set.
      canonicalizer = IcuLocaleCanonicalizer(extended: true);
    });

    test('every enabled string row canonicalizes correctly', () {
      expect(rows, isNotEmpty);
      var seen = 0;
      for (final row in rows) {
        final r = row as Map<String, dynamic>;
        if (r['disabled'] == true) continue;
        final input = r['input'];
        final expected = r['output'];
        if (input is! String || expected is! String) continue;

        final actual = canonicalizer.canonicalize(input);
        expect(
          actual,
          expected,
          reason: 'canonicalize($input): expected $expected, got $actual',
        );
        seen++;
      }
      expect(
        seen,
        greaterThan(50),
        reason: 'expected at least 50 rows; got $seen',
      );
    });
  });

  group('IcuLocale — locale_core/canonicalize.json string-form rows', () {
    late final List<dynamic> rows;
    setUpAll(() async {
      rows =
          await loadJsonFixture('locale_core', 'canonicalize') as List<dynamic>;
    });

    test('every string-form row round-trips through parse + toString', () {
      var seen = 0;
      for (final row in rows) {
        final r = row as Map<String, dynamic>;
        final input = r['input'];
        final expected = r['output'];
        if (input is! String || expected is! String) continue;

        final actual = IcuLocale.parse(input).toString();
        expect(
          actual,
          expected,
          reason: 'parse+toString($input): expected $expected, got $actual',
        );
        seen++;
      }
      expect(
        seen,
        greaterThan(0),
        reason: 'expected string-form rows in locale_core/canonicalize.json',
      );
    });
  });
}
