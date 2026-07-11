// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies IcuLocaleCanonicalizer construction + canonicalize behavior
// on hand-picked cases. The full ICU4X locale/canonicalize.json corpus
// runs in test/_corpus/locale_canonicalizer_corpus_test.dart.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleCanonicalizer — construction', () {
    test('default (common data) constructs', () {
      expect(() => IcuLocaleCanonicalizer(), returnsNormally);
    });

    test('extended data set constructs', () {
      expect(() => IcuLocaleCanonicalizer(extended: true), returnsNormally);
    });
  });

  group('IcuLocaleCanonicalizer.canonicalize — common cases', () {
    late final IcuLocaleCanonicalizer canonicalizer;
    setUpAll(() {
      canonicalizer = IcuLocaleCanonicalizer(extended: true);
    });

    test('mixed-case → properly cased', () {
      expect(canonicalizer.canonicalize('Pl'), 'pl');
      expect(canonicalizer.canonicalize('eN-uS'), 'en-US');
    });

    test('CLDR alias → canonical form', () {
      // cka → cmr per CLDR alias rules (Khumi Chin)
      expect(canonicalizer.canonicalize('cka'), 'cmr');
      // nob-bokmal → nb (Norwegian Bokmål)
      expect(canonicalizer.canonicalize('nob-bokmal'), 'nb');
    });
  });
}
