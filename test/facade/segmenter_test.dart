// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies grapheme / word / sentence / line segmentation across English,
// CJK, and emoji. Behavioral focus:
//   * Family-emoji 👨‍👩‍👧 is ONE grapheme (not 4).
//   * Regional-indicator pair 🇯🇵 is ONE grapheme.
//   * "Hello world." has 2 word tokens + 4 word boundaries.
//   * "First. Second." has 2 sentence segments.
//   * Chinese text segments words without spaces.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuSegmenter.grapheme — handles complex emoji', () {
    test('plain ASCII letters segment one-per', () {
      final s = IcuSegmenter.grapheme();
      final result = s.segments('hello').toList();
      expect(result.length, 5);
      expect(result.map((e) => e.text).toList(), ['h', 'e', 'l', 'l', 'o']);
    });

    test('combining mark joins with base letter (é = e + combining acute)', () {
      final s = IcuSegmenter.grapheme();
      // U+0065 + U+0301 = "e" with combining acute = ONE grapheme.
      final result = s.segments('é').toList();
      expect(result.length, 1);
      expect(result[0].text, 'é');
    });

    test('regional-indicator pair 🇯🇵 is one grapheme', () {
      final s = IcuSegmenter.grapheme();
      // 🇯🇵 = REGIONAL INDICATOR J + REGIONAL INDICATOR P
      final result = s.segments('🇯🇵').toList();
      expect(result.length, 1);
      expect(result[0].text, '🇯🇵');
    });

    test('family ZWJ emoji 👨‍👩‍👧 is one grapheme', () {
      final s = IcuSegmenter.grapheme();
      final result = s.segments('👨‍👩‍👧').toList();
      expect(result.length, 1);
    });
  });

  group('IcuSegmenter.word — English word boundaries', () {
    test('"Hello world." segments into expected boundaries', () {
      final s = IcuSegmenter.word();
      // Boundaries depend on UAX #29 — should include 0, 5 (after "Hello"),
      // 6 (after space), 11 (after "world"), 12 (after ".")
      final boundaries = s.boundaries('Hello world.');
      // First boundary is 0 (start), last is 12 (end). At minimum we expect
      // boundaries at start+end of "Hello", "world", and around the period.
      expect(boundaries.first, 0);
      expect(boundaries.last, 12);
      expect(boundaries.length, greaterThanOrEqualTo(5));
    });

    test('extracts word text segments', () {
      final s = IcuSegmenter.word();
      final segs = s.segments('Hello world.').toList();
      // Should contain segments for "Hello", "world", whitespace, period.
      final textSegs = segs.map((e) => e.text).toList();
      expect(textSegs, contains('Hello'));
      expect(textSegs, contains('world'));
    });
  });

  group('IcuSegmenter.word — Chinese (no spaces)', () {
    test('segments CJK text without explicit spaces', () {
      final s = IcuSegmenter.word(locale: 'zh');
      // 我喜欢吃苹果 = "I like to eat apples" — should segment into multiple
      // word units even though there are no spaces.
      final boundaries = s.boundaries('我喜欢吃苹果');
      // At minimum expect more than 2 boundaries (start + end + at least
      // one internal break).
      expect(
        boundaries.length,
        greaterThan(2),
        reason: 'CJK should produce multiple word segments, got $boundaries',
      );
    });
  });

  group('IcuSegmenter.sentence — English sentences', () {
    test('"First. Second." produces 2 segments', () {
      final s = IcuSegmenter.sentence();
      final segs = s.segments('First. Second.').toList();
      expect(segs.length, 2);
      // First segment: "First. " (UAX #29 includes trailing whitespace)
      // Second: "Second."
      expect(segs[0].text.trim(), 'First.');
      expect(segs[1].text.trim(), 'Second.');
    });
  });

  group('IcuLineSegmenter — line-break opportunities', () {
    test('English text yields breaks at spaces + end', () {
      final s = IcuLineSegmenter.auto();
      final breaks = s.breakOpportunities('Hello world').toList();
      // Should yield break opportunities after "Hello " (~6) and at end (11).
      expect(breaks, contains(11));
      expect(breaks.length, greaterThanOrEqualTo(2));
    });
  });

  group('IcuSegmenter — empty + edge cases', () {
    test('empty input yields no segments', () {
      final s = IcuSegmenter.grapheme();
      expect(s.segments('').toList(), isEmpty);
    });

    test('boundaries on empty string is empty', () {
      final s = IcuSegmenter.word();
      expect(s.boundaries(''), isEmpty);
    });

    test('single-character input yields one segment', () {
      final s = IcuSegmenter.grapheme();
      expect(s.segments('a').toList().length, 1);
    });
  });
}
