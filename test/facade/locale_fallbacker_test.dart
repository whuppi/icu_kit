import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleFallbacker — language priority (default)', () {
    late final IcuLocaleFallbacker fb;
    setUpAll(() {
      fb = IcuLocaleFallbacker();
    });

    test('en-CA falls back through to en', () {
      final chain = fb.chain('en-CA').toList();
      expect(chain.first, 'en-CA');
      // Should include 'en' (base language) somewhere in the chain.
      expect(chain, contains('en'));
    });

    test('en-Latn-US chain reaches en', () {
      final chain = fb.chain('en-Latn-US').toList();
      expect(chain.first, 'en-Latn-US');
      expect(chain, contains('en'));
    });

    test('zh-Hant-TW chain has multiple steps reaching zh-Hant or zh', () {
      final chain = fb.chain('zh-Hant-TW').toList();
      expect(chain.first, 'zh-Hant-TW');
      expect(chain.length, greaterThan(1));
      // Either 'zh-Hant' or 'zh' should appear as a fallback step.
      final hasBase = chain.contains('zh-Hant') || chain.contains('zh');
      expect(
        hasBase,
        isTrue,
        reason: 'expected zh-Hant or zh in chain, got: $chain',
      );
    });
  });
}
