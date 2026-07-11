// CHARTER — this suite alone proves IcuLocale's own contract, on BOTH
// worlds (the VM and Chrome — the -p flag is the runner; lib's
// conditional exports pick the world): parse() accepts valid BCP-47 tags
// and normalizes case; toString() round-trips the canonical form; an
// invalid tag throws IcuLocaleParseError carrying the offending tag.
// Every other facade suite CONSUMES IcuLocale — this one is about it.
// Diet: the public facade + literals declared in this file.

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocale.parse — valid tags', () {
    test('plain language tag round-trips', () {
      expect(IcuLocale.parse('en').toString(), 'en');
    });

    test('language-region round-trips', () {
      expect(IcuLocale.parse('de-CH').toString(), 'de-CH');
    });

    test('language-script-region round-trips', () {
      expect(IcuLocale.parse('zh-Hant-TW').toString(), 'zh-Hant-TW');
    });

    test('case is normalized to BCP-47 canonical form', () {
      // lowercase region + uppercase script arrive denormalized on purpose.
      expect(IcuLocale.parse('DE-ch').toString(), 'de-CH');
      expect(IcuLocale.parse('zh-hant-tw').toString(), 'zh-Hant-TW');
    });

    test('unicode extension keywords survive', () {
      expect(IcuLocale.parse('th-TH-u-nu-thai').toString(), 'th-TH-u-nu-thai');
    });
  });

  group('IcuLocale.parse — invalid tags fail loud', () {
    test('garbage throws IcuLocaleParseError carrying the tag', () {
      expect(
        () => IcuLocale.parse('not a locale!'),
        throwsA(
          isA<IcuLocaleParseError>().having(
            (e) => e.input,
            'input',
            'not a locale!',
          ),
        ),
      );
    });

    test('empty string throws IcuLocaleParseError', () {
      expect(() => IcuLocale.parse(''), throwsA(isA<IcuLocaleParseError>()));
    });
  });
}
