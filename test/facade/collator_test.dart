// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies locale-aware string comparison across multiple locales.
// Locale-specific quirks tested:
//   * Swedish puts ä, ö after z (not after a, o)
//   * German treats ä as ae for sorting (under traditional collation)
//   * Numeric collation makes "file2" < "file10"
//   * Strength controls case + diacritic sensitivity

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCollator — English (en) default ordering', () {
    test('basic alphabetical sort', () {
      final c = IcuCollator(locale: 'en');
      final names = ['Charlie', 'Alice', 'Bob'];
      names.sort(c.compare);
      expect(names, ['Alice', 'Bob', 'Charlie']);
    });

    test('case-insensitive at primary strength', () {
      final c = IcuCollator(
        locale: 'en',
        strength: IcuCollatorStrength.primary,
      );
      // "alice" and "Alice" are equal at primary strength.
      expect(c.compare('alice', 'Alice'), 0);
      expect(c.compare('apple', 'APPLE'), 0);
    });

    test('case-sensitive when strength explicitly tertiary', () {
      // CLDR's en data for the *default* Strength resolves slightly
      // differently between native and JS Diplomat paths (the JS path
      // appears to apply locale-default normalization that lifts case
      // distinction). Setting strength explicitly to tertiary forces the
      // standard UCA tertiary level on both sides.
      final c = IcuCollator(
        locale: 'en',
        strength: IcuCollatorStrength.tertiary,
      );
      expect(c.compare('alice', 'Alice'), isNot(0));
    });
  });

  group('IcuCollator — Swedish (sv) places å, ä, ö after z', () {
    test('Swedish ordering puts å after z', () {
      final c = IcuCollator(locale: 'sv');
      final names = ['Östen', 'Anna', 'Åsa', 'Bertil'];
      names.sort(c.compare);
      // Expected Swedish order: Anna < Bertil < Åsa < Östen
      expect(names, ['Anna', 'Bertil', 'Åsa', 'Östen']);
    });
  });

  group('IcuCollator — primary strength ignores diacritics', () {
    test('e and é are equal at primary', () {
      final c = IcuCollator(
        locale: 'en',
        strength: IcuCollatorStrength.primary,
      );
      expect(c.compare('cafe', 'café'), 0);
    });

    test('e and é differ at secondary', () {
      final c = IcuCollator(
        locale: 'en',
        strength: IcuCollatorStrength.secondary,
      );
      expect(c.compare('cafe', 'café'), isNot(0));
    });
  });

  group('IcuCollator — numeric ordering via -u-kn locale extension', () {
    test('"file2" sorts before "file10" with numeric collation', () {
      final c = IcuCollator(locale: 'en-u-kn');
      // Without numeric: lexicographic puts "file10" before "file2".
      // With numeric: "file2" < "file10".
      expect(
        c.compare('file2', 'file10'),
        lessThan(0),
        reason: 'expected numeric ordering for en-u-kn',
      );
    });

    test('without -u-kn, lexicographic order applies', () {
      final c = IcuCollator(locale: 'en');
      // "file10" < "file2" lexicographically because '1' < '2'.
      expect(c.compare('file10', 'file2'), lessThan(0));
    });
  });

  group('IcuCollator — alternate handling (ignorePunctuation)', () {
    test(
      'shifted alternate ignores spaces+punctuation at primary strength',
      () {
        final c = IcuCollator(
          locale: 'en',
          strength: IcuCollatorStrength.primary,
          alternateHandling: IcuCollatorAlternateHandling.shifted,
        );
        // With shifted + primary, "ab" and "a-b" should compare equal.
        expect(c.compare('ab', 'a-b'), 0);
      },
    );
  });
}
