// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives ICU4X's own plurals/categories.json fixture through IcuPluralRules.
// Every (langid, plural_type, expected_categories) row is one assertion.
// Failure here means our bindings disagree with ICU4X's reference behavior.
//
// Source: vendor/icu4x/components/plurals/tests/fixtures/categories.json

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuPluralRules — full categories.json corpus', () {
    late final List<dynamic> rows;
    setUpAll(() async {
      rows = await loadJsonFixture('plurals', 'categories') as List<dynamic>;
    });

    test('every row matches supportedCategories exactly', () {
      expect(
        rows,
        isNotEmpty,
        reason: 'corpus is empty — vendor refresh likely broken',
      );
      for (final row in rows) {
        final r = row as Map<String, dynamic>;
        final langid = r['langid'] as String;
        final pluralType = r['plural_type'] as String;
        final expected = (r['categories'] as List)
            .cast<String>()
            .map((c) => IcuPluralCategory.tryParse(c)!)
            .toSet();

        final rules = pluralType == 'Cardinal'
            ? IcuPluralRules.cardinal(langid)
            : IcuPluralRules.ordinal(langid);

        final actual = rules.supportedCategories;
        expect(
          actual,
          expected,
          reason:
              'mismatch for $langid $pluralType: '
              'expected $expected, got $actual',
        );
      }
    });
  });
}
