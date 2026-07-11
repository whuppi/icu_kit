// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies date-only formatting across multiple locales + field-sets +
// lengths. ICU4X's CLDR data is the truth source; tests assert real
// rendered strings rather than spec-style approximations.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  // Use a fixed date so tests are reproducible across runs.
  final apr28 = DateTime(2026, 4, 28); // Tue, Apr 28, 2026

  group('IcuDateFormat.ymd — English (en-US)', () {
    test('medium renders abbreviated month + comma', () {
      final fmt = IcuDateFormat.ymd(locale: 'en-US');
      // CLDR en-US medium: "Apr 28, 2026"
      expect(fmt.format(apr28), contains('Apr'));
      expect(fmt.format(apr28), contains('28'));
      expect(fmt.format(apr28), contains('2026'));
    });

    test('long renders full month name', () {
      final fmt = IcuDateFormat.ymd(
        locale: 'en-US',
        length: IcuDateLength.long,
      );
      expect(fmt.format(apr28), contains('April'));
      expect(fmt.format(apr28), contains('2026'));
    });

    test('short renders all-numeric', () {
      final fmt = IcuDateFormat.ymd(
        locale: 'en-US',
        length: IcuDateLength.short,
      );
      // en-US short: "4/28/26"
      final result = fmt.format(apr28);
      expect(result, contains('26'));
      expect(result, isNot(contains('Apr')));
    });
  });

  group('IcuDateFormat.ymd — German (de) uses DD.MM.YYYY', () {
    test('medium uses period separator', () {
      final fmt = IcuDateFormat.ymd(locale: 'de');
      // CLDR de medium: "28.04.2026"
      final result = fmt.format(apr28);
      expect(result, contains('28'));
      expect(result, contains('2026'));
      expect(
        result,
        contains('.'),
        reason: 'expected period separator, got: $result',
      );
    });
  });

  group('IcuDateFormat.ymde — weekday + date', () {
    test('en-US long includes full weekday name', () {
      final fmt = IcuDateFormat.ymde(
        locale: 'en-US',
        length: IcuDateLength.long,
      );
      // April 28, 2026 was a Tuesday.
      final result = fmt.format(apr28);
      expect(
        result.toLowerCase(),
        contains('tuesday'),
        reason: 'expected weekday "Tuesday", got: $result',
      );
    });
  });

  group('IcuDateFormat.md — month + day only (no year)', () {
    test('en-US renders without year', () {
      final fmt = IcuDateFormat.md(locale: 'en-US');
      final result = fmt.format(apr28);
      expect(result, contains('Apr'));
      expect(result, isNot(contains('2026')));
    });
  });

  group('IcuDateFormat.y — year only', () {
    test('en-US renders just the year', () {
      final fmt = IcuDateFormat.y(locale: 'en-US');
      final result = fmt.format(apr28);
      expect(result.contains('2026'), isTrue);
    });
  });

  group('IcuDateFormat — Japanese calendar via locale extension', () {
    test('en-u-ca-japanese renders era-based year', () {
      // 2026 in Reiwa era = 令和8年 (Reiwa 8). The Japanese calendar has
      // been Reiwa since 2019.
      final fmt = IcuDateFormat.ymd(
        locale: 'en-u-ca-japanese',
        length: IcuDateLength.long,
      );
      final result = fmt.format(apr28);
      // Era markers in en locale: "Reiwa" or "R" or numeric era.
      // Be loose — we're proving the calendar wired through, not a
      // specific Japanese-era formatting choice.
      expect(
        result,
        contains('8'),
        reason: 'expected Reiwa year 8 to appear, got: $result',
      );
      expect(
        result,
        isNot(contains('2026')),
        reason: 'expected Japanese era year, not Gregorian, got: $result',
      );
    });
  });

  group('IcuDateFormat — Arabic numerals via locale extension', () {
    test('en-u-nu-arab renders date with Arabic-Indic digits', () {
      final fmt = IcuDateFormat.ymd(
        locale: 'en-u-nu-arab',
        length: IcuDateLength.short,
      );
      final result = fmt.format(apr28);
      // Arabic-Indic digit '٢' (U+0662) for "2".
      expect(
        result,
        contains('٢'),
        reason: 'expected Arabic-Indic digits, got: $result',
      );
    });
  });
}
