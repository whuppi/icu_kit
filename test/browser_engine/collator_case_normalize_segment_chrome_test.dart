// §3f collation / case mapping / normalization / segmentation on the browser
// engine. Behaviour verified against Intl.Collator, String.toLocale*Case,
// String.normalize, Intl.Segmenter. Engine-gap methods surface as
// IcuUnsupportedError.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  group('IcuCollator (PARTIAL)', () {
    test('tertiary orders a < b', () {
      final c = IcuCollator(locale: 'en-US');
      expect(c.compare('a', 'b'), lessThan(0));
      expect(c.compare('b', 'a'), greaterThan(0));
      expect(c.compare('a', 'a'), 0);
    });
    test('primary strength ignores case', () {
      final c = IcuCollator(
        locale: 'en-US',
        strength: IcuCollatorStrength.primary,
      );
      expect(c.compare('A', 'a'), 0);
    });
    test('quaternary strength throws (no browser equivalent)', () {
      expect(
        () => IcuCollator(
          locale: 'en-US',
          strength: IcuCollatorStrength.quaternary,
        ),
        throwsA(isA<IcuUnsupportedError>()),
      );
    });
    test('caseLevel On throws (browser Intl has no case level)', () {
      expect(
        () => IcuCollator(locale: 'en-US', caseLevel: IcuCollatorCaseLevel.on),
        throwsA(isA<IcuUnsupportedError>()),
      );
    });
    test('non-punctuation maxVariable under shifted throws', () {
      expect(
        () => IcuCollator(
          locale: 'en-US',
          alternateHandling: IcuCollatorAlternateHandling.shifted,
          maxVariable: IcuCollatorMaxVariable.symbol,
        ),
        throwsA(isA<IcuUnsupportedError>()),
      );
    });
  });

  group('IcuCaseMapper', () {
    test('lowercase / uppercase (ASCII)', () {
      final m = IcuCaseMapper();
      expect(m.lowercase('HELLO', locale: 'en-US'), 'hello');
      expect(m.uppercase('hello', locale: 'en-US'), 'HELLO');
    });
    test('Turkish dotless-i via locale', () {
      final m = IcuCaseMapper();
      // tr: uppercasing 'i' yields dotted capital İ.
      expect(m.uppercase('i', locale: 'tr'), 'İ');
    });
    test('fold throws (no browser case-folding)', () {
      final m = IcuCaseMapper();
      expect(() => m.fold('Hello'), throwsA(isA<IcuUnsupportedError>()));
    });
    test('foldTurkic throws', () {
      final m = IcuCaseMapper();
      expect(() => m.foldTurkic('Hello'), throwsA(isA<IcuUnsupportedError>()));
    });
  });

  group('IcuNormalizer (FULL)', () {
    test('NFC composes decomposed é', () {
      final n = IcuNormalizer(IcuNormalizationForm.nfc);
      const decomposed = 'é'; // e + combining acute
      const composed = 'é'; // é
      expect(n.normalize(decomposed), composed);
      expect(n.isNormalized(composed), isTrue);
      expect(n.isNormalized(decomposed), isFalse);
    });
    test('NFD decomposes precomposed é', () {
      final n = IcuNormalizer(IcuNormalizationForm.nfd);
      const decomposed = 'é';
      const composed = 'é';
      expect(n.normalize(composed), decomposed);
      expect(n.isNormalized(decomposed), isTrue);
    });
  });

  group('IcuSegmenter', () {
    test('grapheme boundaries over a surrogate-pair cluster', () {
      final seg = IcuSegmenter.grapheme();
      // "a👍b": 'a'@0, '👍'@1 (UTF-16 len 2), 'b'@3, length 4.
      final bounds = seg.boundaries('a\u{1F44D}b');
      expect(bounds.first, 0);
      expect(bounds.last, 'a\u{1F44D}b'.length);
      expect(bounds, [0, 1, 3, 4]);
    });
    test('word boundaries split on the space', () {
      final seg = IcuSegmenter.word();
      final bounds = seg.boundaries('foo bar');
      expect(bounds.first, 0);
      expect(bounds.last, 'foo bar'.length);
      expect(bounds, contains(3)); // end of 'foo'
    });
    test('streams a long mixed BMP + surrogate input without drift', () {
      // Exercises the lazy break-iterator's streaming loop + tail over many
      // clusters: 'a' (1 UTF-16 unit) then '👍' (surrogate pair, 2 units).
      final seg = IcuSegmenter.grapheme();
      final input = 'a\u{1F44D}' * 1500; // 3000 clusters, 4500 UTF-16 units
      final bounds = seg.boundaries(input);
      expect(bounds.length, 3001); // one per cluster start + trailing length
      expect(bounds.first, 0);
      expect(bounds.last, input.length); // 4500
      expect(bounds.take(5), [0, 1, 3, 4, 6]); // a@0 👍@1 a@3 👍@4 a@6
      // Strictly increasing — no boundary dropped or duplicated across the run.
      for (var i = 1; i < bounds.length; i++) {
        expect(bounds[i], greaterThan(bounds[i - 1]));
      }
    });
  });
}
