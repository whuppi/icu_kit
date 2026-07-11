// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies Unicode property lookups via static helpers AND reusable sets.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuProperties — basic letter classification', () {
    test('A is alphabetic + uppercase', () {
      expect(IcuProperties.isAlphabetic(0x41), isTrue);
      expect(IcuProperties.isUppercase(0x41), isTrue);
      expect(IcuProperties.isLowercase(0x41), isFalse);
    });

    test('a is alphabetic + lowercase', () {
      expect(IcuProperties.isAlphabetic(0x61), isTrue);
      expect(IcuProperties.isLowercase(0x61), isTrue);
      expect(IcuProperties.isUppercase(0x61), isFalse);
    });

    test('1 is not alphabetic', () {
      expect(IcuProperties.isAlphabetic(0x31), isFalse);
    });

    test('space is whitespace', () {
      expect(IcuProperties.isWhitespace(0x20), isTrue);
    });

    test('A is not whitespace', () {
      expect(IcuProperties.isWhitespace(0x41), isFalse);
    });
  });

  group('IcuProperties — digits', () {
    test('5 is hex digit', () {
      expect(IcuProperties.isHexDigit(0x35), isTrue);
    });

    test('A (0x41) is hex digit', () {
      expect(IcuProperties.isHexDigit(0x41), isTrue);
    });

    test('G is NOT hex digit', () {
      expect(IcuProperties.isHexDigit(0x47), isFalse);
    });
  });

  group('IcuProperties — emoji', () {
    test('🚀 is emoji', () {
      expect(IcuProperties.isEmoji(0x1F680), isTrue);
    });

    test('🚀 is emoji-presentation', () {
      expect(IcuProperties.isEmojiPresentation(0x1F680), isTrue);
    });

    test('A is not emoji', () {
      expect(IcuProperties.isEmoji(0x41), isFalse);
    });

    test('# (0x23) is emoji-component but not emoji-presentation', () {
      // Number sign # IS an emoji component (used in keycap sequences)
      // but doesn't render as emoji on its own.
      expect(IcuProperties.has(0x23, IcuBinaryProperty.emojiComponent), isTrue);
      expect(IcuProperties.isEmojiPresentation(0x23), isFalse);
    });
  });

  group('IcuProperties — identifier rules (XID)', () {
    test('A is XID-Start', () {
      expect(IcuProperties.isXidStart(0x41), isTrue);
    });

    test('1 is XID-Continue but not XID-Start', () {
      expect(IcuProperties.isXidContinue(0x31), isTrue);
      expect(IcuProperties.isXidStart(0x31), isFalse);
    });

    test('hyphen is neither', () {
      expect(IcuProperties.isXidStart(0x2D), isFalse);
      expect(IcuProperties.isXidContinue(0x2D), isFalse);
    });
  });

  group('IcuPropertySet — reusable set queries', () {
    late final IcuPropertySet alpha;
    setUpAll(() {
      alpha = IcuPropertySet.forBinary(IcuBinaryProperty.alphabetic);
    });

    test('contains: A yes, 1 no', () {
      expect(alpha.contains(0x41), isTrue);
      expect(alpha.contains(0x31), isFalse);
    });

    test('contains: Greek α yes', () {
      expect(alpha.contains(0x03B1), isTrue);
    });

    test('contains: emoji 🚀 no (not alphabetic)', () {
      expect(alpha.contains(0x1F680), isFalse);
    });
  });

  group('IcuProperties — generic has() with enum', () {
    test('has(A, alphabetic) true', () {
      expect(IcuProperties.has(0x41, IcuBinaryProperty.alphabetic), isTrue);
    });

    test('has(_, math) true for + and ÷', () {
      expect(IcuProperties.has(0x2B, IcuBinaryProperty.math), isTrue);
      expect(IcuProperties.has(0x00F7, IcuBinaryProperty.math), isTrue);
    });

    test('has(_, regionalIndicator) true for 🇯', () {
      // U+1F1EF REGIONAL INDICATOR SYMBOL LETTER J
      expect(
        IcuProperties.has(0x1F1EF, IcuBinaryProperty.regionalIndicator),
        isTrue,
      );
    });

    test('has(A, regionalIndicator) false', () {
      expect(
        IcuProperties.has(0x41, IcuBinaryProperty.regionalIndicator),
        isFalse,
      );
    });
  });
}
