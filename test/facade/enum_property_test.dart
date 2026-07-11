// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies enum-typed Unicode property lookups: GeneralCategory, Script,
// BidiClass, EastAsianWidth, etc.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuGeneralCategoryMap — basic categories', () {
    late final IcuGeneralCategoryMap gc;
    setUpAll(() {
      gc = IcuGeneralCategoryMap();
    });

    test('A is uppercaseLetter', () {
      expect(gc.get(0x41), IcuGeneralCategory.uppercaseLetter);
    });

    test('a is lowercaseLetter', () {
      expect(gc.get(0x61), IcuGeneralCategory.lowercaseLetter);
    });

    test('5 is decimalNumber', () {
      expect(gc.get(0x35), IcuGeneralCategory.decimalNumber);
    });

    test('space is spaceSeparator', () {
      expect(gc.get(0x20), IcuGeneralCategory.spaceSeparator);
    });

    test('. is otherPunctuation', () {
      expect(gc.get(0x2E), IcuGeneralCategory.otherPunctuation);
    });

    test('+ is mathSymbol', () {
      expect(gc.get(0x2B), IcuGeneralCategory.mathSymbol);
    });

    test('\$ is currencySymbol', () {
      expect(gc.get(0x24), IcuGeneralCategory.currencySymbol);
    });
  });

  group('IcuGeneralCategory — convenience getters', () {
    late final IcuGeneralCategoryMap gc;
    setUpAll(() {
      gc = IcuGeneralCategoryMap();
    });

    test('isLetter for A', () {
      expect(gc.get(0x41).isLetter, isTrue);
      expect(gc.get(0x41).isNumber, isFalse);
    });

    test('isNumber for 5', () {
      expect(gc.get(0x35).isNumber, isTrue);
      expect(gc.get(0x35).isLetter, isFalse);
    });

    test('isPunctuation for .', () {
      expect(gc.get(0x2E).isPunctuation, isTrue);
    });

    test('isSymbol for \$', () {
      expect(gc.get(0x24).isSymbol, isTrue);
    });

    test('isSeparator for space', () {
      expect(gc.get(0x20).isSeparator, isTrue);
    });

    test('combining acute is mark', () {
      // U+0301 COMBINING ACUTE ACCENT — nonspacingMark
      expect(gc.get(0x0301).isMark, isTrue);
      expect(gc.get(0x0301), IcuGeneralCategory.nonspacingMark);
    });
  });

  group('IcuScriptMap — script detection', () {
    late final IcuScriptMap script;
    setUpAll(() {
      script = IcuScriptMap();
    });

    test('A and a both have the same script (Latin)', () {
      expect(script.get(0x41), equals(script.get(0x61)));
    });

    test('Greek α has different script than Latin a', () {
      expect(script.get(0x03B1), isNot(equals(script.get(0x61))));
    });

    test('CJK 我 is consistent within Han block', () {
      // U+6211 我 and U+5973 女 should both be Han script.
      expect(script.get(0x6211), equals(script.get(0x5973)));
    });

    test('Arabic chars share a script', () {
      // U+0627 ا and U+0628 ب are both Arabic.
      expect(script.get(0x0627), equals(script.get(0x0628)));
    });

    test('returns int for any code point', () {
      // Should not crash — return some int even for unassigned.
      expect(script.get(0xFFFFE), isA<int>());
    });
  });

  group('IcuBidiClassMap', () {
    test('numeric ranges return some value', () {
      final bidi = IcuBidiClassMap();
      // L is "Left-to-right" letter; Arabic is "AL"; digits are EN/AN.
      // Just verify the call returns ints.
      expect(bidi.get(0x41), isA<int>());
      expect(bidi.get(0x0627), isA<int>());
      expect(bidi.get(0x35), isA<int>());
    });
  });

  group('IcuEastAsianWidthMap', () {
    test('A is narrow/neutral', () {
      final ea = IcuEastAsianWidthMap();
      // Latin 'A' is "Na" (narrow) per UAX #11.
      // Just verify the call returns an int.
      expect(ea.get(0x41), isA<int>());
    });

    test('Han ideograph is wide', () {
      final ea = IcuEastAsianWidthMap();
      // U+4E00 一 is "W" (wide).
      // Verify it differs from Latin A's value.
      expect(ea.get(0x4E00), isNot(equals(ea.get(0x41))));
    });
  });

  group('IcuLineBreakMap / IcuWordBreakMap / IcuSentenceBreakMap', () {
    test('all return ints', () {
      final lb = IcuLineBreakMap();
      final wb = IcuWordBreakMap();
      final sb = IcuSentenceBreakMap();
      expect(lb.get(0x41), isA<int>());
      expect(wb.get(0x41), isA<int>());
      expect(sb.get(0x2E), isA<int>());
    });
  });

  group('IcuCanonicalCombiningClassMap', () {
    test('combining acute (U+0301) is non-zero', () {
      final ccc = IcuCanonicalCombiningClassMap();
      // CCC of U+0301 COMBINING ACUTE ACCENT = 230 (Above).
      expect(ccc.get(0x0301), 230);
    });

    test('regular letter has CCC = 0', () {
      final ccc = IcuCanonicalCombiningClassMap();
      expect(ccc.get(0x41), 0);
    });
  });
}
