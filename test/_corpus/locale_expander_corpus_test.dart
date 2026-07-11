// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives ICU4X's locale/maximize.json + locale/minimize.json fixtures
// through IcuLocaleExpander. Every (input, output) row is one assertion.
//
// Source: vendor/icu4x/components/locale/tests/fixtures/{maximize,minimize}.json

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleExpander.maximize — full corpus', () {
    late final List<dynamic> rows;
    late final IcuLocaleExpander expander;
    setUpAll(() async {
      rows = await loadJsonFixture('locale', 'maximize') as List<dynamic>;
      // Upstream's tests/locale_canonicalizer.rs uses new_extended(); the
      // fixture rows reflect the extended likely-subtags data set.
      expander = IcuLocaleExpander(extended: true);
    });

    test('every row produces the expected maximized form', () {
      expect(rows, isNotEmpty);
      for (final row in rows) {
        final r = row as Map<String, dynamic>;
        final input = r['input'] as String;
        final expected = r['output'] as String;
        final actual = expander.maximize(input);
        expect(
          actual,
          expected,
          reason: 'maximize($input): expected $expected, got $actual',
        );
      }
    });
  });

  group('IcuLocaleExpander.minimize — full corpus', () {
    late final List<dynamic> rows;
    late final IcuLocaleExpander expander;
    setUpAll(() async {
      rows = await loadJsonFixture('locale', 'minimize') as List<dynamic>;
      // Upstream's tests/locale_canonicalizer.rs uses new_extended(); the
      // fixture rows reflect the extended likely-subtags data set.
      expander = IcuLocaleExpander(extended: true);
    });

    test('every row produces the expected minimized form', () {
      expect(rows, isNotEmpty);
      for (final row in rows) {
        final r = row as Map<String, dynamic>;
        final input = r['input'] as String;
        final expected = r['output'] as String;
        final actual = expander.minimize(input);
        expect(
          actual,
          expected,
          reason: 'minimize($input): expected $expected, got $actual',
        );
      }
    });
  });
}
