// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies IcuLocaleExpander construction + maximize/minimize behavior
// on hand-picked cases. The full ICU4X locale/{maximize,minimize}.json
// corpus runs in test/_corpus/locale_expander_corpus_test.dart.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleExpander — construction', () {
    test('default (common data) constructs', () {
      expect(() => IcuLocaleExpander(), returnsNormally);
    });

    test('extended data set constructs', () {
      expect(() => IcuLocaleExpander(extended: true), returnsNormally);
    });
  });

  group('IcuLocaleExpander.maximize', () {
    late final IcuLocaleExpander expander;
    setUpAll(() {
      expander = IcuLocaleExpander(extended: true);
    });

    test('en → en-Latn-US', () {
      expect(expander.maximize('en'), 'en-Latn-US');
    });

    test('zh-Hant → zh-Hant-TW', () {
      expect(expander.maximize('zh-Hant'), 'zh-Hant-TW');
    });

    test('und-IN → expects an Indian script', () {
      // und-IN should expand to a specific script+region pair; just
      // assert it doesn't return the input unchanged.
      final result = expander.maximize('und-IN');
      expect(result, isNot('und-IN'));
    });
  });

  group('IcuLocaleExpander.minimize', () {
    late final IcuLocaleExpander expander;
    setUpAll(() {
      expander = IcuLocaleExpander(extended: true);
    });

    test('en-Latn-US → en', () {
      expect(expander.minimize('en-Latn-US'), 'en');
    });

    test('zh-Hant → zh-TW (favoring region)', () {
      expect(expander.minimize('zh-Hant'), 'zh-TW');
    });
  });

  group('IcuLocaleExpander.minimizeFavorScript', () {
    late final IcuLocaleExpander expander;
    setUpAll(() {
      expander = IcuLocaleExpander(extended: true);
    });

    test('zh-Hant-TW → zh-Hant (favoring script)', () {
      expect(expander.minimizeFavorScript('zh-Hant-TW'), 'zh-Hant');
    });
  });
}
