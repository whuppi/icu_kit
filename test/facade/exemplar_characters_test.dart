import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuExemplarCharacters — English main set', () {
    late final IcuExemplarCharacters main;
    setUpAll(() {
      main = IcuExemplarCharacters(locale: 'en', set: IcuExemplarSet.main);
    });

    test('contains a-z', () {
      for (var c = 0x61; c <= 0x7A; c++) {
        expect(
          main.contains(c),
          isTrue,
          reason: 'expected ${String.fromCharCode(c)} in en main set',
        );
      }
    });

    test('does NOT contain Cyrillic letters', () {
      // U+0430 а CYRILLIC SMALL LETTER A
      expect(main.contains(0x0430), isFalse);
    });

    test('does NOT contain CJK', () {
      expect(main.contains(0x4E00), isFalse);
    });
  });

  group('IcuExemplarCharacters — English numbers set', () {
    test('contains 0-9', () {
      final numbers = IcuExemplarCharacters(
        locale: 'en',
        set: IcuExemplarSet.numbers,
      );
      for (var c = 0x30; c <= 0x39; c++) {
        expect(
          numbers.contains(c),
          isTrue,
          reason: 'expected ${String.fromCharCode(c)} in numbers set',
        );
      }
    });
  });

  group('IcuExemplarCharacters — Russian main set', () {
    test('contains а-я (Cyrillic lowercase)', () {
      final main = IcuExemplarCharacters(
        locale: 'ru',
        set: IcuExemplarSet.main,
      );
      // U+0430 а CYRILLIC SMALL LETTER A
      expect(main.contains(0x0430), isTrue);
      // U+044F я CYRILLIC SMALL LETTER YA
      expect(main.contains(0x044F), isTrue);
    });

    test('does NOT contain Latin letters', () {
      final main = IcuExemplarCharacters(
        locale: 'ru',
        set: IcuExemplarSet.main,
      );
      expect(main.contains(0x61), isFalse);
    });
  });

  group('IcuExemplarCharacters — containsString', () {
    // Note: ICU4X's contains_str() checks whether the input is a SINGLE
    // multi-character exemplar entry (e.g. "ll" / "ch" digraphs in some
    // locales), NOT a character-by-character scan. For per-codepoint
    // membership, use [contains].

    test('en main contains single letter "a"', () {
      final main = IcuExemplarCharacters(
        locale: 'en',
        set: IcuExemplarSet.main,
      );
      expect(main.containsString('a'), isTrue);
    });

    test('en main does NOT contain multi-char "hello" (no such digraph)', () {
      final main = IcuExemplarCharacters(
        locale: 'en',
        set: IcuExemplarSet.main,
      );
      // English has no "hello" digraph in its exemplar set.
      expect(main.containsString('hello'), isFalse);
    });
  });

  group('IcuExemplarCharacters — index headers', () {
    test('en index headers exist', () {
      final idx = IcuExemplarCharacters(
        locale: 'en',
        set: IcuExemplarSet.indexHeaders,
      );
      // English index headers are A-Z (uppercase).
      expect(idx.contains(0x41), isTrue); // A
      expect(idx.contains(0x5A), isTrue); // Z
    });
  });
}
