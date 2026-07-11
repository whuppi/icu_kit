// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies name ↔ code resolution for enum-typed Unicode properties.
// Most useful: round-trip a script name through code lookups + verify
// IcuScriptMap.get returns the same code.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuPropertyName.script — Latin', () {
    late final IcuPropertyName names;
    late final IcuScriptMap map;
    setUpAll(() {
      names = IcuPropertyName.script();
      map = IcuScriptMap();
    });

    test('codeFor("Latin") returns a positive int', () {
      final code = names.codeFor('Latin');
      expect(code, isNotNull);
      expect(code!, greaterThanOrEqualTo(0));
    });

    test('codeFor("Latin") matches IcuScriptMap.get(0x41)', () {
      final code = names.codeFor('Latin');
      expect(map.get(0x41), equals(code));
    });

    test('codeFor("Cyrillic") differs from Latin', () {
      final latin = names.codeFor('Latin');
      final cyr = names.codeFor('Cyrillic');
      expect(latin, isNotNull);
      expect(cyr, isNotNull);
      expect(latin, isNot(cyr));
    });

    test('codeFor("Cyrillic") matches map.get for а (Cyrillic A)', () {
      final cyr = names.codeFor('Cyrillic');
      // U+0430 а CYRILLIC SMALL LETTER A
      expect(map.get(0x0430), equals(cyr));
    });

    test('codeFor for unknown name returns null', () {
      expect(names.codeFor('NotARealScript'), isNull);
    });
  });

  group('IcuPropertyName.script — short names + loose lookup', () {
    test('codeFor("Latn") (short alias) returns same code as "Latin"', () {
      final names = IcuPropertyName.script();
      final long = names.codeFor('Latin');
      final short = names.codeFor('Latn');
      expect(long, equals(short));
    });

    test('codeForLoose ignores case + spaces', () {
      final names = IcuPropertyName.script();
      final strict = names.codeFor('Latin');
      // Loose: "latin", "LATIN", "lat in" all match.
      expect(names.codeForLoose('latin'), equals(strict));
      expect(names.codeForLoose('LATIN'), equals(strict));
    });
  });

  group('IcuPropertyName.script — reverse lookup (nameOf)', () {
    test('nameOf round-trips long names', () {
      final names = IcuPropertyName.script();
      final code = names.codeFor('Latin');
      expect(code, isNotNull);
      final back = names.nameOf(code!);
      expect(back, 'Latin');
    });

    test('nameOf with short=true returns short alias', () {
      final names = IcuPropertyName.script();
      final code = names.codeFor('Latin');
      expect(code, isNotNull);
      final short = names.nameOf(code!, short: true);
      expect(short, 'Latn');
    });
  });

  group('IcuPropertyName.bidiClass', () {
    test('codeFor("L") returns a value', () {
      final names = IcuPropertyName.bidiClass();
      // BidiClass "L" (Left-to-right).
      expect(names.codeFor('L'), isNotNull);
    });

    test('nameOf round-trips bidi-class long name', () {
      final names = IcuPropertyName.bidiClass();
      final code = names.codeFor('L');
      expect(code, isNotNull);
      expect(names.nameOf(code!), 'Left_To_Right');
    });

    test('nameOf with short=true returns short alias', () {
      final names = IcuPropertyName.bidiClass();
      final code = names.codeFor('L');
      expect(code, isNotNull);
      expect(names.nameOf(code!, short: true), 'L');
    });
  });

  group('IcuPropertyName.lineBreak', () {
    test('codeFor("AL") returns a code', () {
      final names = IcuPropertyName.lineBreak();
      // LineBreak "AL" (Alphabetic).
      expect(names.codeFor('AL'), isNotNull);
    });

    test('nameOf round-trips line-break short alias', () {
      final names = IcuPropertyName.lineBreak();
      final code = names.codeFor('AL');
      expect(code, isNotNull);
      expect(names.nameOf(code!, short: true), 'AL');
    });
  });

  group('IcuPropertyName.eastAsianWidth', () {
    test('nameOf round-trips a known value', () {
      final names = IcuPropertyName.eastAsianWidth();
      // EastAsianWidth "W" (Wide).
      final code = names.codeFor('W');
      expect(code, isNotNull);
      expect(names.nameOf(code!, short: true), 'W');
    });
  });

  group('IcuPropertyName.numericType', () {
    test('nameOf round-trips a known value', () {
      final names = IcuPropertyName.numericType();
      // NumericType "De" (Decimal).
      final code = names.codeFor('De');
      expect(code, isNotNull);
      expect(names.nameOf(code!, short: true), 'De');
    });
  });
}
